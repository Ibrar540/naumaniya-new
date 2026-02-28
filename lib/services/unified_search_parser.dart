import 'dart:convert';
import 'admission_search_service.dart';
import 'graduation_search_service.dart';
import 'struckoff_search_service.dart';

/// Enterprise-Level Unified Search Parser for Student Management System
/// Converts natural language input (Urdu/English) into structured search filters
/// with intent detection, confidence scoring, and conflict resolution
class UnifiedSearchParser {
  /// Parse natural language query and return structured JSON
  static Map<String, dynamic> parse(String query, bool isUrdu) {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      return _emptyResult(isUrdu);
    }

    // Initialize filters
    final filters = <String, dynamic>{
      'id': null,
      'id_range': null,
      'name': null,
      'father_name': null,
      'class': [],
      'fee_condition': null,
      'status': null,
      'date_filter': {
        'column': null,
        'type': null,
        'value': null,
        'start': null,
        'end': null,
      },
    };

    // Extract filters
    _extractIdFilter(trimmedQuery, filters);
    _extractNameFilter(trimmedQuery, filters);
    _extractClassFilter(trimmedQuery, filters);
    _extractFeeFilter(trimmedQuery, filters);
    _extractStatusFilter(trimmedQuery, filters);
    _extractDateFilter(trimmedQuery, filters);

    // STEP 1: Detect intent
    final intent = _detectIntent(trimmedQuery, filters);
    
