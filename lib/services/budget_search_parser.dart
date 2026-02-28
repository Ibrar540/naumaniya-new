import 'dart:convert';

/// Enterprise-Level Budget Search Parser
/// Converts natural language input (Urdu/English) into structured search filters
/// for Budget Management System (description, rs, date)
class BudgetSearchParser {
  /// Parse natural language query and return structured JSON
  static Map<String, dynamic> parse(String query, bool isUrdu) {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      return _emptyResult(isUrdu);
    }

    // Initialize filters
    final filters = <String, dynamic>{
      'description_contains': null,
      'amount_condition': {
        'type': null,
        'value': null,
        'start': null,
        'end': null,
      },
      'date_filter': {
        'type': null,
        'value': null,
        'start': null,
        'end': null,
      },
    };

    // Extract filters
    _extractDescriptionFilter(trimmedQuery, filters);
    _extractAmountFilter(trimmedQuery, filters);
    _extractDateFilter(trimmedQuery, filters);

    // STEP 1: Detect intent
    final intent = _detectIntent(trimmedQuery, filters);
    
    // STEP 4: Check if pagination required
    final requiresPagination = _requiresPagination(filters);
    
    // STEP 5: Calculate confidence score
    final confidenceScore = _calculateConfidenceScore(trimmedQuery, filters);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(trimmedQuery, filters, isUrdu);

