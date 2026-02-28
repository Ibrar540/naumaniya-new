import 'package:intl/intl.dart';

/// Intelligent Graduation Date Search Service
/// Provides Google-style search intelligence for graduation dates
/// with Urdu support, fuzzy matching, and smart recommendations
class GraduationSearchService {
  // Urdu graduation keywords
  static final List<String> _urduGraduationKeywords = [
    'فارغ',
    'فارغ التحصیل',
    'گریجویٹ',
    'گریجویشن',
    'فراغت',
    'تکمیل',
  ];

  // English graduation keywords
  static final List<String> _englishGraduationKeywords = [
    'graduate',
    'graduated',
    'graduation',
    'gradute', // common typo
    'gradate', // common typo
    'grad',
    'complete',
    'completed',
    'finish',
    'finished',
  ];

  // Urdu date range keywords
  static final Map<String, String> _urduRangeKeywords = {
    'سے': 'from',
    'تک': 'to',
    'کے درمیان': 'between',
    'میں': 'in',
    'کو': 'on',
    'کا': 'of',
    'کے': 'of',
  };

  /// Check if query is related to graduation
  static bool isGraduationQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check for Urdu keywords
    for (var keyword in _urduGraduationKeywords) {
      if (query.contains(keyword)) return true;
    }
    
    // Check for English keywords
    for (var keyword in _englishGraduationKeywords) {
      if (lowerQuery.contains(keyword)) return true;
    }
    
    // Check for year patterns (4 digits)
    if (RegExp(r'\b(19|20)\d{2}\b').hasMatch(query)) {
      // If contains year and any date-related word
      if (lowerQuery.contains('year') || 
          lowerQuery.contains('سال') ||
          query.contains('میں') ||
          query.contains('کو')) {
        return true;
      }
    }
    
