import 'package:intl/intl.dart';

/// Intelligent Admission Date Search Service
/// Provides Google-style search intelligence for admission dates
/// with Urdu support, month names, fuzzy matching, and smart recommendations
class AdmissionSearchService {
  // Urdu admission keywords
  static final List<String> _urduAdmissionKeywords = [
    'داخلہ',
    'داخل',
    'داخلے',
    'ایڈمیشن',
    'رجسٹر',
    'رجسٹریشن',
    'اندراج',
    'داخل ہونے',
  ];

  // English admission keywords
  static final List<String> _englishAdmissionKeywords = [
    'admission',
    'admision', // common typo
    'admisin', // common typo
    'admit',
    'admitted',
    'enroll',
    'enrolled',
    'enrollment',
    'register',
    'registered',
    'registration',
    'join',
    'joined',
  ];

  // Urdu months
  static final Map<String, int> _urduMonths = {
    'جنوری': 1,
    'فروری': 2,
    'مارچ': 3,
    'اپریل': 4,
    'مئی': 5,
    'جون': 6,
    'جولائی': 7,
    'اگست': 8,
    'ستمبر': 9,
    'اکتوبر': 10,
    'نومبر': 11,
    'دسمبر': 12,
  };

  // English months (full and short)
  static final Map<String, int> _englishMonths = {
    'january': 1, 'jan': 1, 'januray': 1, // include typo
    'february': 2, 'feb': 2, 'feburary': 2, // include typo
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4, 'aprl': 4, // include typo
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

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

  /// Check if query is related to admission date
  static bool isAdmissionQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check for Urdu keywords
    for (var keyword in _urduAdmissionKeywords) {
      if (query.contains(keyword)) return true;
    }
    
    // Check for English keywords
    for (var keyword in _englishAdmissionKeywords) {
      if (lowerQuery.contains(keyword)) return true;
    }
    
    // Check for month names with year (likely admission context)
    final hasMonth = _hasMonthName(query);
    final hasYear = RegExp(r'\b(19|20)\d{2}\b').hasMatch(query);
    
    if (hasMonth && hasYear) {
      // If has month + year, check for admission context
      if (query.contains('داخل') || query.contains('ایڈمیشن') || 
          lowerQuery.contains('admission') || lowerQuery.contains('admit') ||
          lowerQuery.contains('enroll')) {
        return true;
      }
    }
    
    return false;
  }

  /// Check if query contains month name
  static bool _hasMonthName(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check Urdu months
    for (var month in _urduMonths.keys) {
      if (query.contains(month)) return true;
    }
    
    // Check English months
    for (var month in _englishMonths.keys) {
      if (lowerQuery.contains(month)) return true;
    }
    
    return false;
  }