    return {
      'intent': intent,
      'confidence_score': confidenceScore,
      'requires_pagination': requiresPagination,
      'filters': filters,
      'recommendations': recommendations,
    };
  }
  
  /// STEP 1: Detect query intent
  static String _detectIntent(String query, Map<String, dynamic> filters) {
    int activeFilters = 0;
    
    if (filters['description_contains'] != null) activeFilters++;
    if (filters['amount_condition']['type'] != null) activeFilters++;
    if (filters['date_filter']['type'] != null) activeFilters++;
    
    // EXACT_AMOUNT: Only amount with exact value
    if (filters['amount_condition']['type'] == 'exact' && activeFilters == 1) {
      return 'EXACT_AMOUNT';
    }
    
    // RANGE_QUERY: Amount range or date range
    if (filters['amount_condition']['type'] == 'range' || 
        filters['date_filter']['type'] == 'range') {
      return 'RANGE_QUERY';
    }
    
    // DATE_QUERY: Only date filter
    if (filters['date_filter']['type'] != null && activeFilters == 1) {
      return 'DATE_QUERY';
    }
    
    // DESCRIPTION_SEARCH: Only description
    if (filters['description_contains'] != null && activeFilters == 1) {
      return 'DESCRIPTION_SEARCH';
    }
    
    // COMBINED_QUERY: Multiple filters
    if (activeFilters >= 2) {
      return 'COMBINED_QUERY';
    }
    
    // INCOMPLETE_QUERY: No filters or very short
    if (activeFilters == 0 || query.length <= 2) {
      return 'INCOMPLETE_QUERY';
    }
    
    return 'DESCRIPTION_SEARCH';
  }
  
  /// Extract description filter
  static void _extractDescriptionFilter(String query, Map<String, dynamic> filters) {
    // Remove amount and date patterns to isolate description
    String descQuery = query;
    
    // Remove amount patterns
    descQuery = descQuery.replaceAll(RegExp(r'\d+\s*(?:rs|روپے|rupees?)'), '');
    descQuery = descQuery.replaceAll(RegExp(r'(?:greater than|less than|se zyada|se kam|سے زیادہ|سے کم)\s*\d+'), '');
    descQuery = descQuery.replaceAll(RegExp(r'\d+\s*(?:to|se|سے)\s*\d+'), '');
    
    // Remove date patterns
    descQuery = descQuery.replaceAll(RegExp(r'\d{4}'), '');
    descQuery = descQuery.replaceAll(RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}'), '');
    
    // Remove common date keywords
    final dateKeywords = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
                          'january', 'february', 'march', 'april', 'june', 'july', 'august', 'september', 'october', 'november', 'december',
                          'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];
    
    for (var keyword in dateKeywords) {
      descQuery = descQuery.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    
    descQuery = descQuery.trim();
    
    // If something remains, use it as description
    if (descQuery.isNotEmpty && descQuery.length > 1) {
      filters['description_contains'] = descQuery;
    }
  }
  
  /// Extract amount filter
  static void _extractAmountFilter(String query, Map<String, dynamic> filters) {
    final lowerQuery = query.toLowerCase();
    
    // Pattern 1: Amount range "2000 to 5000", "2000 se 5000", "2000 سے 5000"
    final rangePatterns = [
      RegExp(r'(\d+)\s*(?:to|se|سے)\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*-\s*(\d+)'),
    ];
    
    for (var pattern in rangePatterns) {
      final match = pattern.firstMatch(query);
      if (match != null) {
        filters['amount_condition'] = {
          'type': 'range',
          'value': null,
          'start': int.parse(match.group(1)!),
          'end': int.parse(match.group(2)!),
        };
        return;
      }
    }
    
    // Pattern 2: Greater than "greater than 5000", "5000 se zyada", "5000 سے زیادہ"
    if (lowerQuery.contains('greater than') || 
        lowerQuery.contains('se zyada') || 
        lowerQuery.contains('se ziada') ||
        query.contains('سے زیادہ') ||
        query.contains('سے بڑا') ||
        lowerQuery.contains('more than') ||
        query.contains('>')) {
      
      final amountMatch = RegExp(r'(\d+)').firstMatch(query);
      if (amountMatch != null) {
        filters['amount_condition'] = {
          'type': 'greater_than',
          'value': int.parse(amountMatch.group(1)!),
          'start': null,
          'end': null,
        };
        return;
      }
    }
    
    // Pattern 3: Less than "less than 2000", "2000 se kam", "2000 سے کم"
    if (lowerQuery.contains('less than') || 
        lowerQuery.contains('se kam') ||
        query.contains('سے کم') ||
        query.contains('سے چھوٹا') ||
        lowerQuery.contains('below') ||
        query.contains('<')) {
      
      final amountMatch = RegExp(r'(\d+)').firstMatch(query);
      if (amountMatch != null) {
        filters['amount_condition'] = {
          'type': 'less_than',
          'value': int.parse(amountMatch.group(1)!),
          'start': null,
          'end': null,
        };
        return;
      }
    }
    
    // Pattern 4: Exact amount "5000 rs", "5000 روپے", "5000"
    final exactPatterns = [
      RegExp(r'(\d+)\s*(?:rs|روپے|rupees?)', caseSensitive: false),
      RegExp(r'^(\d+)$'),
    ];
    
    for (var pattern in exactPatterns) {
      final match = pattern.firstMatch(query.trim());
      if (match != null) {
        filters['amount_condition'] = {
          'type': 'exact',
          'value': int.parse(match.group(1)!),
          'start': null,
          'end': null,
        };
        return;
      }
    }
  }
  
  /// Extract date filter
  static void _extractDateFilter(String query, Map<String, dynamic> filters) {
    // Month name mappings
    final monthMap = {
      'january': 1, 'jan': 1, 'جنوری': 1,
      'february': 2, 'feb': 2, 'فروری': 2,
      'march': 3, 'mar': 3, 'مارچ': 3,
      'april': 4, 'apr': 4, 'اپریل': 4,
      'may': 5, 'مئی': 5,
      'june': 6, 'jun': 6, 'جون': 6,
      'july': 7, 'jul': 7, 'جولائی': 7,
      'august': 8, 'aug': 8, 'اگست': 8,
      'september': 9, 'sep': 9, 'sept': 9, 'ستمبر': 9,
      'october': 10, 'oct': 10, 'اکتوبر': 10,
      'november': 11, 'nov': 11, 'نومبر': 11,
      'december': 12, 'dec': 12, 'دسمبر': 12,
    };
    
    // Pattern 1: Date range "2020 to 2023", "2020 se 2023"
    final rangePattern = RegExp(r'(\d{4})\s*(?:to|se|سے)\s*(\d{4})');
    final rangeMatch = rangePattern.firstMatch(query);
    if (rangeMatch != null) {
      final startYear = int.parse(rangeMatch.group(1)!);
      final endYear = int.parse(rangeMatch.group(2)!);
      filters['date_filter'] = {
        'type': 'range',
        'value': null,
        'start': '$startYear-01-01',
        'end': '$endYear-12-31',
      };
      return;
    }
    
    // Pattern 2: Month + Year "Jan 2024", "January 2024", "جنوری 2024"
    for (var entry in monthMap.entries) {
      final monthPattern = RegExp('${entry.key}\\s*(\\d{4})', caseSensitive: false);
      final monthMatch = monthPattern.firstMatch(query);
      if (monthMatch != null) {
        final year = int.parse(monthMatch.group(1)!);
        final month = entry.value;
        final lastDay = DateTime(year, month + 1, 0).day;
        
        filters['date_filter'] = {
          'type': 'month',
          'value': {
            'month': month,
            'year': year,
          },
          'start': '$year-${month.toString().padLeft(2, '0')}-01',
          'end': '$year-${month.toString().padLeft(2, '0')}-$lastDay',
        };
        return;
      }
    }
    
    // Pattern 3: Exact date "15-08-2024", "15/08/2024"
    final datePatterns = [
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'),
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
    ];
    
    for (var pattern in datePatterns) {
      final match = pattern.firstMatch(query);
      if (match != null) {
        String dateStr;
        if (match.group(1)!.length == 4) {
          // yyyy-mm-dd format
          dateStr = '${match.group(1)}-${match.group(2)!.padLeft(2, '0')}-${match.group(3)!.padLeft(2, '0')}';
        } else {
          // dd-mm-yyyy format
          dateStr = '${match.group(3)}-${match.group(2)!.padLeft(2, '0')}-${match.group(1)!.padLeft(2, '0')}';
        }
        
        filters['date_filter'] = {
          'type': 'exact',
          'value': dateStr,
          'start': null,
          'end': null,
        };
        return;
      }
    }
    
    // Pattern 4: Year only "2024"
    final yearPattern = RegExp(r'\b(20\d{2})\b');
    final yearMatch = yearPattern.firstMatch(query);
    if (yearMatch != null) {
      final year = int.parse(yearMatch.group(1)!);
      filters['date_filter'] = {
        'type': 'year',
        'value': year,
        'start': '$year-01-01',
        'end': '$year-12-31',
      };
    }
  }
  
  /// STEP 4: Check if pagination is required
  static bool _requiresPagination(Map<String, dynamic> filters) {
    // If only year filter, require pagination
    if (filters['date_filter']['type'] == 'year' && 
        filters['description_contains'] == null &&
        filters['amount_condition']['type'] == null) {
      return true;
    }
    
    // If no filters at all, require pagination
    if (filters['description_contains'] == null &&
        filters['amount_condition']['type'] == null &&
        filters['date_filter']['type'] == null) {
      return true;
    }
    
    return false;
  }
  
  /// STEP 5: Calculate confidence score (0-100)
  static int _calculateConfidenceScore(String query, Map<String, dynamic> filters) {
    // Exact amount → 95
    if (filters['amount_condition']['type'] == 'exact') {
      return 95;
    }
    
    // Amount range → 90
    if (filters['amount_condition']['type'] == 'range') {
      return 90;
    }
    
    // Date + description → 85
    if (filters['date_filter']['type'] != null && 
        filters['description_contains'] != null) {
      return 85;
    }
    
    // Amount condition (greater/less) → 80
    if (filters['amount_condition']['type'] == 'greater_than' ||
        filters['amount_condition']['type'] == 'less_than') {
      return 80;
    }
    
    // Single description word → 70
    if (filters['description_contains'] != null && 
        filters['description_contains'].split(' ').length == 1) {
      return 70;
    }
    
    // Multiple description words → 75
    if (filters['description_contains'] != null) {
      return 75;
    }
    
    // Date only → 70
    if (filters['date_filter']['type'] != null) {
      return 70;
    }
    
    // Incomplete query → 40
    if (query.length <= 2) {
      return 40;
    }
    
    return 60; // Default
  }
  
  /// Generate smart recommendations
  static List<String> _generateRecommendations(
    String query,
    Map<String, dynamic> filters,
    bool isUrdu,
  ) {
    final recommendations = <String>[];
    
    // Based on active filters
    if (filters['amount_condition']['type'] == 'exact') {
      final amount = filters['amount_condition']['value'];
      if (isUrdu) {
        recommendations.addAll([
          '$amount روپے کی تفصیلات',
          '$amount روپے سے زیادہ',
          '$amount روپے کے اخراجات',
        ]);
      } else {
        recommendations.addAll([
          'Rs $amount details',
          'Greater than Rs $amount',
          'Expenses of Rs $amount',
        ]);
      }
    } else if (filters['amount_condition']['type'] == 'range') {
      final start = filters['amount_condition']['start'];
      final end = filters['amount_condition']['end'];
      if (isUrdu) {
        recommendations.addAll([
          '$start سے $end روپے کے اخراجات',
          '$start سے $end روپے کی آمدنی',
          '$start سے $end روپے کا ریکارڈ',
        ]);
      } else {
        recommendations.addAll([
          'Rs $start to $end expenses',
          'Rs $start to $end income',
          'Rs $start to $end records',
        ]);
      }
    } else if (filters['date_filter']['type'] == 'year') {
      final year = filters['date_filter']['value'];
      if (isUrdu) {
        recommendations.addAll([
          '$year کے تمام اخراجات',
          '$year کی آمدنی',
          '$year کا بجٹ ریکارڈ',
        ]);
      } else {
        recommendations.addAll([
          'All expenses in $year',
          'Income in $year',
          'Budget records $year',
        ]);
      }
    } else if (filters['date_filter']['type'] == 'month') {
      final monthData = filters['date_filter']['value'];
      final month = monthData['month'];
      final year = monthData['year'];
      final monthNames = isUrdu 
          ? ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر']
          : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final monthName = monthNames[month - 1];
      
      if (isUrdu) {
        recommendations.addAll([
          '$monthName $year کے اخراجات',
          '$monthName $year کی آمدنی',
          '$monthName $year کا مکمل ریکارڈ',
        ]);
      } else {
        recommendations.addAll([
          '$monthName $year expenses',
          '$monthName $year income',
          '$monthName $year complete records',
        ]);
      }
    } else if (filters['description_contains'] != null) {
      final desc = filters['description_contains'];
      if (isUrdu) {
        recommendations.addAll([
          '$desc کی تفصیلات',
          '$desc کے اخراجات',
          '$desc کا مکمل ریکارڈ',
        ]);
      } else {
        recommendations.addAll([
          '$desc details',
          '$desc expenses',
          '$desc complete records',
        ]);
      }
    } else {
      // Default recommendations
      if (isUrdu) {
        recommendations.addAll([
          'تمام اخراجات',
          '2024 کے اخراجات',
          '5000 روپے سے زیادہ',
        ]);
      } else {
        recommendations.addAll([
          'All expenses',
          'Expenses in 2024',
          'Greater than Rs 5000',
        ]);
      }
    }
    
    // Ensure exactly 3 unique recommendations that don't duplicate input
    final uniqueRecs = recommendations.where((rec) => 
      rec.toLowerCase() != query.toLowerCase() && 
      !query.toLowerCase().contains(rec.toLowerCase())
    ).toSet().toList();
    
    while (uniqueRecs.length < 3) {
      if (isUrdu) {
        uniqueRecs.add('بجٹ کا مکمل ریکارڈ');
      } else {
        uniqueRecs.add('Complete budget records');
      }
    }
    
    return uniqueRecs.take(3).toList();
  }
  
  /// Return empty result with default recommendations
  static Map<String, dynamic> _emptyResult(bool isUrdu) {
    return {
      'intent': 'INCOMPLETE_QUERY',
      'confidence_score': 40,
      'requires_pagination': true,
      'filters': {
        'description_contains': null,
        'amount_condition': {
          'type': null,
          'value': null,
          'start': null,
          'end': null,
        },
        'date_filter': {
          'type': null,
          'value': null,
          'start': null,
          'end': null,
        },
      },
      'recommendations': isUrdu
          ? [
              'تمام اخراجات',
              '2024 کے اخراجات',
              '5000 روپے سے زیادہ',
            ]
          : [
              'All expenses',
              'Expenses in 2024',
              'Greater than Rs 5000',
            ],
    };
  }
  
  /// Convert parsed result to JSON string
  static String toJson(Map<String, dynamic> result) {
    return jsonEncode(result);
  }
  
  /// Convert parsed result to pretty JSON string
  static String toPrettyJson(Map<String, dynamic> result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result);
  }
}
