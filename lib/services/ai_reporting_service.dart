import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../providers/teacher_provider.dart';
import '../providers/budget_provider.dart';
import '../models/ai_query_result.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:flutter/foundation.dart';
import 'package:naumaniya/services/ai_query_parser.dart';

class AIReportingService {
  final TeacherProvider _teacherProvider;
  final BudgetProvider _budgetProvider;
  // final StudentProvider _studentProvider; // Removed - uses Firebase

  // Configuration options
  final bool enableFuzzyMatching;
  final bool enableAdvancedFiltering;
  final int maxResults;
  final bool enableRangeQueries;

  AIReportingService({
    TeacherProvider? teacherProvider,
    BudgetProvider? budgetProvider,
    this.enableFuzzyMatching = true,
    this.enableAdvancedFiltering = true,
    this.maxResults = 1000,
    this.enableRangeQueries = true,
  })  : _teacherProvider = teacherProvider ?? TeacherProvider(),
        _budgetProvider = budgetProvider ?? BudgetProvider();
        // _studentProvider = studentProvider ?? StudentProvider(); // Removed - uses Firebase

  /// Helper for robust date parsing with multiple formats
  DateTime? _parseDate(String date) {
    try {
      // Try ISO format first
      var parsed = DateTime.tryParse(date);
      if (parsed != null) return parsed;

      // Try common formats
      final formats = [
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
      ];

      for (final format in formats) {
        try {
          // Simple parsing for common formats
          final parts = date.split(RegExp(r'[-/]'));
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);

            // Handle different date formats
            if (format.startsWith('yyyy')) {
              // yyyy-MM-dd format
              return DateTime(year, month, day);
            } else if (format.startsWith('MM')) {
              // MM/dd/yyyy format
              return DateTime(year, day, month);
            } else {
              // dd/MM/yyyy format
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Date parsing failed for "$date": $e');
      return null;
    }
  }

  /// Enhanced query parsing with multiple conditions and Urdu support
  Map<String, dynamic> _parseAdvancedQuery(String query) {
    final result = {
      'modules': <String>[],
      'statuses': <String>[],
      'dateRanges': <Map<String, dynamic>>[],
      'amountRanges': <Map<String, dynamic>>[],
      'classFilters': <String>[],
      'textFilters': <String>[],
      'numericFilters': <Map<String, dynamic>>[],
      'queryIntent': '',
      'suggestions': <String>[],
      'isUrduQuery': false,
    };

    final lowerQuery = query.toLowerCase();
    final isUrduQuery = _detectUrduQuery(query);
    result['isUrduQuery'] = isUrduQuery;

    // Enhanced module detection with Urdu support
    _detectModulesWithUrdu(lowerQuery, query, result);

    // Enhanced status detection with Urdu
    _detectStatusesWithUrdu(lowerQuery, query, result);

    // Enhanced date parsing with Urdu months
    final dateRanges = _extractDateRangesWithUrdu(lowerQuery, query);
    result['dateRanges'] = dateRanges;

    // Enhanced amount parsing with Urdu
    final amountRanges = _extractAmountRangesWithUrdu(lowerQuery, query);
    result['amountRanges'] = amountRanges;

    // Class filters with Urdu support
    _detectClassFiltersWithUrdu(lowerQuery, query, result);

    // Text filters with Urdu support
    final textFilters = _extractTextFiltersWithUrdu(lowerQuery, query);
    result['textFilters'] = textFilters;

    // Numeric filters
    final numericFilters = _extractNumericFilters(lowerQuery);
    result['numericFilters'] = numericFilters;

    // Query intent detection
    result['queryIntent'] = _detectQueryIntent(lowerQuery, query, result);

    // Generate smart suggestions
    result['suggestions'] = _generateSuggestions(result, isUrduQuery);

    return result;
  }

  /// Detect if query contains Urdu text
  bool _detectUrduQuery(String query) {
    final urduRegex = RegExp(
        r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return urduRegex.hasMatch(query);
  }

  /// Enhanced module detection with Urdu keywords
  void _detectModulesWithUrdu(
      String lowerQuery, String originalQuery, Map<String, dynamic> result) {
    // English keywords
    final englishKeywords = {
      'students': ['student', 'admission', 'fee', 'class', 'grade'],
      'teachers': ['teacher', 'salary', 'staff', 'instructor'],
      'budget': [
        'budget',
        'income',
        'expenditure',
        'money',
        'finance',
        'expense'
      ],
    };

    // Urdu keywords
    final urduKeywords = {
      'students': ['طلباء', 'طالب علم', 'فیس', 'کلاس', 'درجہ', 'داخلہ'],
      'teachers': ['اساتذہ', 'استاد', 'تنخواہ', 'ملازم', 'معلم'],
      'budget': ['بجٹ', 'آمدنی', 'خرچ', 'پیسہ', 'مالیہ', 'اخراجات'],
    };

    final modules = result['modules'] as List<String>;

    // Check English keywords
    for (final entry in englishKeywords.entries) {
      if (entry.value.any((keyword) => lowerQuery.contains(keyword))) {
        modules.add(entry.key);
      }
    }

    // Check Urdu keywords
    for (final entry in urduKeywords.entries) {
      if (entry.value.any((keyword) => originalQuery.contains(keyword))) {
        modules.add(entry.key);
      }
    }

    // If no modules detected, add all
    if (modules.isEmpty) {
      modules.addAll(['students', 'teachers', 'budget']);
    }
  }

  /// Enhanced status detection with Urdu
  void _detectStatusesWithUrdu(
      String lowerQuery, String originalQuery, Map<String, dynamic> result) {
    // English status keywords
    final englishStatusKeywords = {
      'active': ['active', 'current', 'present'],
      'inactive': ['inactive', 'inactive'],
      'graduated': ['graduated', 'graduate', 'completed'],
      'struck off': ['struck off', 'struck', 'off'],
      'left': ['left', 'quit', 'resigned'],
    };

    // Urdu status keywords
    final urduStatusKeywords = {
      'active': ['فعال', 'موجود', 'حاضر'],
      'inactive': ['غیر فعال', 'غیر حاضر'],
      'graduated': ['فارغ التحصیل', 'مکمل', 'ختم'],
      'struck off': ['خارج شدہ', 'خارج'],
      'left': ['چھوڑ دیا', 'استعفیٰ', 'برطرف'],
    };

    final statuses = result['statuses'] as List<String>;

    // Check English keywords
    for (final entry in englishStatusKeywords.entries) {
      if (entry.value.any((keyword) => lowerQuery.contains(keyword))) {
        statuses.add(entry.key);
      }
    }

    // Check Urdu keywords
    for (final entry in urduStatusKeywords.entries) {
      if (entry.value.any((keyword) => originalQuery.contains(keyword))) {
        statuses.add(entry.key);
      }
    }
  }

  /// Enhanced date parsing with Urdu months
  List<Map<String, dynamic>> _extractDateRangesWithUrdu(
      String lowerQuery, String originalQuery) {
    final ranges = <Map<String, dynamic>>[];

    // English months
    final englishMonths = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december'
    ];

    // Urdu months
    final urduMonths = [
      'جنوری',
      'فروری',
      'مارچ',
      'اپریل',
      'مئی',
      'جون',
      'جولائی',
      'اگست',
      'ستمبر',
      'اکتوبر',
      'نومبر',
      'دسمبر'
    ];

    // Extract year ranges
    final yearRangeMatch =
        RegExp(r'(\d{4})\s*(?:to|-|سے)\s*(\d{4})').firstMatch(originalQuery);
    if (yearRangeMatch != null) {
      ranges.add({
        'type': 'year_range',
        'start': int.parse(yearRangeMatch.group(1)!),
        'end': int.parse(yearRangeMatch.group(2)!),
      });
    }

    // Extract month-year combinations
    for (int i = 0; i < englishMonths.length; i++) {
      if (lowerQuery.contains(englishMonths[i]) ||
          originalQuery.contains(urduMonths[i])) {
        final yearMatch = RegExp(r'(\d{4})').firstMatch(originalQuery);
        final year = yearMatch != null
            ? int.parse(yearMatch.group(1)!)
            : DateTime.now().year;

        ranges.add({
          'type': 'month_year',
          'month': i + 1,
          'year': year,
        });
        break;
      }
    }

    // Extract specific years
    final yearMatches = RegExp(r'\b(20\d{2})\b').allMatches(originalQuery);
    for (final match in yearMatches) {
      ranges.add({
        'type': 'year',
        'year': int.parse(match.group(1)!),
      });
    }

    return ranges;
  }

  /// Enhanced amount parsing with Urdu
  List<Map<String, dynamic>> _extractAmountRangesWithUrdu(
      String lowerQuery, String originalQuery) {
    final ranges = <Map<String, dynamic>>[];

    // Extract amount ranges with Urdu words
    final rangePatterns = [
      RegExp(r'between\s+(\d+(?:\.\d+)?)\s+and\s+(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s+سے\s+(\d+(?:\.\d+)?)\s+کے\s+درمیان'),
    ];

    for (final pattern in rangePatterns) {
      final rangeMatch = pattern.firstMatch(originalQuery);
      if (rangeMatch != null) {
        ranges.add({
          'type': 'range',
          'min': double.parse(rangeMatch.group(1)!),
          'max': double.parse(rangeMatch.group(2)!),
        });
        break;
      }
    }

    // Extract comparison amounts with Urdu
    final comparisonPatterns = [
      RegExp(r'(more|less|above|below|over|under)\s+than?\s+(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s+سے\s+(زیادہ|کم|اوپر|نیچے)'),
    ];

    for (final pattern in comparisonPatterns) {
      final comparisonMatch = pattern.firstMatch(originalQuery);
      if (comparisonMatch != null) {
        final operator = comparisonMatch.group(1)!;
        final amount = double.parse(comparisonMatch.group(2)!);

        String op;
        if (operator.contains('more') ||
            operator.contains('above') ||
            operator.contains('over') ||
            operator.contains('زیادہ') ||
            operator.contains('اوپر')) {
          op = 'more';
        } else {
          op = 'less';
        }

        ranges.add({
          'type': 'comparison',
          'operator': op,
          'amount': amount,
        });
        break;
      }
    }

    // Extract exact amounts with Urdu
    final exactPatterns = [
      RegExp(r'(\d+(?:\.\d+)?)\s+(?:rupees?|rs?|amount)'),
      RegExp(r'(\d+(?:\.\d+)?)\s+(?:روپے|رقم)'),
    ];

    for (final pattern in exactPatterns) {
      final exactMatch = pattern.firstMatch(originalQuery);
      if (exactMatch != null) {
        ranges.add({
          'type': 'exact',
          'amount': double.parse(exactMatch.group(1)!),
        });
        break;
      }
    }

    return ranges;
  }

  /// Enhanced class detection with Urdu
  void _detectClassFiltersWithUrdu(
      String lowerQuery, String originalQuery, Map<String, dynamic> result) {
    final classFilters = result['classFilters'] as List<String>;

    // English class patterns
    final englishClassMatches =
        RegExp(r'class\s*([a-c])', caseSensitive: false).allMatches(lowerQuery);
    for (final match in englishClassMatches) {
      classFilters.add(match.group(1)!.toUpperCase());
    }

    // Urdu class patterns
    final urduClassMatches = RegExp(r'کلاس\s*([ا-ج])', caseSensitive: false)
        .allMatches(originalQuery);
    for (final match in urduClassMatches) {
      final urduClass = match.group(1)!;
      final classMap = {'ا': 'A', 'ب': 'B', 'ج': 'C'};
      if (classMap.containsKey(urduClass)) {
        classFilters.add(classMap[urduClass]!);
      }
    }
  }

  /// Enhanced text filters with Urdu
  List<String> _extractTextFiltersWithUrdu(
      String lowerQuery, String originalQuery) {
    final filters = <String>[];

    // Extract quoted strings
    final quotedMatches = RegExp(r'"([^"]+)"').allMatches(originalQuery);
    for (final match in quotedMatches) {
      filters.add(match.group(1)!);
    }

    // Extract common keywords in both languages
    final keywords = {
      'name': ['name', 'نام'],
      'description': ['description', 'تفصیل', 'وضاحت'],
      'title': ['title', 'عنوان'],
      'subject': ['subject', 'مضمون'],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((keyword) => originalQuery.contains(keyword))) {
        // Try to extract the value after the keyword
        for (final keyword in entry.value) {
          final pattern = RegExp('$keyword\\s+([\\w\\u0600-\\u06FF]+)');
          final match = pattern.firstMatch(originalQuery);
          if (match != null) {
            filters.add(match.group(1)!);
            break;
          }
        }
      }
    }

    return filters;
  }




  /// Extract numeric filters from query
  List<Map<String, dynamic>> _extractNumericFilters(String query) {
    final filters = <Map<String, dynamic>>[];

    // Extract IDs
    final idMatches = RegExp(r'id\s*[#:]?\s*(\d+)').allMatches(query);
    for (final match in idMatches) {
      filters.add({
        'type': 'id',
        'value': int.parse(match.group(1)!),
      });
    }

    // Extract specific amounts without context
    final amountMatches = RegExp(r'\b(\d+(?:\.\d+)?)\b').allMatches(query);
    for (final match in amountMatches) {
      final amount = double.tryParse(match.group(1)!);
      if (amount != null && amount > 0) {
        filters.add({
          'type': 'amount',
          'value': amount,
        });
      }
    }

    return filters;
  }

  /// Detect query intent
  String _detectQueryIntent(
      String lowerQuery, String originalQuery, Map<String, dynamic> result) {
    final statuses = result['statuses'] as List<String>;
    final dateRanges = result['dateRanges'] as List<Map<String, dynamic>>;
    final amountRanges = result['amountRanges'] as List<Map<String, dynamic>>;

    // Intent patterns
    if (originalQuery.contains('کتنے') || originalQuery.contains('how many')) {
      return 'count';
    }
    if (originalQuery.contains('کل') ||
        originalQuery.contains('total') ||
        originalQuery.contains('sum')) {
      return 'total';
    }
    if (originalQuery.contains('اوسط') ||
        originalQuery.contains('average') ||
        originalQuery.contains('mean')) {
      return 'average';
    }
    if (originalQuery.contains('سب') ||
        originalQuery.contains('all') ||
        originalQuery.contains('every')) {
      return 'list_all';
    }
    if (statuses.isNotEmpty) {
      return 'filter_by_status';
    }
    if (dateRanges.isNotEmpty) {
      return 'filter_by_date';
    }
    if (amountRanges.isNotEmpty) {
      return 'filter_by_amount';
    }

    return 'general_search';
  }

  /// Generate smart suggestions based on query analysis
  List<String> _generateSuggestions(Map<String, dynamic> result, bool isUrdu) {
    final suggestions = <String>[];
    final modules = result['modules'] as List<String>;

    if (isUrdu) {
      // Urdu suggestions
      if (modules.contains('students')) {
        suggestions.addAll([
          'کل طلباء کی تعداد کیا ہے؟',
          'فعال طلباء کی فہرست دکھائیں',
          '2024 میں داخل ہونے والے طلباء',
          'فیس 5000 سے زیادہ والے طلباء',
        ]);
      }
      if (modules.contains('teachers')) {
        suggestions.addAll([
          'کل اساتذہ کی تعداد کیا ہے؟',
          'فعال اساتذہ کی فہرست',
          'تنخواہ 10000 سے زیادہ والے اساتذہ',
          '2023 میں شامل ہونے والے اساتذہ',
        ]);
      }
      if (modules.contains('budget')) {
        suggestions.addAll([
          'کل آمدنی کیا ہے؟',
          '2024 کا بجٹ رپورٹ',
          '5000 سے زیادہ کے اخراجات',
          'جنوری 2024 کی آمدنی',
        ]);
      }
    } else {
      // English suggestions
      if (modules.contains('students')) {
        suggestions.addAll([
          'How many total students?',
          'Show active students list',
          'Students admitted in 2024',
          'Students with fee more than 5000',
        ]);
      }
      if (modules.contains('teachers')) {
        suggestions.addAll([
          'How many total teachers?',
          'Show active teachers list',
          'Teachers with salary more than 10000',
          'Teachers joined in 2023',
        ]);
      }
      if (modules.contains('budget')) {
        suggestions.addAll([
          'What is total income?',
          'Budget report for 2024',
          'Expenditures more than 5000',
          'Income for January 2024',
        ]);
      }
    }

    return suggestions;
  }

  /// Process user query and return structured result
  Future<AIQueryResult> processQuery(String query,
      {required bool isUrdu}) async {
    if (query.trim().isEmpty) {
      throw AIReportingException('Query cannot be empty');
    }

    try {
      debugPrint('=== AI REPORTING DEBUG ===');
      debugPrint('Processing query: "$query"');
      debugPrint('Language:  [1m${isUrdu ? "Urdu" : "English"} [0m');

      // Use the enterprise AI query parser
      final parsedResult = AIQueryParser.parse(query);
      debugPrint('Parsed query: $parsedResult');

      // Convert parser result to internal format
      final parsedQuery = _convertParserResult(parsedResult);
      debugPrint('Converted query: $parsedQuery');

      // Process based on detected module
      AIQueryResult result;
      final module = parsedResult['module'];

      if (module == 'students' || module == 'teachers' || 
          module == 'masjid_income' || module == 'masjid_expenditure' || 
          module == 'madrasa_budget') {
        // Single module query
        debugPrint('Processing single module: $module');
        result = await _processSingleModuleQuery(module, parsedQuery, isUrdu);
      } else {
        // Multi-module or unknown query
        debugPrint('Processing multi-module query');
        result = await _processMultiModuleQuery(parsedQuery, isUrdu);
      }

      // Add recommendations from parser
      result = AIQueryResult(
        module: result.module,
        data: result.data,
        summary: result.summary,
        actions: result.actions,
        filters: result.filters,
        suggestions: parsedResult['recommendations'] ?? [],
      );

      debugPrint(
          'Query processed successfully. Results: ${result.data.length}');
      debugPrint('=== END DEBUG ===');
      return result;
    } catch (e, stack) {
      debugPrint('=== AI REPORTING ERROR ===');
      debugPrint('Failed to process query: $e');
      debugPrint('Stack trace: $stack');
      debugPrint('=== END ERROR ===');
      if (e is AIReportingException) rethrow;
      throw AIReportingException('Failed to process query: $e');
    }
  }

  /// Convert parser result to internal format
  Map<String, dynamic> _convertParserResult(Map<String, dynamic> parserResult) {
    final filters = Map<String, dynamic>.from(parserResult['filters'] as Map);
    
    return {
      'modules': [parserResult['module']],
      'statuses': filters['status'] != null ? [filters['status']] : <String>[],
      'dateRanges': _convertDateFilter(filters['date_filter'] != null ? Map<String, dynamic>.from(filters['date_filter'] as Map) : null),
      'amountRanges': _convertAmountFilter(filters['amount_condition'] != null ? Map<String, dynamic>.from(filters['amount_condition'] as Map) : null),
      'classFilters': filters['class'] ?? <String>[],
      'textFilters': _convertTextFilters(filters),
      'numericFilters': _convertNumericFilters(filters),
      'queryIntent': parserResult['intent'],
      'suggestions': parserResult['recommendations'] ?? <String>[],
      'isUrduQuery': _detectUrduQuery(parserResult['module']),
    };
  }

  /// Convert date filter from parser format
  List<Map<String, dynamic>> _convertDateFilter(Map<String, dynamic>? dateFilter) {
    if (dateFilter == null || dateFilter['type'] == null) return [];
    
    final ranges = <Map<String, dynamic>>[];
    
    switch (dateFilter['type']) {
      case 'year':
        ranges.add({
          'type': 'year',
          'year': dateFilter['value'],
        });
        break;
      case 'month':
        ranges.add({
          'type': 'month_year',
          'month': dateFilter['value']['month'],
          'year': dateFilter['value']['year'],
        });
        break;
      case 'range':
        ranges.add({
          'type': 'year_range',
          'start': dateFilter['start'],
          'end': dateFilter['end'],
        });
        break;
    }
    
    return ranges;
  }

  /// Convert amount filter from parser format
  List<Map<String, dynamic>> _convertAmountFilter(Map<String, dynamic>? amountFilter) {
    if (amountFilter == null || amountFilter['type'] == null) return [];
    
    final ranges = <Map<String, dynamic>>[];
    
    switch (amountFilter['type']) {
      case 'exact':
        ranges.add({
          'type': 'exact',
          'amount': amountFilter['value'],
        });
        break;
      case 'greater_than':
        ranges.add({
          'type': 'comparison',
          'operator': 'more',
          'amount': amountFilter['value'],
        });
        break;
      case 'less_than':
        ranges.add({
          'type': 'comparison',
          'operator': 'less',
          'amount': amountFilter['value'],
        });
        break;
      case 'range':
        ranges.add({
          'type': 'range',
          'min': amountFilter['start'],
          'max': amountFilter['end'],
        });
        break;
    }
    
    return ranges;
  }

  /// Convert text filters from parser format
  List<String> _convertTextFilters(Map<String, dynamic> filters) {
    final textFilters = <String>[];
    
    if (filters['name'] != null) textFilters.add(filters['name']);
    if (filters['father_name'] != null) textFilters.add(filters['father_name']);
    if (filters['description_contains'] != null) textFilters.add(filters['description_contains']);
    
    return textFilters;
  }

  /// Convert numeric filters from parser format
  List<Map<String, dynamic>> _convertNumericFilters(Map<String, dynamic> filters) {
    final numericFilters = <Map<String, dynamic>>[];
    
    if (filters['id'] != null) {
      numericFilters.add({
        'type': 'id',
        'value': filters['id'],
      });
    }
    
    if (filters['id_range'] != null) {
      numericFilters.add({
        'type': 'id_range',
        'start': filters['id_range']['start'],
        'end': filters['id_range']['end'],
      });
    }
    
    return numericFilters;
  }

  /// Process single module query
  Future<AIQueryResult> _processSingleModuleQuery(
      String module, Map<String, dynamic> parsedQuery, bool isUrdu) async {
    switch (module) {
      case 'students':
        return await _processStudentQueryAdvanced(parsedQuery, isUrdu);
      case 'teachers':
        return await _processTeacherQueryAdvanced(parsedQuery, isUrdu);
      case 'masjid_income':
      case 'masjid_expenditure':
      case 'madrasa_budget':
        return await _processBudgetQueryAdvanced(parsedQuery, isUrdu);
      default:
        throw AIReportingException('Unknown module: $module');
    }
  }

  /// Process multi-module query
  Future<AIQueryResult> _processMultiModuleQuery(
      Map<String, dynamic> parsedQuery, bool isUrdu) async {
    final results = <Map<String, dynamic>>[];

    for (final module in parsedQuery['modules']) {
      try {
        final result =
            await _processSingleModuleQuery(module, parsedQuery, isUrdu);
        results.add({
          'module': module,
          'data': result.data,
          'summary': result.summary,
        });
      } catch (e) {
        debugPrint('Error processing module $module: $e');
        // Continue with other modules
      }
    }

    final totalRecords =
        results.fold<int>(0, (sum, r) => sum + (r['data'] as List).length);
    final summary = isUrdu
        ? 'کل ریکارڈز: $totalRecords (${results.length} ماڈیولز)'
        : 'Total records: $totalRecords (${results.length} modules)';

    return AIQueryResult(
      module: 'mixed',
      data: results,
      summary: summary,
      filters: parsedQuery,
      suggestions: parsedQuery['suggestions'] ?? [],
    );
  }

  /// Advanced student query processing with better debugging
  Future<AIQueryResult> _processStudentQueryAdvanced(
      Map<String, dynamic> parsedQuery, bool isUrdu) async {
    try {
      debugPrint('Fetching students data...');
      final students = <Student>[]; // Student data not yet migrated
      debugPrint('Total students fetched: ${students.length}');

      if (students.isEmpty) {
        debugPrint('WARNING: No students data available');
        return AIQueryResult(
          module: 'students',
          data: [],
          summary: isUrdu
              ? 'کوئی طلباء کا ڈیٹا نہیں ملا'
              : 'No students data available',
          filters: parsedQuery,
          suggestions: parsedQuery['suggestions'] ?? [],
        );
      }

      // Log sample data for debugging
      if (students.isNotEmpty) {
        debugPrint('Sample student data:');
        debugPrint(
            'ID: ${students.first.id}, Name: ${students.first.name}, Status: ${students.first.status}');
      }

      List<Student> filteredStudents = students.where((student) {
        bool passesFilter = true;
        String filterReason = '';

        // Apply status filters
        if (parsedQuery['statuses'].isNotEmpty) {
          final statusMatch =
              _applyStatusFilters(student.status, parsedQuery['statuses']);
          if (!statusMatch) {
            filterReason +=
                'Status mismatch (${student.status} vs ${parsedQuery['statuses']}); ';
            passesFilter = false;
          }
        }

        // Apply date filters
        if (parsedQuery['dateRanges'].isNotEmpty) {
          final dateMatch = _applyDateFilters(
              student.admissionDate, parsedQuery['dateRanges']);
          if (!dateMatch) {
            filterReason +=
                'Date mismatch (${student.admissionDate} vs ${parsedQuery['dateRanges']}); ';
            passesFilter = false;
          }
        }

        // Apply class filters
        if (parsedQuery['classFilters'].isNotEmpty) {
          final classMatch =
              _applyClassFilters(student.classId, parsedQuery['classFilters']);
          if (!classMatch) {
            filterReason +=
                'Class mismatch (${student.classId} vs ${parsedQuery['classFilters']}); ';
            passesFilter = false;
          }
        }

        // Apply amount filters
        if (parsedQuery['amountRanges'].isNotEmpty) {
          final fee = double.tryParse(student.fee) ?? 0;
          final amountMatch =
              _applyAmountFilters(fee, parsedQuery['amountRanges']);
          if (!amountMatch) {
            filterReason +=
                'Amount mismatch ($fee vs ${parsedQuery['amountRanges']}); ';
            passesFilter = false;
          }
        }

        // Apply text filters
        if (parsedQuery['textFilters'].isNotEmpty) {
          final textMatch =
              _applyTextFilters(student.name, parsedQuery['textFilters']);
          if (!textMatch) {
            filterReason +=
                'Text mismatch (${student.name} vs ${parsedQuery['textFilters']}); ';
            passesFilter = false;
          }
        }

        // Apply numeric filters
        if (parsedQuery['numericFilters'].isNotEmpty) {
          final numericMatch =
              _applyNumericFilters(student.id, parsedQuery['numericFilters']);
          if (!numericMatch) {
            filterReason +=
                'Numeric mismatch (${student.id} vs ${parsedQuery['numericFilters']}); ';
            passesFilter = false;
          }
        }

        if (!passesFilter && filterReason.isNotEmpty) {
          debugPrint(
              'Student ${student.name} (ID: ${student.id}) filtered out: $filterReason');
        }

        return passesFilter;
      }).toList();

      debugPrint('Students after filtering: ${filteredStudents.length}');

      // If no results and we have strict filters, try with relaxed filters
      if (filteredStudents.isEmpty && _hasStrictFilters(parsedQuery)) {
        debugPrint(
            'No results with strict filters, trying relaxed filtering...');
        filteredStudents =
            _applyRelaxedFiltering(students, parsedQuery).cast<Student>();
        debugPrint(
            'Students after relaxed filtering: ${filteredStudents.length}');
      }

      // Limit results if configured
      if (filteredStudents.length > maxResults) {
        debugPrint('Limiting results to $maxResults');
        filteredStudents = filteredStudents.take(maxResults).toList();
      }

      String summary =
          _generateStudentSummary(filteredStudents, parsedQuery, isUrdu);

      // Add debugging info to summary if no results
      if (filteredStudents.isEmpty) {
        summary += isUrdu
            ? '\n(کل طلباء: ${students.length}, فلٹرز: ${_getFilterSummary(parsedQuery)})'
            : '\n(Total students: ${students.length}, Filters: ${_getFilterSummary(parsedQuery)})';
      }

      return AIQueryResult(
        module: 'students',
        data: filteredStudents,
        summary: summary,
        filters: parsedQuery,
        suggestions: parsedQuery['suggestions'] ?? [],
      );
    } catch (e) {
      debugPrint('Error in _processStudentQueryAdvanced: $e');
      rethrow;
    }
  }

  /// Advanced teacher query processing with better debugging
  Future<AIQueryResult> _processTeacherQueryAdvanced(
      Map<String, dynamic> parsedQuery, bool isUrdu) async {
    try {
      debugPrint('Fetching teachers data...');
      final teachers = await _teacherProvider.fetchTeachers();
      debugPrint('Total teachers fetched: ${teachers.length}');

      if (teachers.isEmpty) {
        debugPrint('WARNING: No teachers data available');
        return AIQueryResult(
          module: 'teachers',
          data: [],
          summary: isUrdu
              ? 'کوئی اساتذہ کا ڈیٹا نہیں ملا'
              : 'No teachers data available',
          filters: parsedQuery,
          suggestions: parsedQuery['suggestions'] ?? [],
        );
      }

      // Log sample data for debugging
      if (teachers.isNotEmpty) {
        debugPrint('Sample teacher data:');
        debugPrint(
            'ID: ${teachers.first.id}, Name: ${teachers.first.name}, Status: ${teachers.first.status}');
      }

      List<Teacher> filteredTeachers = teachers.where((teacher) {
        bool passesFilter = true;
        String filterReason = '';

        // Apply status filters
        if (parsedQuery['statuses'].isNotEmpty) {
          final statusMatch =
              _applyStatusFilters(teacher.status, parsedQuery['statuses']);
          if (!statusMatch) {
            filterReason +=
                'Status mismatch (${teacher.status} vs ${parsedQuery['statuses']}); ';
            passesFilter = false;
          }
        }

        // Apply date filters
        if (parsedQuery['dateRanges'].isNotEmpty) {
          final dateMatch = _applyDateFilters(
              teacher.startingDate, parsedQuery['dateRanges']);
          if (!dateMatch) {
            filterReason +=
                'Date mismatch (${teacher.startingDate} vs ${parsedQuery['dateRanges']}); ';
            passesFilter = false;
          }
        }

        // Apply amount filters
        if (parsedQuery['amountRanges'].isNotEmpty) {
          final salary = teacher.salary.toDouble();
          final amountMatch =
              _applyAmountFilters(salary, parsedQuery['amountRanges']);
          if (!amountMatch) {
            filterReason +=
                'Amount mismatch ($salary vs ${parsedQuery['amountRanges']}); ';
            passesFilter = false;
          }
        }

        // Apply text filters
        if (parsedQuery['textFilters'].isNotEmpty) {
          final textMatch =
              _applyTextFilters(teacher.name, parsedQuery['textFilters']);
          if (!textMatch) {
            filterReason +=
                'Text mismatch (${teacher.name} vs ${parsedQuery['textFilters']}); ';
            passesFilter = false;
          }
        }

        // Apply numeric filters
        if (parsedQuery['numericFilters'].isNotEmpty) {
          final numericMatch =
              _applyNumericFilters(teacher.id, parsedQuery['numericFilters']);
          if (!numericMatch) {
            filterReason +=
                'Numeric mismatch (${teacher.id} vs ${parsedQuery['numericFilters']}); ';
            passesFilter = false;
          }
        }

        if (!passesFilter && filterReason.isNotEmpty) {
          debugPrint(
              'Teacher ${teacher.name} (ID: ${teacher.id}) filtered out: $filterReason');
        }

        return passesFilter;
      }).toList();

      debugPrint('Teachers after filtering: ${filteredTeachers.length}');

      // If no results and we have strict filters, try with relaxed filters
      if (filteredTeachers.isEmpty && _hasStrictFilters(parsedQuery)) {
        debugPrint(
            'No results with strict filters, trying relaxed filtering...');
        filteredTeachers =
            _applyRelaxedFiltering(teachers, parsedQuery).cast<Teacher>();
        debugPrint(
            'Teachers after relaxed filtering: ${filteredTeachers.length}');
      }

      // Limit results if configured
      if (filteredTeachers.length > maxResults) {
        debugPrint('Limiting results to $maxResults');
        filteredTeachers = filteredTeachers.take(maxResults).toList();
      }

      String summary =
          _generateTeacherSummary(filteredTeachers, parsedQuery, isUrdu);

      // Add debugging info to summary if no results
      if (filteredTeachers.isEmpty) {
        summary += isUrdu
            ? '\n(کل اساتذہ: ${teachers.length}, فلٹرز: ${_getFilterSummary(parsedQuery)})'
            : '\n(Total teachers: ${teachers.length}, Filters: ${_getFilterSummary(parsedQuery)})';
      }

      return AIQueryResult(
        module: 'teachers',
        data: filteredTeachers,
        summary: summary,
        filters: parsedQuery,
        suggestions: parsedQuery['suggestions'] ?? [],
      );
    } catch (e) {
      debugPrint('Error in _processTeacherQueryAdvanced: $e');
      rethrow;
    }
  }

  /// Advanced budget query processing with better debugging
  Future<AIQueryResult> _processBudgetQueryAdvanced(
      Map<String, dynamic> parsedQuery, bool isUrdu) async {
    try {
      debugPrint('Fetching budget data...');
      final incomesRaw = await _budgetProvider.fetchIncomes();
      final expendituresRaw = await _budgetProvider.fetchExpenditures();
      debugPrint(
          'Total incomes: ${incomesRaw.length}, Total expenditures: ${expendituresRaw.length}');

      final incomes = incomesRaw.map((e) => Income.fromMap(e)).toList();
      final expenditures =
          expendituresRaw.map((e) => Expenditure.fromMap(e)).toList();

      if (incomes.isEmpty && expenditures.isEmpty) {
        debugPrint('WARNING: No budget data available');
        return AIQueryResult(
          module: 'budget',
          data: [],
          summary:
              isUrdu ? 'کوئی بجٹ کا ڈیٹا نہیں ملا' : 'No budget data available',
          filters: parsedQuery,
          suggestions: parsedQuery['suggestions'] ?? [],
        );
      }

      // Log sample data for debugging
      if (incomes.isNotEmpty) {
        debugPrint(
            'Sample income: ${incomes.first.description} - ${incomes.first.amount}');
      }
      if (expenditures.isNotEmpty) {
        debugPrint(
            'Sample expenditure: ${expenditures.first.description} - ${expenditures.first.amount}');
      }

      List<Income> filteredIncomes = incomes.where((income) {
        bool passesFilter = true;
        String filterReason = '';

        if (parsedQuery['dateRanges'].isNotEmpty) {
          final incomeDate = _parseDate(income.date);
          final dateMatch =
              _applyDateFilters(incomeDate, parsedQuery['dateRanges']);
          if (!dateMatch) {
            filterReason +=
                'Date mismatch (${income.date} vs ${parsedQuery['dateRanges']}); ';
            passesFilter = false;
          }
        }

        if (parsedQuery['amountRanges'].isNotEmpty) {
          final amount = income.amount;
          final amountMatch =
              _applyAmountFilters(amount, parsedQuery['amountRanges']);
          if (!amountMatch) {
            filterReason +=
                'Amount mismatch ($amount vs ${parsedQuery['amountRanges']}); ';
            passesFilter = false;
          }
        }

        if (parsedQuery['textFilters'].isNotEmpty) {
          final textMatch =
              _applyTextFilters(income.description, parsedQuery['textFilters']);
          if (!textMatch) {
            filterReason +=
                'Text mismatch (${income.description} vs ${parsedQuery['textFilters']}); ';
            passesFilter = false;
          }
        }

        if (!passesFilter && filterReason.isNotEmpty) {
          debugPrint(
              'Income ${income.description} filtered out: $filterReason');
        }

        return passesFilter;
      }).toList();

      List<Expenditure> filteredExpenditures =
          expenditures.where((expenditure) {
        bool passesFilter = true;
        String filterReason = '';

        if (parsedQuery['dateRanges'].isNotEmpty) {
          final expenditureDate = _parseDate(expenditure.date);
          final dateMatch =
              _applyDateFilters(expenditureDate, parsedQuery['dateRanges']);
          if (!dateMatch) {
            filterReason +=
                'Date mismatch (${expenditure.date} vs ${parsedQuery['dateRanges']}); ';
            passesFilter = false;
          }
        }

        if (parsedQuery['amountRanges'].isNotEmpty) {
          final amount = expenditure.amount;
          final amountMatch =
              _applyAmountFilters(amount, parsedQuery['amountRanges']);
          if (!amountMatch) {
            filterReason +=
                'Amount mismatch ($amount vs ${parsedQuery['amountRanges']}); ';
            passesFilter = false;
          }
        }

        if (parsedQuery['textFilters'].isNotEmpty) {
          final textMatch = _applyTextFilters(
              expenditure.description, parsedQuery['textFilters']);
          if (!textMatch) {
            filterReason +=
                'Text mismatch (${expenditure.description} vs ${parsedQuery['textFilters']}); ';
            passesFilter = false;
          }
        }

        if (!passesFilter && filterReason.isNotEmpty) {
          debugPrint(
              'Expenditure ${expenditure.description} filtered out: $filterReason');
        }

        return passesFilter;
      }).toList();

      debugPrint('Incomes after filtering: ${filteredIncomes.length}');
      debugPrint(
          'Expenditures after filtering: ${filteredExpenditures.length}');

      var filteredBudget = [...filteredIncomes, ...filteredExpenditures];

      // If no results and we have strict filters, try with relaxed filters
      if (filteredBudget.isEmpty && _hasStrictFilters(parsedQuery)) {
        debugPrint(
            'No results with strict filters, trying relaxed filtering...');
        final allBudget = [...incomes, ...expenditures];
        filteredBudget =
            _applyRelaxedFiltering(allBudget, parsedQuery).cast<Object>();
        debugPrint('Budget after relaxed filtering: ${filteredBudget.length}');
      }

      // Limit results if configured
      if (filteredBudget.length > maxResults) {
        debugPrint('Limiting results to $maxResults');
        filteredBudget = filteredBudget.take(maxResults).toList();
      }

      String summary = _generateBudgetSummary(
          filteredIncomes, filteredExpenditures, parsedQuery, isUrdu);

      // Add debugging info to summary if no results
      if (filteredBudget.isEmpty) {
        summary += isUrdu
            ? '\n(کل بجٹ ریکارڈز: ${incomes.length + expenditures.length}, فلٹرز: ${_getFilterSummary(parsedQuery)})'
            : '\n(Total budget records: ${incomes.length + expenditures.length}, Filters: ${_getFilterSummary(parsedQuery)})';
      }

      return AIQueryResult(
        module: 'budget',
        data: filteredBudget,
        summary: summary,
        filters: parsedQuery,
        suggestions: parsedQuery['suggestions'] ?? [],
      );
    } catch (e) {
      debugPrint('Error in _processBudgetQueryAdvanced: $e');
      rethrow;
    }
  }

  /// Check if query has strict filters that might be too restrictive
  bool _hasStrictFilters(Map<String, dynamic> parsedQuery) {
    return parsedQuery['statuses'].isNotEmpty ||
        parsedQuery['dateRanges'].isNotEmpty ||
        parsedQuery['amountRanges'].isNotEmpty ||
        parsedQuery['classFilters'].isNotEmpty ||
        parsedQuery['textFilters'].isNotEmpty ||
        parsedQuery['numericFilters'].isNotEmpty;
  }

  /// Apply relaxed filtering when strict filters return no results
  List<dynamic> _applyRelaxedFiltering(
      List<dynamic> data, Map<String, dynamic> parsedQuery) {
    debugPrint('Applying relaxed filtering...');

    // Only apply text filters (most common user intent)
    if (parsedQuery['textFilters'].isNotEmpty) {
      return data.where((item) {
        String searchText = '';
        if (item is Student) {
          searchText = '${item.name} ${item.status}';
        } else if (item is Teacher) {
          searchText = '${item.name} ${item.status}';
        } else if (item is Income) {
          searchText = item.description;
        } else if (item is Expenditure) {
          searchText = item.description;
        }

        return parsedQuery['textFilters'].any((filter) =>
            searchText.toLowerCase().contains(filter.toLowerCase()));
      }).toList();
    }

    // If no text filters, return all data
    return data;
  }

  /// Get a summary of applied filters for debugging
  String _getFilterSummary(Map<String, dynamic> parsedQuery) {
    final filters = <String>[];
    if (parsedQuery['statuses'].isNotEmpty)
      filters.add('Status: ${parsedQuery['statuses']}');
    if (parsedQuery['dateRanges'].isNotEmpty)
      filters.add('Date: ${parsedQuery['dateRanges']}');
    if (parsedQuery['amountRanges'].isNotEmpty)
      filters.add('Amount: ${parsedQuery['amountRanges']}');
    if (parsedQuery['classFilters'].isNotEmpty)
      filters.add('Class: ${parsedQuery['classFilters']}');
    if (parsedQuery['textFilters'].isNotEmpty)
      filters.add('Text: ${parsedQuery['textFilters']}');
    if (parsedQuery['numericFilters'].isNotEmpty)
      filters.add('Numeric: ${parsedQuery['numericFilters']}');

    return filters.isEmpty ? 'None' : filters.join(', ');
  }

  // Filter application methods
  bool _applyStatusFilters(String status, List<String> filters) {
    if (filters.isEmpty) return true;
    return filters
        .any((filter) => status.toLowerCase().contains(filter.toLowerCase()));
  }

  bool _applyDateFilters(DateTime? date, List<Map<String, dynamic>> filters) {
    if (filters.isEmpty || date == null) return true;

    for (final filter in filters) {
      switch (filter['type']) {
        case 'year':
          if (date.year == filter['year']) return true;
          break;
        case 'month_year':
          if (date.month == filter['month'] && date.year == filter['year'])
            return true;
          break;
        case 'year_range':
          if (date.year >= filter['start'] && date.year <= filter['end'])
            return true;
          break;
      }
    }
    return false;
  }

  bool _applyClassFilters(int? classId, List<String> filters) {
    if (filters.isEmpty || classId == null) return true;
    final classMap = {'A': 1, 'B': 2, 'C': 3};
    return filters.any((filter) => classMap[filter] == classId);
  }

  bool _applyAmountFilters(double amount, List<Map<String, dynamic>> filters) {
    if (filters.isEmpty) return true;

    for (final filter in filters) {
      switch (filter['type']) {
        case 'comparison':
          final operator = filter['operator'];
          final filterAmount = filter['amount'];
          if (operator == 'more' && amount <= filterAmount) return false;
          if (operator == 'less' && amount >= filterAmount) return false;
          break;
        case 'range':
          if (amount < filter['min'] || amount > filter['max']) return false;
          break;
        case 'exact':
          if ((amount - filter['amount']).abs() > 0.01) return false;
          break;
      }
    }
    return true;
  }

  bool _applyTextFilters(String text, List<String> filters) {
    if (filters.isEmpty) return true;
    final lowerText = text.toLowerCase();
    if (enableFuzzyMatching) {
      // Fuzzy match: if any filter is similar enough to the text
      return filters.any((filter) {
        final lowerFilter = filter.toLowerCase();
        // Direct contains still counts as a match
        if (lowerText.contains(lowerFilter)) return true;
        // Fuzzy similarity
        final similarity =
            StringSimilarity.compareTwoStrings(lowerText, lowerFilter);
        return similarity > 0.7;
      });
    } else {
      // Original contains logic
      return filters.any((filter) => lowerText.contains(filter.toLowerCase()));
    }
  }

  bool _applyNumericFilters(int? id, List<Map<String, dynamic>> filters) {
    if (filters.isEmpty || id == null) return true;

    for (final filter in filters) {
      if (filter['type'] == 'id' && filter['value'] == id) return true;
    }
    return false;
  }

  // Summary generation methods
  String _generateStudentSummary(
      List<Student> students, Map<String, dynamic> filters, bool isUrdu) {
    final count = students.length;
    final totalFees = students.fold<double>(
        0, (sum, s) => sum + (double.tryParse(s.fee) ?? 0));

    if (filters['statuses'].isNotEmpty) {
      final statuses = filters['statuses'].join(', ');
      return isUrdu
          ? 'طلباء با حیثیت "$statuses": $count (کل فیس: $totalFees)'
          : 'Students with status "$statuses": $count (Total fees: $totalFees)';
    }

    return isUrdu
        ? 'کل طلباء: $count (کل فیس: $totalFees)'
        : 'Total students: $count (Total fees: $totalFees)';
  }

  String _generateTeacherSummary(
      List<Teacher> teachers, Map<String, dynamic> filters, bool isUrdu) {
    final count = teachers.length;
    final totalSalary = teachers.fold<int>(0, (sum, t) => sum + t.salary);

    if (filters['statuses'].isNotEmpty) {
      final statuses = filters['statuses'].join(', ');
      return isUrdu
          ? 'اساتذہ با حیثیت "$statuses": $count (کل تنخواہ: $totalSalary)'
          : 'Teachers with status "$statuses": $count (Total salary: $totalSalary)';
    }

    return isUrdu
        ? 'کل اساتذہ: $count (کل تنخواہ: $totalSalary)'
        : 'Total teachers: $count (Total salary: $totalSalary)';
  }

  String _generateBudgetSummary(
      List<Income> incomes,
      List<Expenditure> expenditures,
      Map<String, dynamic> filters,
      bool isUrdu) {
    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenditure =
        expenditures.fold<double>(0, (sum, e) => sum + e.amount);
    final netAmount = totalIncome - totalExpenditure;

    return isUrdu
        ? 'کل بجٹ ریکارڈز: ${incomes.length + expenditures.length}\nکل آمدنی: $totalIncome\nکل اخراجات: $totalExpenditure\nخالص رقم: $netAmount'
        : 'Total budget records: ${incomes.length + expenditures.length}\nTotal income: $totalIncome\nTotal expenditure: $totalExpenditure\nNet amount: $netAmount';
  }
}

/// Custom exception for AI reporting errors
class AIReportingException implements Exception {
  final String message;
  AIReportingException(this.message);

  @override
  String toString() => 'AIReportingException: $message';
}