    return false;
  }

  /// Parse graduation date query and return search parameters
  static GraduationSearchParams? parseQuery(String query) {
    if (query.trim().isEmpty) return null;
    
    final trimmedQuery = query.trim();
    
    // Try to extract date range
    final dateRange = _extractDateRange(trimmedQuery);
    if (dateRange != null) {
      return GraduationSearchParams(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        originalQuery: trimmedQuery,
        searchType: GraduationSearchType.range,
      );
    }
    
    // Try to extract exact date
    final exactDate = _extractExactDate(trimmedQuery);
    if (exactDate != null) {
      return GraduationSearchParams(
        exactDate: exactDate,
        originalQuery: trimmedQuery,
        searchType: GraduationSearchType.exact,
      );
    }
    
    // Try to extract year
    final year = _extractYear(trimmedQuery);
    if (year != null) {
      return GraduationSearchParams(
        year: year,
        originalQuery: trimmedQuery,
        searchType: GraduationSearchType.year,
      );
    }
    
    return null;
  }

  /// Extract year from query
  static int? _extractYear(String query) {
    // Match 4-digit year (1900-2099)
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(query);
    if (yearMatch != null) {
      return int.tryParse(yearMatch.group(0)!);
    }
    return null;
  }

  /// Extract exact date from query
  static DateTime? _extractExactDate(String query) {
    // Try various date formats
    final formats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yy',
      'dd/MM/yy',
    ];
    
    for (var format in formats) {
      try {
        final dateFormat = DateFormat(format);
        // Find date pattern in query
        final datePattern = RegExp(r'\d{1,4}[-/]\d{1,2}[-/]\d{1,4}');
        final match = datePattern.firstMatch(query);
        if (match != null) {
          return dateFormat.parse(match.group(0)!);
        }
      } catch (e) {
        continue;
      }
    }
    
    return null;
  }

  /// Extract date range from query
  static Map<String, DateTime>? _extractDateRange(String query) {
    // Pattern: "2020 سے 2023 تک" or "2020 to 2023" or "2020-2023"
    
    // Try hyphen range: 2020-2023
    final hyphenRange = RegExp(r'(\d{4})\s*-\s*(\d{4})');
    final hyphenMatch = hyphenRange.firstMatch(query);
    if (hyphenMatch != null) {
      final startYear = int.parse(hyphenMatch.group(1)!);
      final endYear = int.parse(hyphenMatch.group(2)!);
      return {
        'start': DateTime(startYear, 1, 1),
        'end': DateTime(endYear, 12, 31),
      };
    }
    
    // Try Urdu range: "2020 سے 2023 تک"
    final urduRange = RegExp(r'(\d{4})\s*سے\s*(\d{4})\s*تک');
    final urduMatch = urduRange.firstMatch(query);
    if (urduMatch != null) {
      final startYear = int.parse(urduMatch.group(1)!);
      final endYear = int.parse(urduMatch.group(2)!);
      return {
        'start': DateTime(startYear, 1, 1),
        'end': DateTime(endYear, 12, 31),
      };
    }
    
    // Try English range: "2020 to 2023"
    final englishRange = RegExp(r'(\d{4})\s+(?:to|through|until)\s+(\d{4})', caseSensitive: false);
    final englishMatch = englishRange.firstMatch(query);
    if (englishMatch != null) {
      final startYear = int.parse(englishMatch.group(1)!);
      final endYear = int.parse(englishMatch.group(2)!);
      return {
        'start': DateTime(startYear, 1, 1),
        'end': DateTime(endYear, 12, 31),
      };
    }
    
    // Try date range with full dates
    final datePattern = RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}');
    final dates = datePattern.allMatches(query).toList();
    if (dates.length == 2) {
      try {
        final date1 = _parseFlexibleDate(dates[0].group(0)!);
        final date2 = _parseFlexibleDate(dates[1].group(0)!);
        if (date1 != null && date2 != null) {
          return {
            'start': date1.isBefore(date2) ? date1 : date2,
            'end': date1.isAfter(date2) ? date1 : date2,
          };
        }
      } catch (e) {
        // Continue to next pattern
      }
    }
    
    return null;
  }

  /// Parse date with flexible format
  static DateTime? _parseFlexibleDate(String dateStr) {
    final formats = ['dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yy', 'dd/MM/yy'];
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Generate smart recommendations based on user input
  static List<String> generateRecommendations(String query, bool isUrdu) {
    final recommendations = <String>[];
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      return isUrdu 
        ? [
            '2024 میں فارغ ہونے والے طلبہ',
            '2023 کے فارغ التحصیل طلبہ',
            '2020 سے 2024 تک گریجویٹ طلبہ',
          ]
        : [
            'Students graduated in 2024',
            'Graduate students of 2023',
            'Graduation from 2020 to 2024',
          ];
    }
    
    // Extract year if present
    final year = _extractYear(trimmedQuery);
    
    // Check if query ends with incomplete word
    final endsWithIncomplete = _endsWithIncompleteWord(trimmedQuery, isUrdu);
    
    if (year != null) {
      recommendations.addAll(_generateYearRecommendations(year, trimmedQuery, isUrdu));
    } else if (endsWithIncomplete) {
      recommendations.addAll(_generateCompletionRecommendations(trimmedQuery, isUrdu));
    } else {
      recommendations.addAll(_generateContextualRecommendations(trimmedQuery, isUrdu));
    }
    
    // Ensure exactly 3 unique recommendations
    final uniqueRecs = recommendations.toSet().toList();
    while (uniqueRecs.length < 3) {
      uniqueRecs.add(isUrdu 
        ? '${DateTime.now().year} میں فارغ ہونے والے طلبہ'
        : 'Students graduated in ${DateTime.now().year}');
    }
    
    return uniqueRecs.take(3).toList();
  }

  /// Check if query ends with incomplete word
  static bool _endsWithIncompleteWord(String query, bool isUrdu) {
    if (isUrdu) {
      // Check for incomplete Urdu graduation words
      return query.endsWith('ف') || 
             query.endsWith('فا') ||
             query.endsWith('فار') ||
             query.endsWith('گر') ||
             query.endsWith('گری');
    } else {
      // Check for incomplete English words
      return query.toLowerCase().endsWith('grad') ||
             query.toLowerCase().endsWith('gradu') ||
             query.toLowerCase().endsWith('gradua');
    }
  }

  /// Generate year-based recommendations
  static List<String> _generateYearRecommendations(int year, String query, bool isUrdu) {
    final recs = <String>[];
    
    if (isUrdu) {
      // Don't repeat exact query
      if (!query.contains('فارغ ہونے والے طلبہ')) {
        recs.add('$year میں فارغ ہونے والے طلبہ');
      }
      if (!query.contains('فارغ التحصیل طلبہ')) {
        recs.add('$year کے فارغ التحصیل طلبہ کا مکمل ریکارڈ');
      }
      if (!query.contains('گریجویٹ')) {
        recs.add('$year میں گریجویٹ ہونے والوں کی فہرست');
      }
      
      // Add range suggestions
      if (recs.length < 3) {
        recs.add('${year - 1} سے $year تک فارغ ہونے والے طلبہ');
      }
      if (recs.length < 3) {
        recs.add('$year کی فراغت کی تاریخیں');
      }
    } else {
      if (!query.toLowerCase().contains('graduated in')) {
        recs.add('Students graduated in $year');
      }
      if (!query.toLowerCase().contains('graduation year')) {
        recs.add('Graduation year $year complete record');
      }
      if (!query.toLowerCase().contains('graduates of')) {
        recs.add('List of $year graduates');
      }
      
      if (recs.length < 3) {
        recs.add('Graduated from ${year - 1} to $year');
      }
      if (recs.length < 3) {
        recs.add('$year graduation dates');
      }
    }
    
    return recs;
  }

  /// Generate completion recommendations for incomplete words
  static List<String> _generateCompletionRecommendations(String query, bool isUrdu) {
    final recs = <String>[];
    final currentYear = DateTime.now().year;
    
    if (isUrdu) {
      recs.add('$query التحصیل $currentYear');
      recs.add('$query ہونے والے طلبہ');
      recs.add('$query طلبہ کی فہرست');
    } else {
      recs.add('${query}uated students $currentYear');
      recs.add('${query}uation year $currentYear');
      recs.add('${query}uates list');
    }
    
    return recs;
  }

  /// Generate contextual recommendations
  static List<String> _generateContextualRecommendations(String query, bool isUrdu) {
    final recs = <String>[];
    final currentYear = DateTime.now().year;
    
    // Check if query contains "سے" (from)
    if (query.contains('سے') && !query.contains('تک')) {
      final year = _extractYear(query);
      if (year != null) {
        recs.add('$query ${year + 3} تک فارغ ہونے والے طلبہ');
        recs.add('$query $currentYear کے درمیان گریجویٹ طلبہ');
        recs.add('$query شروع ہونے والی فراغت کی تاریخیں');
      }
    }
    // Check if query contains "to" or "from"
    else if (query.toLowerCase().contains('from') && !query.toLowerCase().contains('to')) {
      final year = _extractYear(query);
      if (year != null) {
        recs.add('$query to ${year + 3} graduated students');
        recs.add('$query to $currentYear graduation records');
        recs.add('$query onwards graduation dates');
      }
    }
    
    // Default contextual suggestions
    if (recs.isEmpty) {
      if (isUrdu) {
        recs.add('$query $currentYear میں');
        recs.add('$query کا مکمل ریکارڈ');
        recs.add('$query کی تفصیلات');
      } else {
        recs.add('$query in $currentYear');
        recs.add('$query complete record');
        recs.add('$query details');
      }
    }
    
    return recs;
  }

  /// Build SQL WHERE clause for graduation search
  static String buildWhereClause(GraduationSearchParams params) {
    switch (params.searchType) {
      case GraduationSearchType.exact:
        return "graduation_date = '${_formatDate(params.exactDate!)}'";
      
      case GraduationSearchType.year:
        return "EXTRACT(YEAR FROM graduation_date) = ${params.year}";
      
      case GraduationSearchType.range:
        return "graduation_date BETWEEN '${_formatDate(params.startDate!)}' AND '${_formatDate(params.endDate!)}'";
    }
  }

  /// Format date for SQL
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

/// Graduation search parameters
class GraduationSearchParams {
  final DateTime? exactDate;
  final int? year;
  final DateTime? startDate;
  final DateTime? endDate;
  final String originalQuery;
  final GraduationSearchType searchType;

  GraduationSearchParams({
    this.exactDate,
    this.year,
    this.startDate,
    this.endDate,
    required this.originalQuery,
    required this.searchType,
  });

  @override
  String toString() {
    return 'GraduationSearchParams(type: $searchType, query: $originalQuery)';
  }
}

/// Types of graduation searches
enum GraduationSearchType {
  exact,  // Exact date match
  year,   // Year match
  range,  // Date range
}