    // STEP 3: Resolve conflicts
    final conflictWarning = _resolveConflicts(filters);
    
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
      'conflict_warning': conflictWarning,
      'recommendations': recommendations,
    };
  }
  
  /// STEP 1: Detect query intent
  static String _detectIntent(String query, Map<String, dynamic> filters) {
    // Count active filters
    int activeFilters = 0;
    if (filters['id'] != null) activeFilters++;
    if (filters['id_range'] != null) activeFilters++;
    if (filters['name'] != null) activeFilters++;
    if (filters['father_name'] != null) activeFilters++;
    if (filters['class'] != null && (filters['class'] as List).isNotEmpty) activeFilters++;
    if (filters['fee_condition'] != null) activeFilters++;
    if (filters['status'] != null) activeFilters++;
    if (filters['date_filter']['column'] != null) activeFilters++;
    
    // EXACT_LOOKUP: Single ID
    if (filters['id'] != null && activeFilters == 1) {
      return 'EXACT_LOOKUP';
    }
    
    // RANGE_QUERY: ID range or date range
    if (filters['id_range'] != null || 
        (filters['date_filter']['type'] == 'range')) {
      return 'RANGE_QUERY';
    }
    
    // DATE_QUERY: Any date filter
    if (filters['date_filter']['column'] != null) {
      return activeFilters > 1 ? 'COMBINED_COMPLEX' : 'DATE_QUERY';
    }
    
    // COMBINED_COMPLEX: Multiple filters
    if (activeFilters >= 2) {
      return 'COMBINED_COMPLEX';
    }
    
    // FILTER_SEARCH: Single filter (not ID)
    if (activeFilters == 1) {
      return 'FILTER_SEARCH';
    }
    
    // INCOMPLETE_QUERY: No filters or very short query
    if (activeFilters == 0 || query.length <= 2) {
      return 'INCOMPLETE_QUERY';
    }
    
    return 'FILTER_SEARCH';
  }
  
  /// STEP 3: Resolve conflicts in filters
  static String? _resolveConflicts(Map<String, dynamic> filters) {
    final conflicts = <String>[];
    
    // Conflict: Both ID and ID range
    if (filters['id'] != null && filters['id_range'] != null) {
      conflicts.add('Both exact ID and ID range specified - using ID range');
      filters['id'] = null; // Prioritize range
    }
    
    // Conflict: Fee with/without contradictions
    if (filters['fee_condition'] != null) {
      final feeOp = filters['fee_condition']['operator'];
      final feeVal = filters['fee_condition']['value'];
      
      // Check for impossible conditions
      if (feeOp == '=' && feeVal == 0 && filters['status'] == 'active') {
        // This might be intentional, no conflict
      }
    }
    
    // Conflict: Multiple date columns (shouldn't happen but check)
    // Already handled by priority in _extractDateFilter
    
    return conflicts.isEmpty ? null : conflicts.join('; ');
  }
  
  /// STEP 4: Check if pagination is required
  static bool _requiresPagination(Map<String, dynamic> filters) {
    // Count specific filters
    int specificFilters = 0;
    if (filters['id'] != null) return false; // Exact ID, no pagination needed
    if (filters['id_range'] != null) specificFilters++;
    if (filters['name'] != null) specificFilters++;
    if (filters['father_name'] != null) specificFilters++;
    if (filters['class'] != null && (filters['class'] as List).isNotEmpty) specificFilters++;
    if (filters['fee_condition'] != null) specificFilters++;
    if (filters['status'] != null) specificFilters++;
    
    // If only date filter (especially year only), require pagination
    if (filters['date_filter']['column'] != null && 
        filters['date_filter']['type'] == 'year' && 
        specificFilters == 0) {
      return true;
    }
    
    // If no specific filters, require pagination
    if (specificFilters == 0 && filters['date_filter']['column'] == null) {
      return true;
    }
    
    return false;
  }
  
  /// STEP 5: Calculate confidence score (0-100)
  static int _calculateConfidenceScore(String query, Map<String, dynamic> filters) {
    // Exact ID → 100
    if (filters['id'] != null) {
      return 100;
    }
    
    // Exact Name (length > 5) → 90
    if (filters['name'] != null && filters['name'].toString().length > 5) {
      return 90;
    }
    
    // Multiple filters → 85
    int activeFilters = 0;
    if (filters['id_range'] != null) activeFilters++;
    if (filters['name'] != null) activeFilters++;
    if (filters['father_name'] != null) activeFilters++;
    if (filters['class'] != null && (filters['class'] as List).isNotEmpty) activeFilters++;
    if (filters['fee_condition'] != null) activeFilters++;
    if (filters['status'] != null) activeFilters++;
    if (filters['date_filter']['column'] != null) activeFilters++;
    
    if (activeFilters >= 2) {
      return 85;
    }
    
    // Single filter → 70
    if (activeFilters == 1) {
      return 70;
    }
    
    // Incomplete query → 40
    if (query.length <= 2 || activeFilters == 0) {
      return 40;
    }
    
    return 60; // Default
  }

  /// Extract ID filter
  static void _extractIdFilter(String query, Map<String, dynamic> filters) {
    final lowerQuery = query.toLowerCase();
    
    // Check for ID range patterns
    // "ID 10 to 20", "آئی ڈی 10 سے 20 تک", "10-20"
    final rangePatterns = [
      RegExp(r'(?:id|آئی ڈی)\s*(\d+)\s*(?:to|سے)\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*-\s*(\d+)'),
    ];
    
    for (var pattern in rangePatterns) {
      final match = pattern.firstMatch(query);
      if (match != null) {
        filters['id_range'] = {
          'start': int.parse(match.group(1)!),
          'end': int.parse(match.group(2)!),
        };
        return;
      }
    }
    
    // Check for exact ID
    // "ID 7", "آئی ڈی 7"
    final idPattern = RegExp(r'(?:id|آئی ڈی)\s*(\d+)', caseSensitive: false);
    final idMatch = idPattern.firstMatch(query);
    if (idMatch != null) {
      filters['id'] = int.parse(idMatch.group(1)!);
    }
  }

  /// Extract name filter
  static void _extractNameFilter(String query, Map<String, dynamic> filters) {
    // Check for name-specific keywords
    final nameKeywords = ['name', 'نام', 'student', 'طالب علم'];
    final fatherKeywords = ['father', 'والد', 'والد کا نام', 'father name'];
    
    bool hasNameKeyword = nameKeywords.any((k) => query.toLowerCase().contains(k));
    bool hasFatherKeyword = fatherKeywords.any((k) => query.toLowerCase().contains(k));
    
    // If query contains name/father keywords, extract the name part
    if (hasNameKeyword || hasFatherKeyword) {
      // Extract text after the keyword
      String? nameValue;
      
      for (var keyword in [...nameKeywords, ...fatherKeywords]) {
        final index = query.toLowerCase().indexOf(keyword);
        if (index != -1) {
          final afterKeyword = query.substring(index + keyword.length).trim();
          // Remove common connecting words
          nameValue = afterKeyword
              .replaceAll(RegExp(r'^(is|:|\s)+'), '')
              .split(RegExp(r'\s+(and|or|with|کے|کا|میں)\s+'))[0]
              .trim();
          break;
        }
      }
      
      if (nameValue != null && nameValue.isNotEmpty) {
        if (hasFatherKeyword) {
          filters['father_name'] = nameValue;
        } else {
          filters['name'] = nameValue;
        }
      }
    }
  }

  /// Extract class filter (supports multiple classes)
  static void _extractClassFilter(String query, Map<String, dynamic> filters) {
    // Check for class keywords
    final classKeywords = ['class', 'جماعت', 'کلاس'];
    
    bool hasClassKeyword = classKeywords.any((k) => query.toLowerCase().contains(k));
    
    if (hasClassKeyword) {
      final classes = <String>[];
      
      // Extract multiple classes: "class A, B and C", "جماعت A، B اور C"
      // Remove class keyword prefix
      String classContent = query;
      for (var keyword in classKeywords) {
        classContent = classContent.replaceAll(RegExp(keyword, caseSensitive: false), '');
      }
      
      // Split by comma, and, اور
      final parts = classContent.split(RegExp(r'[,،]|\s+(?:and|اور)\s+'));
      
      for (var part in parts) {
        final trimmed = part.trim();
        // Extract class names (letters, numbers, or words)
        final classMatch = RegExp(r'([A-Za-z0-9]+(?:st|nd|rd|th)?)', caseSensitive: false).firstMatch(trimmed);
        if (classMatch != null) {
          classes.add(classMatch.group(0)!.toUpperCase());
        }
      }
      
      // Remove duplicates
      filters['class'] = classes.toSet().toList();
    }
  }

  /// Extract fee filter
  static void _extractFeeFilter(String query, Map<String, dynamic> filters) {
    final lowerQuery = query.toLowerCase();
    
    // Check for fee keywords
    if (lowerQuery.contains('fee') || query.contains('فیس')) {
      // "students with fee" → fee > 0
      if (lowerQuery.contains('with fee') || query.contains('فیس والے')) {
        filters['fee_condition'] = {'operator': '>', 'value': 0};
        return;
      }
      
      // "students without fee" → fee = 0
      if (lowerQuery.contains('without fee') || query.contains('بغیر فیس')) {
        filters['fee_condition'] = {'operator': '=', 'value': 0};
        return;
      }
      
      // "fee greater than X" → fee > X
      final greaterPattern = RegExp(r'(?:fee|فیس)\s*(?:greater than|>|سے زیادہ)\s*(\d+)', caseSensitive: false);
      final greaterMatch = greaterPattern.firstMatch(query);
      if (greaterMatch != null) {
        filters['fee_condition'] = {
          'operator': '>',
          'value': int.parse(greaterMatch.group(1)!),
        };
        return;
      }
      
      // "fee less than X" → fee < X
      final lessPattern = RegExp(r'(?:fee|فیس)\s*(?:less than|<|سے کم)\s*(\d+)', caseSensitive: false);
      final lessMatch = lessPattern.firstMatch(query);
      if (lessMatch != null) {
        filters['fee_condition'] = {
          'operator': '<',
          'value': int.parse(lessMatch.group(1)!),
        };
        return;
      }
      
      // "fee = X" → fee = X
      final equalPattern = RegExp(r'(?:fee|فیس)\s*(?:=|equals|برابر)\s*(\d+)', caseSensitive: false);
      final equalMatch = equalPattern.firstMatch(query);
      if (equalMatch != null) {
        filters['fee_condition'] = {
          'operator': '=',
          'value': int.parse(equalMatch.group(1)!),
        };
      }
    }
  }

  /// Extract status filter
  static void _extractStatusFilter(String query, Map<String, dynamic> filters) {
    final lowerQuery = query.toLowerCase();
    
    // Map Urdu/English status keywords to database values
    final statusMap = {
      'active': 'active',
      'فعال': 'active',
      'فعال طلبہ': 'active',
      'graduate': 'graduate',
      'graduated': 'graduate',
      'فارغ': 'graduate',
      'فارغ التحصیل': 'graduate',
      'گریجویٹ': 'graduate',
      'struck off': 'struck off',
      'struck-off': 'struck off',
      'اخراج شدہ': 'struck off',
      'خارج شدہ': 'struck off',
      'خارج': 'struck off',
    };
    
    for (var entry in statusMap.entries) {
      if (lowerQuery.contains(entry.key.toLowerCase()) || query.contains(entry.key)) {
        filters['status'] = entry.value;
        break;
      }
    }
  }

  /// Extract date filter using existing date search services
  static void _extractDateFilter(String query, Map<String, dynamic> filters) {
    String? dateColumn;
    dynamic dateParams;
    
    // Priority 1: Check for admission date
    if (AdmissionSearchService.isAdmissionQuery(query)) {
      dateColumn = 'admission_date';
      dateParams = AdmissionSearchService.parseQuery(query);
    }
    // Priority 2: Check for struck-off date
    else if (StruckOffSearchService.isStruckOffQuery(query)) {
      dateColumn = 'struck_off_date';
      dateParams = StruckOffSearchService.parseQuery(query);
    }
    // Priority 3: Check for graduation date
    else if (GraduationSearchService.isGraduationQuery(query)) {
      dateColumn = 'graduation_date';
      dateParams = GraduationSearchService.parseQuery(query);
    }
    
    if (dateColumn != null && dateParams != null) {
      filters['date_filter']['column'] = dateColumn;
      
      // Map search type to filter type
      final searchType = dateParams.searchType.toString().split('.').last;
      filters['date_filter']['type'] = searchType;
      
      // Extract values based on type
      if (searchType == 'exact') {
        filters['date_filter']['value'] = dateParams.exactDate?.toIso8601String();
      } else if (searchType == 'year') {
        filters['date_filter']['value'] = dateParams.year;
      } else if (searchType == 'month') {
        filters['date_filter']['value'] = {
          'month': dateParams.month,
          'year': dateParams.year,
        };
      } else if (searchType == 'range') {
        filters['date_filter']['start'] = dateParams.startDate?.toIso8601String();
        filters['date_filter']['end'] = dateParams.endDate?.toIso8601String();
      }
    }
  }

  /// Generate smart recommendations
  static List<String> _generateRecommendations(
    String query,
    Map<String, dynamic> filters,
    bool isUrdu,
  ) {
    final recommendations = <String>[];
    
    // Use date service recommendations if date filter is active
    if (filters['date_filter']['column'] != null) {
      final dateColumn = filters['date_filter']['column'];
      
      if (dateColumn == 'admission_date') {
        return AdmissionSearchService.generateRecommendations(query, isUrdu);
      } else if (dateColumn == 'struck_off_date') {
        return StruckOffSearchService.generateRecommendations(query, isUrdu);
      } else if (dateColumn == 'graduation_date') {
        return GraduationSearchService.generateRecommendations(query, isUrdu);
      }
    }
    
    // Generate recommendations based on active filters
    if (filters['id'] != null) {
      final id = filters['id'];
      if (isUrdu) {
        recommendations.addAll([
          'آئی ڈی $id کا مکمل ریکارڈ',
          'آئی ڈی $id سے ${id + 10} تک',
          'آئی ڈی $id کے بعد والے طلبہ',
        ]);
      } else {
        recommendations.addAll([
          'ID $id complete record',
          'ID $id to ${id + 10}',
          'Students after ID $id',
        ]);
      }
    } else if (filters['class'] != null && (filters['class'] as List).isNotEmpty) {
      final classes = filters['class'] as List;
      final className = classes.first;
      if (isUrdu) {
        recommendations.addAll([
          'جماعت $className کے تمام طلبہ',
          'جماعت $className کے فعال طلبہ',
          'جماعت $className کی فیس کی تفصیلات',
        ]);
      } else {
        recommendations.addAll([
          'All students in class $className',
          'Active students in class $className',
          'Class $className fee details',
        ]);
      }
    } else if (filters['status'] != null) {
      final status = filters['status'];
      if (isUrdu) {
        final statusUrdu = status == 'active' ? 'فعال' : status == 'graduate' ? 'فارغ' : 'خارج';
        recommendations.addAll([
          '$statusUrdu طلبہ کی فہرست',
          '$statusUrdu طلبہ کا مکمل ریکارڈ',
          '$statusUrdu طلبہ کی تعداد',
        ]);
      } else {
        recommendations.addAll([
          'List of $status students',
          'Complete record of $status students',
          'Count of $status students',
        ]);
      }
    } else if (filters['fee_condition'] != null) {
      if (isUrdu) {
        recommendations.addAll([
          'فیس کی تفصیلات',
          'فیس والے طلبہ',
          'فیس کا مکمل ریکارڈ',
        ]);
      } else {
        recommendations.addAll([
          'Fee details',
          'Students with fee',
          'Complete fee record',
        ]);
      }
    } else {
      // Default recommendations
      if (isUrdu) {
        recommendations.addAll([
          'تمام فعال طلبہ',
          '2024 میں داخل ہونے والے طلبہ',
          'جماعت A کے طلبہ',
        ]);
      } else {
        recommendations.addAll([
          'All active students',
          'Students admitted in 2024',
          'Class A students',
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
        uniqueRecs.add('تمام طلبہ کا ریکارڈ');
      } else {
        uniqueRecs.add('All students records');
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
        'id': null,
        'id_range': null,
        'name': null,
        'father_name': null,
        'class': [],
        'fee_condition': null,
        'status': null,
        'date_filter': {
          'column': null,
          'type': null,
          'value': null,
          'start': null,
          'end': null,
        },
      },
      'conflict_warning': null,
      'recommendations': isUrdu
          ? [
              'تمام فعال طلبہ',
              '2024 میں داخل ہونے والے طلبہ',
              'جماعت A کے طلبہ',
            ]
          : [
              'All active students',
              'Students admitted in 2024',
              'Class A students',
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