  /// Parse admission date query and return search parameters
  static AdmissionSearchParams? parseQuery(String query) {
    if (query.trim().isEmpty) return null;
    
    final trimmedQuery = query.trim();
    
    // Try to extract date range
    final dateRange = _extractDateRange(trimmedQuery);
    if (dateRange != null) {
      return AdmissionSearchParams(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        originalQuery: trimmedQuery,
        searchType: AdmissionSearchType.range,
      );
    }
    
    // Try to extract exact date
    final exactDate = _extractExactDate(trimmedQuery);
    if (exactDate != null) {
      return AdmissionSearchParams(
        exactDate: exactDate,
        originalQuery: trimmedQuery,
        searchType: AdmissionSearchType.exact,
      );
    }
    
    // Try to extract month + year
    final monthYear = _extractMonthYear(trimmedQuery);
    if (monthYear != null) {
      return AdmissionSearchParams(
        month: monthYear['month'],
        year: monthYear['year'],
        originalQuery: trimmedQuery,
        searchType: AdmissionSearchType.month,
      );
    }
    
    // Try to extract year only
    final year = _extractYear(trimmedQuery);
    if (year != null) {
      return AdmissionSearchParams(
        year: year,
        originalQuery: trimmedQuery,
        searchType: AdmissionSearchType.year,
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

  /// Extract month and year from query
  static Map<String, int>? _extractMonthYear(String query) {
    final lowerQuery = query.toLowerCase();
    int? month;
    int? year;
    
    // Extract year
    year = _extractYear(query);
    
    // Extract month from Urdu
    for (var entry in _urduMonths.entries) {
      if (query.contains(entry.key)) {
        month = entry.value;
        break;
      }
    }
    
    // Extract month from English if not found
    if (month == null) {
      for (var entry in _englishMonths.entries) {
        if (lowerQuery.contains(entry.key)) {
          month = entry.value;
          break;
        }
      }
    }
    
    // Return if we have month (year is optional for month-only searches)
    if (month != null) {
      return {'month': month, 'year': year ?? DateTime.now().year};
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
            '2024 میں داخل ہونے والے طلبہ',
            '2023 کے ایڈمیشن کا مکمل ریکارڈ',
            '2020 سے 2024 تک داخلہ ریکارڈ',
          ]
        : [
            'Students admitted in 2024',
            'Admission records of 2023',
            'Admissions from 2020 to 2024',
          ];
    }
    
    // Extract year if present
    final year = _extractYear(trimmedQuery);
    
    // Extract month if present
    final monthYear = _extractMonthYear(trimmedQuery);
    
    // Check if query ends with incomplete word
    final endsWithIncomplete = _endsWithIncompleteWord(trimmedQuery, isUrdu);
    
    if (monthYear != null) {
      recommendations.addAll(_generateMonthRecommendations(
        monthYear['month']!, 
        monthYear['year']!, 
        trimmedQuery, 
        isUrdu
      ));
    } else if (year != null) {
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
        ? '${DateTime.now().year} میں داخل ہونے والے طلبہ'
        : 'Students admitted in ${DateTime.now().year}');
    }
    
    return uniqueRecs.take(3).toList();
  }

  /// Check if query ends with incomplete word
  static bool _endsWithIncompleteWord(String query, bool isUrdu) {
    if (isUrdu) {
      // Check for incomplete Urdu admission words
      return query.endsWith('دا') || 
             query.endsWith('داخ') ||
             query.endsWith('ای') ||
             query.endsWith('ایڈ') ||
             query.endsWith('رج') ||
             query.endsWith('رجس');
    } else {
      // Check for incomplete English words
      final lower = query.toLowerCase();
      return lower.endsWith('adm') ||
             lower.endsWith('admi') ||
             lower.endsWith('admis') ||
             lower.endsWith('admiss') ||
             lower.endsWith('enr') ||
             lower.endsWith('enro');
    }
  }

  /// Generate month-based recommendations
  static List<String> _generateMonthRecommendations(int month, int year, String query, bool isUrdu) {
    final recs = <String>[];
    
    // Get month name
    String monthNameUrdu = _urduMonths.entries.firstWhere((e) => e.value == month).key;
    String monthNameEnglish = _englishMonths.entries.firstWhere((e) => e.value == month).key;
    
    if (isUrdu) {
      if (!query.contains('داخل ہونے والے طلبہ')) {
        recs.add('$monthNameUrdu $year میں داخل ہونے والے طلبہ');
      }
      if (!query.contains('ایڈمیشن کا مکمل ریکارڈ')) {
        recs.add('$monthNameUrdu $year کے ایڈمیشن کا مکمل ریکارڈ');
      }
      if (!query.contains('رجسٹر ہونے والے')) {
        recs.add('$monthNameUrdu $year میں رجسٹر ہونے والے طلبہ');
      }
      
      if (recs.length < 3) {
        recs.add('$monthNameUrdu میں داخلہ کی تاریخیں');
      }
    } else {
      if (!query.toLowerCase().contains('admitted in')) {
        recs.add('Students admitted in $monthNameEnglish $year');
      }
      if (!query.toLowerCase().contains('admission during')) {
        recs.add('Admission during $monthNameEnglish $year complete record');
      }
      if (!query.toLowerCase().contains('enrolled in')) {
        recs.add('Students enrolled in $monthNameEnglish $year');
      }
      
      if (recs.length < 3) {
        recs.add('$monthNameEnglish $year admission dates');
      }
    }
    
    return recs;
  }

  /// Generate year-based recommendations
  static List<String> _generateYearRecommendations(int year, String query, bool isUrdu) {
    final recs = <String>[];
    
    if (isUrdu) {
      // Don't repeat exact query
      if (!query.contains('داخل ہونے والے طلبہ')) {
        recs.add('$year میں داخل ہونے والے طلبہ');
      }
      if (!query.contains('ایڈمیشن کا مکمل ریکارڈ')) {
        recs.add('$year کے ایڈمیشن کا مکمل ریکارڈ');
      }
      if (!query.contains('رجسٹر ہونے والے')) {
        recs.add('$year میں رجسٹر ہونے والے طلبہ');
      }
      
      // Add range suggestions
      if (recs.length < 3) {
        recs.add('${year - 1} سے $year تک داخل ہونے والے طلبہ');
      }
      if (recs.length < 3) {
        recs.add('$year کی داخلہ کی تاریخیں');
      }
    } else {
      if (!query.toLowerCase().contains('admitted in')) {
        recs.add('Students admitted in $year');
      }
      if (!query.toLowerCase().contains('admission year')) {
        recs.add('Admission year $year complete record');
      }
      if (!query.toLowerCase().contains('enrolled in')) {
        recs.add('Students enrolled in $year');
      }
      
      if (recs.length < 3) {
        recs.add('Admitted from ${year - 1} to $year');
      }
      if (recs.length < 3) {
        recs.add('$year admission dates');
      }
    }
    
    return recs;
  }

  /// Generate completion recommendations for incomplete words
  static List<String> _generateCompletionRecommendations(String query, bool isUrdu) {
    final recs = <String>[];
    final currentYear = DateTime.now().year;
    
    if (isUrdu) {
      recs.add('$query ہونے والے طلبہ $currentYear');
      recs.add('$query کا مکمل ریکارڈ');
      recs.add('$query کی فہرست');
    } else {
      recs.add('${query}ission students $currentYear');
      recs.add('${query}ission year $currentYear');
      recs.add('${query}ission list');
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
        recs.add('$query ${year + 3} تک داخل ہونے والے طلبہ');
        recs.add('$query $currentYear کے درمیان ایڈمیشن');
        recs.add('$query شروع ہونے والے داخلہ ریکارڈ');
      }
    }
    // Check if query contains "to" or "from"
    else if (query.toLowerCase().contains('from') && !query.toLowerCase().contains('to')) {
      final year = _extractYear(query);
      if (year != null) {
        recs.add('$query to ${year + 3} admitted students');
        recs.add('$query to $currentYear admission records');
        recs.add('$query onwards admission dates');
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

  /// Build SQL WHERE clause for admission search
  static String buildWhereClause(AdmissionSearchParams params) {
    switch (params.searchType) {
      case AdmissionSearchType.exact:
        return "admission_date = '${_formatDate(params.exactDate!)}'";
      
      case AdmissionSearchType.year:
        return "EXTRACT(YEAR FROM admission_date) = ${params.year}";
      
      case AdmissionSearchType.month:
        return "EXTRACT(YEAR FROM admission_date) = ${params.year} AND EXTRACT(MONTH FROM admission_date) = ${params.month}";
      
      case AdmissionSearchType.range:
        return "admission_date BETWEEN '${_formatDate(params.startDate!)}' AND '${_formatDate(params.endDate!)}'";
    }
  }

  /// Format date for SQL
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

/// Admission search parameters
class AdmissionSearchParams {
  final DateTime? exactDate;
  final int? year;
  final int? month;
  final DateTime? startDate;
  final DateTime? endDate;
  final String originalQuery;
  final AdmissionSearchType searchType;

  AdmissionSearchParams({
    this.exactDate,
    this.year,
    this.month,
    this.startDate,
    this.endDate,
    required this.originalQuery,
    required this.searchType,
  });

  @override
  String toString() {
    return 'AdmissionSearchParams(type: $searchType, query: $originalQuery)';
  }
}

/// Types of admission searches
enum AdmissionSearchType {
  exact,  // Exact date match
  year,   // Year match
  month,  // Month + Year match
  range,  // Date range
}
