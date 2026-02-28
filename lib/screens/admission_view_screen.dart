import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'admission_form_screen.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';
import '../services/graduation_search_service.dart';
import '../services/struckoff_search_service.dart';
import '../services/admission_search_service.dart';

class AdmissionViewScreen extends StatefulWidget {
  const AdmissionViewScreen({super.key});

  @override
  _AdmissionViewScreenState createState() => _AdmissionViewScreenState();
}

class SearchResult {
  final double score;
  final List<String> matchReasons;
  final Map<String, dynamic> admission;
  
  SearchResult({
    required this.score,
    required this.matchReasons,
    required this.admission,
  });
}

class _AdmissionViewScreenState extends State<AdmissionViewScreen> {
  // DatabaseService is static, no instance needed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _admissions = [];
  int? _lastId;
  bool _isLoading = false;
  bool _hasMore = true;
  final _scrollController = ScrollController();
  
  // Enhanced search mappings
  final Map<String, String> _urduMonths = {
    'جنوری': 'january', 'فروری': 'february', 'مارچ': 'march', 'اپریل': 'april',
    'مئی': 'may', 'جون': 'june', 'جولائی': 'july', 'اگست': 'august',
    'ستمبر': 'september', 'اکتوبر': 'october', 'نومبر': 'november', 'دسمبر': 'december'
  };
  
  final Map<String, int> _monthNumbers = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
    'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
  };  

  final Map<String, String> _urduStatusMap = {
    'فعال': 'active', 
    'فعال طلباء': 'active',
    'فارغ التحصیل': 'graduate', 
    'فارغ': 'graduate',
    'فارغ طلباء': 'graduate',
    'فارغ التحصیل طلباء': 'graduate',
    'گریجویٹ': 'graduate', 
    'خارج شدہ': 'struck off',
    'خارج': 'struck off',
    'خارج طلباء': 'struck off',
    'خارج شدہ طلباء': 'struck off',
    'اسٹرک آف': 'struck off'
  };
  
  List<String> _searchHistory = [];
  List<String> _smartSuggestions = [];
  bool _showSuggestions = false;
  Map<String, int> _searchAnalytics = {};
  Map<String, List<String>> _searchPatterns = {};

  @override
  void initState() {
    super.initState();
    _fetchAdmissions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _fetchAdmissions();
    }
  }

  Future<void> _fetchAdmissions() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseService.getAdmissionsPaginated(
          lastId: _lastId);

      if (data.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        _admissions.addAll(data);
        if (data.isNotEmpty) {
          _lastId = data.last['id'];
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }  
  
  Future<void> _updateStudentStatus(String id, String status) async {
    try {
      final updateData = <String, dynamic>{'status': status};
      
      // Add the appropriate date field based on status
      final now = DateTime.now().toIso8601String().split('T')[0];
      if (status == 'Graduate') {
        updateData['graduation_date'] = now;
        updateData['struck_off_date'] = null;
      } else if (status == 'Struck Off') {
        updateData['struck_off_date'] = now;
        updateData['graduation_date'] = null;
      } else if (status == 'Active') {
        updateData['graduation_date'] = null;
        updateData['struck_off_date'] = null;
      }
      
      await DatabaseService.updateAdmission(id, updateData);
      // Reload the admissions list
      setState(() {
        _admissions.clear();
        _lastId = null;
        _hasMore = true;
      });
      await _fetchAdmissions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAdmissions(String query) {
    setState(() {
      _searchQuery = query;
      _generateSmartSuggestions(query);
      
      if (query.trim().isNotEmpty) {
        final trimmedQuery = query.trim();
        _searchAnalytics[trimmedQuery] = (_searchAnalytics[trimmedQuery] ?? 0) + 1;
        
        if (!_searchHistory.contains(trimmedQuery)) {
          _searchHistory.insert(0, trimmedQuery);
          if (_searchHistory.length > 15) {
            _searchHistory = _searchHistory.take(15).toList();
          }
        } else {
          _searchHistory.remove(trimmedQuery);
          _searchHistory.insert(0, trimmedQuery);
        }
      }
      
      _showSuggestions = query.trim().isNotEmpty;
      
      // Debug UI display
      print('UI Debug - _showSuggestions: $_showSuggestions, _smartSuggestions.length: ${_smartSuggestions.length}, _searchQuery: "$_searchQuery"');
    });
  }

  void _generateSmartSuggestions(String query) {
    final lowerQuery = query.toLowerCase().trim();
    _smartSuggestions.clear();
    
    if (lowerQuery.isEmpty) {
      return;
    }
    
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;
    
    // PRIORITY 1: INTELLIGENT ID SEARCH SYSTEM
    final suggestions = _generateIntelligentIdSuggestions(lowerQuery, isUrdu);
    
    if (suggestions.isNotEmpty) {
      _smartSuggestions = suggestions;
      return;
    }
    
    // PRIORITY 2: INTELLIGENT ADMISSION DATE SEARCH SYSTEM
    final dateSuggestions = _generateIntelligentDateSuggestions(lowerQuery, isUrdu);
    
    if (dateSuggestions.isNotEmpty) {
      print('Date suggestions generated: $dateSuggestions');
      _smartSuggestions = dateSuggestions;
      return;
    }
    
    // PRIORITY 3: INTELLIGENT STRUCK-OFF DATE SEARCH SYSTEM
    final struckOffSuggestions = _generateIntelligentStruckOffSuggestions(lowerQuery, isUrdu);
    
    if (struckOffSuggestions.isNotEmpty) {
      _smartSuggestions = struckOffSuggestions;
      return;
    }
    
    // PRIORITY 4: INTELLIGENT GRADUATION DATE SEARCH SYSTEM
    final graduationSuggestions = _generateIntelligentGraduationSuggestions(lowerQuery, isUrdu);
    
    if (graduationSuggestions.isNotEmpty) {
      _smartSuggestions = graduationSuggestions;
      return;
    }
    
    // PRIORITY 5: INTELLIGENT CLASS SEARCH SYSTEM
    final classSuggestions = _generateIntelligentClassSuggestions(lowerQuery, isUrdu);
    
    if (classSuggestions.isNotEmpty) {
      print('Class suggestions generated: $classSuggestions');
      _smartSuggestions = classSuggestions;
      return;
    }
    
    // PRIORITY 6: INTELLIGENT FEE SEARCH SYSTEM
    final feeSuggestions = _generateIntelligentFeeSuggestions(lowerQuery, isUrdu);
    
    if (feeSuggestions.isNotEmpty) {
      print('Fee suggestions generated: $feeSuggestions');
      _smartSuggestions = feeSuggestions;
      return;
    }
    
    // PRIORITY 7: INTELLIGENT STATUS SEARCH SYSTEM
    final statusSuggestions = _generateIntelligentStatusSuggestions(lowerQuery, isUrdu);
    
    if (statusSuggestions.isNotEmpty) {
      print('Status suggestions generated: $statusSuggestions');
      _smartSuggestions = statusSuggestions;
      return;
    }
    
    // PRIORITY 8: INTELLIGENT NAME SEARCH SYSTEM
    final nameSuggestions = _generateIntelligentNameSuggestions(lowerQuery, isUrdu);
    
    if (nameSuggestions.isNotEmpty) {
      _smartSuggestions = nameSuggestions;
      return;
    } else {
      // PRIORITY 8: DEFAULT SUGGESTIONS
      _smartSuggestions.addAll(isUrdu ? [
        'فعال طلباء',
        'کلاس A کے طلباء',
        'سال 2024 کے داخلے',
      ] : [
        'active students',
        'class A students',
        'admissions 2024',
      ]);
    }
    
    // Always limit to exactly 3 suggestions
    _smartSuggestions = _smartSuggestions.take(3).toList();
    
    // Apply Google-like learning: Sort by popularity
    _smartSuggestions.sort((a, b) {
      final aCount = _searchAnalytics[a] ?? 0;
      final bCount = _searchAnalytics[b] ?? 0;
      return bCount.compareTo(aCount); // Most popular first
    });
  }

  List<String> _generateIntelligentIdSuggestions(String query, bool isUrdu) {
    final suggestions = <String>[];
    
    // Detect ID patterns: "آئی ڈی 7", "ID 7", "7 کا ریکارڈ", "7", "students with id 7"
    final hasIdKeyword = query.contains('آئی ڈی') || 
                         query.contains('id') || 
                         query.contains('ریکارڈ') ||
                         query.contains('record') ||
                         query.contains('students with id') ||
                         query.contains('student with id');
    
    final numberMatch = RegExp(r'\d+').firstMatch(query);
    final extractedNumber = numberMatch?.group(0);
    
    // Check if this is an ID-related query
    final isIdQuery = hasIdKeyword || 
                      query.contains('کا ریکارڈ') ||
                      RegExp(r'\d+\s+and\s+\d+').hasMatch(query) ||
                      (extractedNumber != null && query.length <= 5 && RegExp(r'^\d+$').hasMatch(query.trim()) && 
                       !query.contains('سال') && !query.contains('year') && 
                       !query.contains('فیس') && !query.contains('fee') &&
                       !RegExp(r'20\d{2}').hasMatch(query));
    
    if (!isIdQuery || extractedNumber == null) {
      return suggestions; // Return empty if not ID query
    }
    
    final num = int.parse(extractedNumber);
    
    // Analyze what user has typed after the number for dynamic suggestions
    final afterNumber = query.substring(query.indexOf(extractedNumber) + extractedNumber.length).trim();
    final beforeNumber = query.substring(0, query.indexOf(extractedNumber)).trim();
    
    // Special handling for "students with id" patterns
    if (query.contains('students with id') || query.contains('student with id')) {
      if (isUrdu) {
        suggestions.addAll([
          'آئی ڈی $num اور ${num + 1} والے طلباء',
          'آئی ڈی $num سے ${num + 5} تک کے طلباء',
          'آئی ڈی $num کے بعد والے طلباء',
        ]);
      } else {
        // Handle partial "students with id X an" -> suggest "and Y"
        if (query.endsWith(' an') || query.endsWith(' a')) {
          suggestions.addAll([
            'students with id $num and ${num + 1}',
            'students with id $num and ${num + 2}',
            'students with id $num and ${num + 3}',
          ]);
        } else {
          suggestions.addAll([
            'students with id $num and ${num + 1}',
            'students with id $num to ${num + 5}',
            'students with id greater than $num',
          ]);
        }
      }
      return suggestions.take(3).toList();
    }
    
    if (isUrdu) {
      // URDU INTELLIGENT SUGGESTIONS
      
      // If user typed "آئی ڈی 7 س" - focus on "سے" patterns
      if (afterNumber.startsWith('س') && !afterNumber.contains('تک')) {
        suggestions.addAll([
          'آئی ڈی $num سے ${num + 10} تک',
          'آئی ڈی $num سے ${num + 20} تک',
          'آئی ڈی $num سے پہلے',
        ]);
      }
      // If user typed "آئی ڈی 7 ک" - focus on "کا/کے" patterns
      else if (afterNumber.startsWith('ک')) {
        suggestions.addAll([
          'آئی ڈی $num کا ریکارڈ',
          'آئی ڈی $num کے بعد',
          'آئی ڈی $num کے بعد والے ریکارڈ',
        ]);
      }
      // If user typed "آئی ڈی 7 ب" - focus on "بعد" patterns
      else if (afterNumber.startsWith('ب')) {
        suggestions.addAll([
          'آئی ڈی $num کے بعد',
          'آئی ڈی $num کے بعد والے ریکارڈ',
          'آئی ڈی $num سے ${num + 10} تک',
        ]);
      }
      // If user typed "آئی ڈی 7 پ" - focus on "پہلے" patterns
      else if (afterNumber.startsWith('پ')) {
        suggestions.addAll([
          'آئی ڈی $num سے پہلے',
          'آئی ڈی $num سے پہلے والے ریکارڈ',
          'آئی ڈی $num کا ریکارڈ',
        ]);
      }
      // If user just typed number or basic ID
      else if (afterNumber.isEmpty || afterNumber.length <= 2) {
        suggestions.addAll([
          'آئی ڈی $num کا ریکارڈ',
          'آئی ڈی $num سے ${num + 10} تک',
          'آئی ڈی $num کے بعد والے ریکارڈ',
        ]);
      }
      // If user typed "7 کا ریکارڈ" - extend meaningfully
      else if (query.contains('کا ریکارڈ')) {
        suggestions.addAll([
          'آئی ڈی $num کا مکمل ریکارڈ',
          'آئی ڈی $num سے ${num + 5} تک',
          'آئی ڈی $num کے بعد',
        ]);
      }
      // Default Urdu patterns
      else {
        suggestions.addAll([
          'آئی ڈی $num کا ریکارڈ',
          'آئی ڈی $num کے بعد',
          'آئی ڈی $num سے ${num + 10} تک',
        ]);
      }
    } else {
      // ENGLISH INTELLIGENT SUGGESTIONS
      
      // If user typed "ID 7 t" - focus on "to" patterns
      if (afterNumber.startsWith('t')) {
        suggestions.addAll([
          'ID $num to ${num + 10}',
          'ID $num to ${num + 20}',
          'ID $num record',
        ]);
      }
      // If user typed "ID 7 a" - focus on "and/after" patterns
      else if (afterNumber.startsWith('a')) {
        suggestions.addAll([
          'ID $num and above',
          'ID $num after',
          'ID $num to ${num + 10}',
        ]);
      }
      // If user typed "ID 7 b" - focus on "before/below" patterns
      else if (afterNumber.startsWith('b')) {
        suggestions.addAll([
          'ID $num before',
          'ID $num and below',
          'ID $num record',
        ]);
      }
      // If user typed "ID 7 r" - focus on "record" patterns
      else if (afterNumber.startsWith('r')) {
        suggestions.addAll([
          'ID $num record',
          'ID $num range',
          'ID $num to ${num + 10}',
        ]);
      }
      // If user just typed number or basic ID
      else if (afterNumber.isEmpty || afterNumber.length <= 2) {
        suggestions.addAll([
          'ID $num record',
          'ID $num to ${num + 10}',
          'ID $num and above',
        ]);
      }
      // Default English patterns
      else {
        suggestions.addAll([
          'ID $num record',
          'ID $num and above',
          'ID $num to ${num + 10}',
        ]);
      }
    }
    
    // Ensure exactly 3 unique suggestions
    final uniqueSuggestions = suggestions.toSet().toList();
    
    // If we have less than 3, fill with popular patterns
    while (uniqueSuggestions.length < 3) {
      final fallback = isUrdu 
          ? 'آئی ڈی ${num + uniqueSuggestions.length} کا ریکارڈ'
          : 'ID ${num + uniqueSuggestions.length} record';
      
      if (!uniqueSuggestions.contains(fallback)) {
        uniqueSuggestions.add(fallback);
      } else {
        break; // Avoid infinite loop
      }
    }
    
    return uniqueSuggestions.take(3).toList();
  }

  bool _matchesSearchQuery(Map<String, dynamic> admission, String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return true;
    
    // Debug search processing
    print('Processing search for: "$lowerQuery" on admission ID: ${admission['id']}');
    
    // INTELLIGENT ID SEARCH PROCESSING
    try {
      final idSearchResult = _processIntelligentIdSearch(admission, lowerQuery);
      if (idSearchResult != null) {
        return idSearchResult; // Use ID search result if it's an ID query
      }
    } catch (e) {
      // If ID search fails, continue to other search types
      print('ID search error: $e');
    }
    
    // INTELLIGENT ADMISSION DATE SEARCH PROCESSING
    try {
      final dateSearchResult = _processIntelligentDateSearch(admission, lowerQuery);
      if (dateSearchResult != null) {
        return dateSearchResult; // Use date search result if it's a date query
      }
    } catch (e) {
      // If date search fails, continue to other search types
      print('Date search error: $e');
      print('Date search error stack: ${e.toString()}');
    }
    
    // INTELLIGENT STRUCK-OFF DATE SEARCH PROCESSING
    try {
      final struckOffSearchResult = _processIntelligentStruckOffSearch(admission, lowerQuery);
      if (struckOffSearchResult != null) {
        return struckOffSearchResult; // Use struck-off search result if it's a struck-off query
      }
    } catch (e) {
      // If struck-off search fails, continue to other search types
      print('Struck-off search error: $e');
    }
    
    // INTELLIGENT GRADUATION DATE SEARCH PROCESSING
    try {
      final graduationSearchResult = _processIntelligentGraduationSearch(admission, lowerQuery);
      if (graduationSearchResult != null) {
        return graduationSearchResult; // Use graduation search result if it's a graduation query
      }
    } catch (e) {
      // If graduation search fails, continue to other search types
      print('Graduation search error: $e');
    }
    
    // INTELLIGENT CLASS SEARCH PROCESSING
    try {
      final classSearchResult = _processIntelligentClassSearch(admission, lowerQuery);
      if (classSearchResult != null) {
        print('Class search result for "${lowerQuery}": $classSearchResult');
        return classSearchResult; // Use class search result if it's a class query
      }
    } catch (e) {
      // If class search fails, continue to other search types
      print('Class search error: $e');
      print('Class search error stack: ${e.toString()}');
    }
    
    // INTELLIGENT FEE SEARCH PROCESSING
    try {
      final feeSearchResult = _processIntelligentFeeSearch(admission, lowerQuery);
      if (feeSearchResult != null) {
        print('Fee search result for "${lowerQuery}": $feeSearchResult');
        return feeSearchResult; // Use fee search result if it's a fee query
      }
    } catch (e) {
      // If fee search fails, continue to other search types
      print('Fee search error: $e');
      print('Fee search error stack: ${e.toString()}');
    }
    
    // INTELLIGENT STATUS SEARCH PROCESSING
    try {
      final statusSearchResult = _processIntelligentStatusSearch(admission, lowerQuery);
      if (statusSearchResult != null) {
        print('Status search result for "${lowerQuery}": $statusSearchResult');
        return statusSearchResult; // Use status search result if it's a status query
      }
    } catch (e) {
      // If status search fails, continue to other search types
      print('Status search error: $e');
    }
    
    // INTELLIGENT NAME SEARCH PROCESSING
    try {
      final nameSearchResult = _processIntelligentNameSearch(admission, lowerQuery);
      if (nameSearchResult != null) {
        return nameSearchResult; // Use name search result if it's a name query
      }
    } catch (e) {
      // If name search fails, continue to other search types
      print('Name search error: $e');
    }
    
    // FALLBACK: Basic text search with Urdu support
    final id = admission['id']?.toString() ?? '';
    final name = admission['name']?.toString() ?? '';
    final fatherName = admission['father_name']?.toString() ?? '';
    final className = admission['class']?.toString() ?? '';
    final status = admission['status']?.toString() ?? '';
    final mobileNo = admission['mobile_no']?.toString() ?? '';
    
    // For Urdu text, don't convert to lowercase as it breaks matching
    // Check if query contains Urdu characters
    final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    
    if (hasUrdu) {
      // Urdu search - case-sensitive and with status translation
      final trimmedQuery = query.trim();
      
      // Check if it's a status search in Urdu
      final urduStatus = _urduStatusMap[trimmedQuery];
      if (urduStatus != null) {
        return status.toLowerCase() == urduStatus.toLowerCase();
      }
      
      // Check if it's a month search in Urdu
      final urduMonth = _urduMonths[trimmedQuery];
      if (urduMonth != null) {
        final admissionDateValue = admission['admission_date'];
        if (admissionDateValue != null) {
          try {
            DateTime date;
            // Handle DateTime object (from PostgreSQL)
            if (admissionDateValue is DateTime) {
              date = admissionDateValue;
            } else if (admissionDateValue is String && admissionDateValue.isNotEmpty) {
              date = DateTime.parse(admissionDateValue);
            } else {
              return false;
            }
            
            final monthNum = _monthNumbers[urduMonth];
            if (monthNum != null && date.month == monthNum) {
              return true;
            }
          } catch (e) {
            // Date parsing failed
          }
        }
      }
      
      // Basic Urdu text matching (case-sensitive for Urdu)
      return id.contains(trimmedQuery) ||
             name.contains(trimmedQuery) ||
             fatherName.contains(trimmedQuery) ||
             className.contains(trimmedQuery) ||
             status.contains(trimmedQuery) ||
             mobileNo.contains(trimmedQuery);
    } else {
      // English search - case-insensitive
      final lowerQuery = query.toLowerCase();
      return id.toLowerCase().contains(lowerQuery) ||
             name.toLowerCase().contains(lowerQuery) ||
             fatherName.toLowerCase().contains(lowerQuery) ||
             className.toLowerCase().contains(lowerQuery) ||
             status.toLowerCase().contains(lowerQuery) ||
             mobileNo.toLowerCase().contains(lowerQuery);
    }
  }

  bool? _processIntelligentIdSearch(Map<String, dynamic> admission, String query) {
    // Detect if this is an ID-related query
    final hasIdKeyword = query.contains('آئی ڈی') || 
                         query.contains('id') || 
                         query.contains('ریکارڈ') ||
                         query.contains('record') ||
                         query.contains('students with id') ||
                         query.contains('student with id');
    
    final numberMatch = RegExp(r'\d+').firstMatch(query);
    final extractedNumber = numberMatch?.group(0);
    
    final isIdQuery = hasIdKeyword || 
                      (extractedNumber != null && query.length <= 20) ||
                      RegExp(r'^\d+$').hasMatch(query.trim()) ||
                      query.contains('کا ریکارڈ') ||
                      RegExp(r'\d+\s+and\s+\d+').hasMatch(query);
    
    if (!isIdQuery) {
      return null; // Not an ID query, use fallback search
    }
    
    final admissionId = int.tryParse(admission['id']?.toString() ?? '0') ?? 0;
    
    // Pattern 1: "students with id 2 and 5" or "ID 2 and 5"
    if (RegExp(r'\d+\s+and\s+\d+').hasMatch(query) && !query.contains('between')) {
      final andMatch = RegExp(r'(\d+)\s+and\s+(\d+)').firstMatch(query);
      if (andMatch != null) {
        final id1 = int.parse(andMatch.group(1)!);
        final id2 = int.parse(andMatch.group(2)!);
        return admissionId == id1 || admissionId == id2;
      }
    }
    
    // Pattern 2: Multiple IDs with commas "2, 4, 6" or "2، 4، 6"
    if (query.contains(',') || query.contains('،')) {
      final ids = query.split(RegExp(r'[,،]'))
          .map((s) => RegExp(r'\d+').firstMatch(s.trim())?.group(0))
          .where((id) => id != null)
          .map((id) => int.parse(id!))
          .toList();
      if (ids.isNotEmpty) {
        return ids.contains(admissionId);
      }
    }
    
    // Pattern 3: Range queries with comprehensive Urdu support
    // Urdu: "سے ... تک", "درمیان ... اور"
    // English: "to", "between ... and"
    if ((query.contains('سے') && query.contains('تک')) || 
        (query.contains('درمیان') && query.contains('اور')) ||
        (query.contains('to') && RegExp(r'\d+\s+to\s+\d+').hasMatch(query)) ||
        (query.contains('between') && query.contains('and'))) {
      
      RegExpMatch? rangeMatch;
      
      if (query.contains('between')) {
        rangeMatch = RegExp(r'between.*?(\d+).*?and.*?(\d+)').firstMatch(query);
      } else if (query.contains('درمیان')) {
        rangeMatch = RegExp(r'درمیان.*?(\d+).*?اور.*?(\d+)').firstMatch(query);
      } else if (query.contains('سے') && query.contains('تک')) {
        rangeMatch = RegExp(r'(\d+)\s*سے\s*(\d+)\s*تک').firstMatch(query);
      } else if (query.contains('to')) {
        rangeMatch = RegExp(r'(\d+)\s+to\s+(\d+)').firstMatch(query);
      }
      
      if (rangeMatch != null) {
        final start = int.parse(rangeMatch.group(1)!);
        final end = int.parse(rangeMatch.group(2)!);
        return admissionId >= start && admissionId <= end;
      }
    }
    
    // Pattern 4: Greater than with comprehensive Urdu support
    // Urdu: "سے زیادہ", "سے بڑا", "کے بعد", "سے اوپر", "سے آگے"
    // English: "greater than", "more than", "and above", "after", ">"
    if (query.contains('سے زیادہ') || 
        query.contains('سے بڑا') ||
        query.contains('کے بعد') || 
        query.contains('سے اوپر') ||
        query.contains('سے آگے') ||
        query.contains('and above') || 
        query.contains('after') ||
        query.contains('greater than') ||
        query.contains('more than') ||
        query.contains('>')) {
      
      final greaterMatch = RegExp(r'(?:سے زیادہ|سے بڑا|کے بعد|سے اوپر|سے آگے|and above|after|greater than|more than|>)\s*(\d+)|(\d+)\s*(?:سے زیادہ|سے بڑا|کے بعد|سے اوپر|سے آگے|and above|after)').firstMatch(query);
      if (greaterMatch != null) {
        final targetId = int.parse(greaterMatch.group(1) ?? greaterMatch.group(2)!);
        return admissionId > targetId;
      }
      
      // Fallback: use first number found
      if (extractedNumber != null) {
        final targetId = int.parse(extractedNumber);
        return admissionId > targetId;
      }
    }
    
    // Pattern 5: Less than with comprehensive Urdu support
    // Urdu: "سے کم", "سے چھوٹا", "سے پہلے", "سے نیچے", "سے پیچھے"
    // English: "less than", "before", "and below", "under", "<"
    if (query.contains('سے کم') || 
        query.contains('سے چھوٹا') ||
        query.contains('سے پہلے') || 
        query.contains('سے نیچے') ||
        query.contains('سے پیچھے') ||
        query.contains('before') || 
        query.contains('and below') ||
        query.contains('less than') ||
        query.contains('under') ||
        query.contains('<')) {
      
      final lessMatch = RegExp(r'(?:سے کم|سے چھوٹا|سے پہلے|سے نیچے|سے پیچھے|before|and below|less than|under|<)\s*(\d+)|(\d+)\s*(?:سے کم|سے چھوٹا|سے پہلے|سے نیچے|سے پیچھے|before)').firstMatch(query);
      if (lessMatch != null) {
        final targetId = int.parse(lessMatch.group(1) ?? lessMatch.group(2)!);
        return admissionId < targetId;
      }
      
      // Fallback: use first number found
      if (extractedNumber != null) {
        final targetId = int.parse(extractedNumber);
        return admissionId < targetId;
      }
    }
    
    // Pattern 6: Exact ID match for "آئی ڈی 7", "آئی ڈی 7 کا ریکارڈ", "7 کا ریکارڈ", "7", "students with id 7"
    if (extractedNumber != null) {
      final searchId = int.parse(extractedNumber);
      return admissionId == searchId;
    }
    
    return null; // No valid pattern found
  }

  List<String> _generateIntelligentDateSuggestions(String query, bool isUrdu) {
    // Use the new AdmissionSearchService for intelligent suggestions
    if (!AdmissionSearchService.isAdmissionQuery(query)) {
      return []; // Return empty if not admission query
    }
    
    return AdmissionSearchService.generateRecommendations(query, isUrdu);
  }

  bool _isAdmissionDateQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check for admission date keywords (order matters - check specific keywords first)
    final urduDateKeywords = ['سال', 'مہینہ', 'تاریخ', 'داخلہ', 'داخلے', 'میں داخل', 'کے داخلے', 'سے', 'تک', 'درمیان'];
    final englishDateKeywords = ['admitted', 'admission', 'admissions', 'year', 'month', 'date', 'from', 'to', 'between'];
    
    // Check for year patterns (strong indicator)
    final hasYear = RegExp(r'20\d{2}').hasMatch(query);
    
    // Check for month patterns
    final hasUrduMonth = _urduMonths.keys.any((month) => query.contains(month));
    final hasEnglishMonth = _monthNumbers.keys.any((month) => lowerQuery.contains(month));
    
    // Check for date-related keywords
    final hasUrduKeywords = urduDateKeywords.any((keyword) => query.contains(keyword));
    final hasEnglishKeywords = englishDateKeywords.any((keyword) => lowerQuery.contains(keyword));
    
    // Strong date indicators: year + date keyword, or specific date phrases
    final hasStrongDateIndicator = (hasYear && (hasEnglishKeywords || hasUrduKeywords)) ||
                                   lowerQuery.contains('admitted in') ||
                                   lowerQuery.contains('admission in') ||
                                   lowerQuery.contains('admitted') && hasYear ||
                                   lowerQuery.contains('admission') && hasYear ||
                                   query.contains('میں داخل') ||
                                   query.contains('کے داخلے');
    
    final result = hasStrongDateIndicator || (hasYear && (hasEnglishKeywords || hasUrduKeywords)) || hasUrduMonth || hasEnglishMonth;
    
    // Debug output
    if (result) {
      print('Date query detected: "$query" - Year: $hasYear, UrduMonth: $hasUrduMonth, EnglishMonth: $hasEnglishMonth, UrduKeywords: $hasUrduKeywords, EnglishKeywords: $hasEnglishKeywords');
    }
    
    return result;
  }

  List<String> _generateUrduDateSuggestions(String query, String? year, String? month, String? day) {
    final suggestions = <String>[];
    
    // Analyze user input patterns for dynamic suggestions
    if (year != null) {
      // Year-based suggestions
      if (query.contains('سے') && !query.contains('تک')) {
        // User typed "سال 2024 سے" - focus on range patterns
        suggestions.addAll([
          'سال $year سے ${int.parse(year) + 1} تک داخلے',
          'سال $year سے ${int.parse(year) + 5} تک کے طلباء',
          'سال $year سے اب تک کے داخلے',
        ]);
      } else if (query.contains('میں')) {
        // User typed "سال 2024 میں" - focus on specific year patterns
        suggestions.addAll([
          'سال $year میں داخل ہونے والے طلباء',
          'سال $year میں کل داخلے',
          'سال $year میں فعال طلباء',
        ]);
      } else if (query.contains('کے')) {
        // User typed "سال 2024 کے" - focus on possession patterns
        suggestions.addAll([
          'سال $year کے داخلے',
          'سال $year کے تمام طلباء',
          'سال $year کے فعال طلباء',
        ]);
      } else if (month != null) {
        // Year + Month combinations
        suggestions.addAll([
          'مہینہ $month سال $year کے داخلے',
          'سال $year میں $month کے طلباء',
          '$month $year میں داخل ہونے والے',
        ]);
      } else if (day != null) {
        // Year + Day combinations
        suggestions.addAll([
          'تاریخ $day سال $year والے داخلے',
          'سال $year میں $day تاریخ کے طلباء',
          '$day/$year کے داخلے',
        ]);
      } else {
        // Basic year suggestions
        suggestions.addAll([
          'سال $year کے داخلے',
          'سال $year میں داخل ہونے والے طلبہ',
          'سال $year سے ${int.parse(year) + 1} تک کا داخلہ ریکارڈ',
        ]);
      }
    } else if (month != null) {
      // Month-only suggestions
      final currentYear = DateTime.now().year;
      suggestions.addAll([
        'مہینہ $month کے داخلے',
        'مہینہ $month سال $currentYear کے داخلے',
        '$month میں داخل ہونے والے طلباء',
      ]);
    } else if (query.contains('داخلہ') || query.contains('داخلے')) {
      // General admission suggestions
      final currentYear = DateTime.now().year;
      suggestions.addAll([
        'سال $currentYear کے داخلے',
        'حالیہ داخلے',
        'فعال طلباء کے داخلے',
      ]);
    } else {
      // Fallback suggestions
      final currentYear = DateTime.now().year;
      suggestions.addAll([
        'سال $currentYear کے داخلے',
        'سال ${currentYear - 1} کے داخلے',
        'حالیہ داخلے',
      ]);
    }
    
    return suggestions;
  }

  List<String> _generateEnglishDateSuggestions(String query, String? year, String? month, String? day) {
    final suggestions = <String>[];
    
    // Detect if user prefers "admitted" or "admission" terminology
    final usesAdmitted = query.toLowerCase().contains('admitted');
    final usesAdmission = query.toLowerCase().contains('admission');
    
    // Analyze user input patterns for dynamic suggestions
    if (year != null) {
      // Year-based suggestions
      if (query.contains('from') && !query.contains('to')) {
        // User typed "from 2024" - focus on range patterns
        if (usesAdmitted) {
          suggestions.addAll([
            'students admitted from $year to ${int.parse(year) + 1}',
            'admitted from $year to ${int.parse(year) + 5}',
            'students admitted from $year onwards',
          ]);
        } else {
          suggestions.addAll([
            'admissions from $year to ${int.parse(year) + 1}',
            'admission records from $year to ${int.parse(year) + 5}',
            'admissions from $year onwards',
          ]);
        }
      } else if (query.contains('in')) {
        // User typed "in 2024" - focus on specific year patterns
        if (usesAdmitted) {
          suggestions.addAll([
            'students admitted in $year',
            'admitted in $year',
            'all students admitted in $year',
          ]);
        } else {
          suggestions.addAll([
            'admissions in $year',
            'admission records in $year',
            'all admissions in $year',
          ]);
        }
      } else if (query.contains('between')) {
        // User typed "between" - focus on range patterns
        suggestions.addAll([
          'admitted between $year and ${int.parse(year) + 1}',
          'admissions between $year and ${int.parse(year) + 5}',
          'students admitted between $year and ${int.parse(year) + 2}',
        ]);
      } else if (month != null) {
        // Year + Month combinations
        if (usesAdmitted) {
          suggestions.addAll([
            'students admitted in $month $year',
            'admitted in $month $year',
            'all students admitted in $month $year',
          ]);
        } else {
          suggestions.addAll([
            '$month $year admissions',
            'admissions in $month $year',
            'admission records from $month $year',
          ]);
        }
      } else if (day != null) {
        // Year + Day combinations
        suggestions.addAll([
          'admissions on $day/$year',
          'students admitted on day $day of $year',
          '$day-$year admission records',
        ]);
      } else {
        // Basic year suggestions - match user's terminology
        if (usesAdmitted) {
          suggestions.addAll([
            'students admitted in $year',
            'admitted in $year',
            'students admitted from $year to ${int.parse(year) + 1}',
          ]);
        } else {
          suggestions.addAll([
            'admissions in $year',
            'admission records in $year',
            'admissions from $year to ${int.parse(year) + 1}',
          ]);
        }
      }
    } else if (month != null) {
      // Month-only suggestions
      final currentYear = DateTime.now().year;
      if (usesAdmitted) {
        suggestions.addAll([
          'students admitted in $month',
          'admitted in $month $currentYear',
          'students admitted in $month $currentYear',
        ]);
      } else {
        suggestions.addAll([
          '$month admissions',
          '$month $currentYear admissions',
          'admissions in $month',
        ]);
      }
    } else if (query.contains('admission') || query.contains('admitted')) {
      // General admission suggestions
      final currentYear = DateTime.now().year;
      if (usesAdmitted) {
        suggestions.addAll([
          'students admitted in $currentYear',
          'recently admitted students',
          'students admitted in ${currentYear - 1}',
        ]);
      } else {
        suggestions.addAll([
          'admissions in $currentYear',
          'recent admissions',
          'admissions in ${currentYear - 1}',
        ]);
      }
    } else {
      // Fallback suggestions
      final currentYear = DateTime.now().year;
      suggestions.addAll([
        'admissions in $currentYear',
        'admissions in ${currentYear - 1}',
        'recent admissions',
      ]);
    }
    
    return suggestions;
  }

  bool? _processIntelligentDateSearch(Map<String, dynamic> admission, String query) {
    // Use the new AdmissionSearchService for intelligent search
    if (!AdmissionSearchService.isAdmissionQuery(query)) {
      return null; // Not an admission query, use fallback search
    }
    
    final admissionDateValue = admission['admission_date'];
    if (admissionDateValue == null || admissionDateValue.toString() == 'none') {
      return false; // No admission date to search
    }
    
    DateTime? admissionDate;
    try {
      // Handle both DateTime objects and String dates
      if (admissionDateValue is DateTime) {
        admissionDate = admissionDateValue;
      } else if (admissionDateValue is String) {
        if (admissionDateValue.isEmpty) {
          return false;
        }
        admissionDate = DateTime.parse(admissionDateValue);
      } else {
        return false;
      }
    } catch (e) {
      return false; // Invalid date format
    }
    
    // Parse the query using the intelligent service
    final searchParams = AdmissionSearchService.parseQuery(query);
    if (searchParams == null) {
      return null; // Could not parse query
    }
    
    // Match based on search type
    switch (searchParams.searchType) {
      case AdmissionSearchType.exact:
        // Exact date match
        return admissionDate.year == searchParams.exactDate!.year &&
               admissionDate.month == searchParams.exactDate!.month &&
               admissionDate.day == searchParams.exactDate!.day;
      
      case AdmissionSearchType.year:
        // Year match
        return admissionDate.year == searchParams.year;
      
      case AdmissionSearchType.month:
        // Month + Year match
        return admissionDate.year == searchParams.year &&
               admissionDate.month == searchParams.month;
      
      case AdmissionSearchType.range:
        // Date range match
        return admissionDate.isAfter(searchParams.startDate!.subtract(Duration(days: 1))) &&
               admissionDate.isBefore(searchParams.endDate!.add(Duration(days: 1)));
    }
  }

  List<String> _generateIntelligentStruckOffSuggestions(String query, bool isUrdu) {
    // Use the new StruckOffSearchService for intelligent suggestions
    if (!StruckOffSearchService.isStruckOffQuery(query)) {
      return []; // Return empty if not struck-off query
    }
    
    return StruckOffSearchService.generateRecommendations(query, isUrdu);
  }

  bool? _processIntelligentStruckOffSearch(Map<String, dynamic> admission, String query) {
    // Use the new StruckOffSearchService for intelligent search
    if (!StruckOffSearchService.isStruckOffQuery(query)) {
      return null; // Not a struck-off query, use fallback search
    }
    
    final struckOffDateStr = admission['struck_off_date']?.toString();
    if (struckOffDateStr == null || struckOffDateStr.isEmpty || struckOffDateStr == 'none') {
      return false; // No struck-off date to search
    }
    
    DateTime? struckOffDate;
    try {
      // Handle both DateTime objects and String dates
      if (struckOffDateStr is DateTime) {
        struckOffDate = struckOffDateStr as DateTime;
      } else {
        struckOffDate = DateTime.parse(struckOffDateStr);
      }
    } catch (e) {
      return false; // Invalid date format
    }
    
    // Parse the query using the intelligent service
    final searchParams = StruckOffSearchService.parseQuery(query);
    if (searchParams == null) {
      return null; // Could not parse query
    }
    
    // Match based on search type
    switch (searchParams.searchType) {
      case StruckOffSearchType.exact:
        // Exact date match
        return struckOffDate.year == searchParams.exactDate!.year &&
               struckOffDate.month == searchParams.exactDate!.month &&
               struckOffDate.day == searchParams.exactDate!.day;
      
      case StruckOffSearchType.year:
        // Year match
        return struckOffDate.year == searchParams.year;
      
      case StruckOffSearchType.month:
        // Month + Year match
        return struckOffDate.year == searchParams.year &&
               struckOffDate.month == searchParams.month;
      
      case StruckOffSearchType.range:
        // Date range match
        return struckOffDate.isAfter(searchParams.startDate!.subtract(Duration(days: 1))) &&
               struckOffDate.isBefore(searchParams.endDate!.add(Duration(days: 1)));
    }
  }

  List<String> _generateIntelligentGraduationSuggestions(String query, bool isUrdu) {
    // Use the new GraduationSearchService for intelligent suggestions
    if (!GraduationSearchService.isGraduationQuery(query)) {
      return []; // Return empty if not graduation query
    }
    
    return GraduationSearchService.generateRecommendations(query, isUrdu);
  }


  bool? _processIntelligentGraduationSearch(Map<String, dynamic> admission, String query) {
    // Use the new GraduationSearchService for intelligent search
    if (!GraduationSearchService.isGraduationQuery(query)) {
      return null; // Not a graduation query, use fallback search
    }
    
    final graduationDateStr = admission['graduation_date']?.toString();
    if (graduationDateStr == null || graduationDateStr.isEmpty || graduationDateStr == 'none') {
      return false; // No graduation date to search
    }
    
    DateTime? graduationDate;
    try {
      // Handle both DateTime objects and String dates
      if (graduationDateStr is DateTime) {
        graduationDate = graduationDateStr as DateTime;
      } else {
        graduationDate = DateTime.parse(graduationDateStr);
      }
    } catch (e) {
      return false; // Invalid date format
    }
    
    // Parse the query using the intelligent service
    final searchParams = GraduationSearchService.parseQuery(query);
    if (searchParams == null) {
      return null; // Could not parse query
    }
    
    // Match based on search type
    switch (searchParams.searchType) {
      case GraduationSearchType.exact:
        // Exact date match
        return graduationDate.year == searchParams.exactDate!.year &&
               graduationDate.month == searchParams.exactDate!.month &&
               graduationDate.day == searchParams.exactDate!.day;
      
      case GraduationSearchType.year:
        // Year match
        return graduationDate.year == searchParams.year;
      
      case GraduationSearchType.range:
        // Date range match
        return graduationDate.isAfter(searchParams.startDate!.subtract(Duration(days: 1))) &&
               graduationDate.isBefore(searchParams.endDate!.add(Duration(days: 1)));
    }
  }

  List<String> _generateIntelligentClassSuggestions(String query, bool isUrdu) {
    final suggestions = <String>[];
    
    // Detect class search patterns
    final isClassQuery = _isClassSearchQuery(query);
    
    if (!isClassQuery) {
      return suggestions; // Return empty if not class query
    }
    
    // Extract multiple classes: "class a, b and c", "class w, 1st, nazira"
    List<String> extractedClasses = [];
    
    // Remove "class" or "جماعت" prefix for easier parsing
    String classContent = query;
    if (query.toLowerCase().contains('class')) {
      classContent = query.toLowerCase().replaceFirst(RegExp(r'class\s*'), '');
    } else if (query.contains('جماعت')) {
      classContent = query.replaceFirst(RegExp(r'جماعت\s*'), '');
    }
    
    // Parse multiple classes with commas and "and"/"اور"
    // Split by comma first, then by "and"/"اور"
    final parts = classContent.split(RegExp(r'[,،]'));
    for (final part in parts) {
      // Further split by "and" or "اور"
      final subParts = part.split(RegExp(r'\s+(?:and|اور)\s+'));
      for (final subPart in subParts) {
        final trimmed = subPart.trim();
        // Extract class names (letters, numbers, or words like "nazira", "tarjuma", "1st")
        final classMatch = RegExp(r'([A-Za-z0-9]+(?:st|nd|rd|th)?|nazira|tarjuma|نظیرہ|ترجمہ)', caseSensitive: false).firstMatch(trimmed);
        if (classMatch != null) {
          extractedClasses.add(classMatch.group(0)!.toUpperCase());
        }
      }
    }
    
    // Remove duplicates
    extractedClasses = extractedClasses.toSet().toList();
    
    // Check for status keywords
    final hasActiveStatus = query.contains('فعال') || query.toLowerCase().contains('active');
    final hasStruckOffStatus = query.contains('اخراج') || query.contains('خارج') || query.toLowerCase().contains('struck');
    final hasGraduateStatus = query.contains('فارغ') || query.contains('گریجویٹ') || query.toLowerCase().contains('grad');
    
    // Analyze what user has typed for dynamic suggestions
    if (isUrdu) {
      suggestions.addAll(_generateUrduClassSuggestions(query, extractedClasses, hasActiveStatus, hasStruckOffStatus, hasGraduateStatus));
    } else {
      suggestions.addAll(_generateEnglishClassSuggestions(query, extractedClasses, hasActiveStatus, hasStruckOffStatus, hasGraduateStatus));
    }
    
    // Ensure exactly 3 unique suggestions
    final uniqueSuggestions = suggestions.toSet().toList();
    return uniqueSuggestions.take(3).toList();
  }

  bool _isClassSearchQuery(String query) {
    // Check for class keywords (including partial matches for better UX)
    final urduClassKeywords = ['جماعت', 'کلاس', 'والے طلبہ', 'کے طلبہ', 'کے فعال', 'کے اخراج', 'کے فارغ'];
    final englishClassKeywords = ['class', 'students', 'grade'];
    
    // Check for partial class keyword typing (e.g., "clas", "cl", "stud")
    final lowerQuery = query.toLowerCase();
    final hasPartialClass = lowerQuery.startsWith('clas') || 
                           lowerQuery.startsWith('cl') && lowerQuery.length <= 5 ||
                           lowerQuery.contains('جما') ||
                           lowerQuery.contains('کلا');
    
    // Check for class letters/numbers
    final hasClassLetter = RegExp(r'[A-Za-z]\s*(?:جماعت|class|والے|کے)|(?:جماعت|class)\s*[A-Za-z]').hasMatch(query);
    
    // Check for class-related keywords
    final hasUrduKeywords = urduClassKeywords.any((keyword) => query.contains(keyword));
    final hasEnglishKeywords = englishClassKeywords.any((keyword) => lowerQuery.contains(keyword));
    
    final result = hasClassLetter || hasUrduKeywords || hasEnglishKeywords || hasPartialClass;
    
    // Debug output
    if (result) {
      print('Class query detected: "$query" - ClassLetter: $hasClassLetter, UrduKeywords: $hasUrduKeywords, EnglishKeywords: $hasEnglishKeywords');
    }
    
    return result;
  }

  List<String> _generateUrduClassSuggestions(String query, List<String> classNames, bool hasActive, bool hasStruckOff, bool hasGraduate) {
    final suggestions = <String>[];
    
    // Handle multiple classes
    if (classNames.length >= 2) {
      // Build dynamic class list string based on user's input pattern
      String classList;
      if (query.contains(',') || query.contains('،')) {
        // User is using commas, suggest with commas
        classList = classNames.take(3).join('، ');
      } else {
        // User is using "and", suggest with "and"
        if (classNames.length == 2) {
          classList = '${classNames[0]} اور ${classNames[1]}';
        } else {
          classList = '${classNames.take(classNames.length - 1).join('، ')} اور ${classNames.last}';
        }
      }
      
      suggestions.addAll([
        'جماعت $classList والے طلبہ',
        'جماعت $classList کے فعال طلبہ',
        'جماعت $classList کے تمام طلبہ',
      ]);
      return suggestions;
    }
    
    // Single class suggestions
    final className = classNames.isNotEmpty ? classNames.first : null;
    if (className != null) {
      // Analyze user input patterns for dynamic suggestions
      if (query.contains('ف') && !hasActive && !hasStruckOff && !hasGraduate) {
        // User typed "جماعت A ف" - focus on status patterns starting with ف
        suggestions.addAll([
          'جماعت $className کے فعال طلبہ',
          'جماعت $className کے فارغ طلبہ',
          'جماعت $className کی فیس باقی والے طلبہ',
        ]);
      } else if (query.contains('ا') && !hasActive && !hasStruckOff) {
        // User typed "جماعت A ا" - focus on patterns starting with ا
        suggestions.addAll([
          'جماعت $className کے اخراج شدہ طلبہ',
          'جماعت $className اور B والے طلبہ',
          'جماعت $className کے تمام طلبہ',
        ]);
      } else if (query.contains('کے')) {
        // User typed "جماعت A کے" - focus on possession patterns
        suggestions.addAll([
          'جماعت $className کے فعال طلبہ',
          'جماعت $className کے اخراج شدہ طلبہ',
          'جماعت $className کے فارغ طلبہ',
        ]);
      } else if (hasActive) {
        // User mentioned active status
        suggestions.addAll([
          'جماعت $className کے فعال طلبہ',
          'جماعت $className کے فعال اور باقی فیس والے طلبہ',
          'جماعت $className کے تمام فعال طلبہ',
        ]);
      } else if (hasStruckOff) {
        // User mentioned struck-off status
        suggestions.addAll([
          'جماعت $className کے اخراج شدہ طلبہ',
          'جماعت $className کے خارج شدہ طلبہ',
          'جماعت $className کے تمام اخراج شدہ طلبہ',
        ]);
      } else if (hasGraduate) {
        // User mentioned graduate status
        suggestions.addAll([
          'جماعت $className کے فارغ طلبہ',
          'جماعت $className کے فارغ التحصیل طلبہ',
          'جماعت $className کے گریجویٹ طلبہ',
        ]);
      } else {
        // Basic class suggestions
        suggestions.addAll([
          'جماعت $className والے طلبہ',
          'جماعت $className کے فعال طلبہ',
          'جماعت $className اور B والے طلبہ',
        ]);
      }
    } else {
      // General class suggestions when no specific class detected
      suggestions.addAll([
        'جماعت A والے طلبہ',
        'جماعت B کے فعال طلبہ',
        'تمام جماعات کے طلبہ',
      ]);
    }
    
    return suggestions;
  }

  List<String> _generateEnglishClassSuggestions(String query, List<String> classNames, bool hasActive, bool hasStruckOff, bool hasGraduate) {
    final suggestions = <String>[];
    
    // Handle multiple classes
    if (classNames.length >= 2) {
      // Build dynamic class list string based on user's input pattern
      String classList;
      if (query.contains(',')) {
        // User is using commas, suggest with commas
        classList = classNames.take(3).join(', ');
      } else {
        // User is using "and", suggest with "and"
        if (classNames.length == 2) {
          classList = '${classNames[0]} and ${classNames[1]}';
        } else {
          classList = '${classNames.take(classNames.length - 1).join(', ')} and ${classNames.last}';
        }
      }
      
      suggestions.addAll([
        'class $classList students',
        'students from class $classList',
        'class $classList active students',
      ]);
      return suggestions;
    }
    
    // Single class suggestions
    final className = classNames.isNotEmpty ? classNames.first : null;
    if (className != null) {
      // Analyze user input patterns for dynamic suggestions
      if (query.toLowerCase().contains('class $className'.toLowerCase()) && query.toLowerCase().contains('a')) {
        // User typed "class A a" - focus on active patterns
        suggestions.addAll([
          'class $className active students',
          'class $className all students',
          'class $className and B students',
        ]);
      } else if (hasActive) {
        // User mentioned active status
        suggestions.addAll([
          'class $className active students',
          'active students from class $className',
          'class $className active with pending fees',
        ]);
      } else if (hasStruckOff) {
        // User mentioned struck-off status
        suggestions.addAll([
          'class $className struck off students',
          'struck off students from class $className',
          'class $className expelled students',
        ]);
      } else if (hasGraduate) {
        // User mentioned graduate status
        suggestions.addAll([
          'class $className graduated students',
          'graduated students from class $className',
          'class $className graduates',
        ]);
      } else {
        // Basic class suggestions
        suggestions.addAll([
          'class $className students',
          'class $className active students',
          'class $className and B students',
        ]);
      }
    } else {
      // General class suggestions when no specific class detected
      suggestions.addAll([
        'class A students',
        'class B active students',
        'all class students',
      ]);
    }
    
    return suggestions;
  }

  bool? _processIntelligentClassSearch(Map<String, dynamic> admission, String query) {
    // Check if this is a class search query
    if (!_isClassSearchQuery(query)) {
      return null; // Not a class query, use fallback search
    }
    
    final studentClass = admission['class']?.toString().toLowerCase() ?? '';
    if (studentClass.isEmpty || studentClass == 'none') {
      return false; // No class to search
    }
    
    // Extract multiple classes: "class a, b and c", "class w, 1st, nazira"
    List<String> extractedClasses = [];
    
    // Remove "class" or "جماعت" prefix for easier parsing
    String classContent = query;
    if (query.toLowerCase().contains('class')) {
      classContent = query.toLowerCase().replaceFirst(RegExp(r'class\s*'), '');
    } else if (query.contains('جماعت')) {
      classContent = query.replaceFirst(RegExp(r'جماعت\s*'), '');
    }
    
    // Parse multiple classes with commas and "and"/"اور"
    final parts = classContent.split(RegExp(r'[,،]'));
    for (final part in parts) {
      // Further split by "and" or "اور"
      final subParts = part.split(RegExp(r'\s+(?:and|اور)\s+'));
      for (final subPart in subParts) {
        final trimmed = subPart.trim();
        // Extract class names (letters, numbers, or words like "nazira", "tarjuma", "1st")
        final classMatch = RegExp(r'([A-Za-z0-9]+(?:st|nd|rd|th)?|nazira|tarjuma|نظیرہ|ترجمہ)', caseSensitive: false).firstMatch(trimmed);
        if (classMatch != null) {
          extractedClasses.add(classMatch.group(0)!.toLowerCase());
        }
      }
    }
    
    // Remove duplicates
    extractedClasses = extractedClasses.toSet().toList();
    
    // Debug class matching
    print('Class search debug - studentClass: "$studentClass", extractedClasses: $extractedClasses, query: "$query"');
    
    // Pattern 1: Multiple classes - check if student class matches any
    if (extractedClasses.isNotEmpty) {
      final matchesClass = extractedClasses.contains(studentClass);
      
      // Check for additional status filters
      if (matchesClass) {
        return _checkStatusFilter(admission, query);
      }
      return matchesClass;
    }
    
    // Pattern 2: Fallback - no classes extracted, check for general class query
    if (query.contains('جماعت') || query.toLowerCase().contains('class')) {
      // Check for status filters only
      return _checkStatusFilter(admission, query);
    }
    
    return null; // No valid class pattern found
  }

  bool _checkStatusFilter(Map<String, dynamic> admission, String query) {
    final status = admission['status']?.toString().toLowerCase() ?? '';
    
    // Check for active status filter
    if (query.contains('فعال') || query.toLowerCase().contains('active')) {
      return status == 'active';
    }
    
    // Check for struck-off status filter
    if (query.contains('اخراج') || query.contains('خارج') || query.toLowerCase().contains('struck')) {
      return status == 'struck off';
    }
    
    // Check for graduate status filter
    if (query.contains('فارغ') || query.contains('گریجویٹ') || query.toLowerCase().contains('grad')) {
      return status == 'graduate';
    }
    
    // Check for fee-related filters
    if (query.contains('فیس باقی') || query.toLowerCase().contains('pending fee')) {
      // This would require fee status checking - for now return true if class matches
      return true;
    }
    
    // No specific status filter, return true (class match is sufficient)
    return true;
  }

  List<String> _generateIntelligentFeeSuggestions(String query, bool isUrdu) {
    final suggestions = <String>[];
    
    // Detect fee search patterns
    final isFeeQuery = _isFeeSearchQuery(query);
    
    if (!isFeeQuery) {
      return suggestions; // Return empty if not fee query
    }
    
    // Extract fee amount information
    final amountMatch = RegExp(r'\d+').firstMatch(query);
    final extractedAmount = amountMatch?.group(0);
    
    // Check for comparison operators
    final hasGreaterThan = query.contains('سے زیادہ') || query.contains('سے اوپر') || 
                          query.toLowerCase().contains('greater than') || 
                          query.toLowerCase().contains('more than') ||
                          query.contains('>');
    
    final hasLessThan = query.contains('سے کم') || query.contains('سے نیچے') || 
                       query.toLowerCase().contains('less than') || 
                       query.toLowerCase().contains('below') ||
                       query.contains('<');
    
    final hasWithFee = query.contains('فیس والے') || query.contains('فیس والا') ||
                      query.toLowerCase().contains('with fee') ||
                      query.toLowerCase().contains('fee wale');
    
    final hasWithoutFee = query.contains('بغیر فیس') || query.contains('فیس نہیں') ||
                         query.toLowerCase().contains('without fee') ||
                         query.toLowerCase().contains('no fee');
    
    // Analyze what user has typed for dynamic suggestions
    if (isUrdu) {
      suggestions.addAll(_generateUrduFeeSuggestions(query, extractedAmount, hasGreaterThan, hasLessThan, hasWithFee, hasWithoutFee));
    } else {
      suggestions.addAll(_generateEnglishFeeSuggestions(query, extractedAmount, hasGreaterThan, hasLessThan, hasWithFee, hasWithoutFee));
    }
    
    // Ensure exactly 3 unique suggestions
    final uniqueSuggestions = suggestions.toSet().toList();
    return uniqueSuggestions.take(3).toList();
  }

  bool _isFeeSearchQuery(String query) {
    // Check for fee keywords
    final urduFeeKeywords = ['فیس', 'فیس والے', 'بغیر فیس', 'فیس نہیں', 'سے زیادہ', 'سے کم'];
    final englishFeeKeywords = ['fee', 'fees', 'with fee', 'without fee', 'no fee', 'greater than', 'less than'];
    
    // Check for fee-related keywords
    final hasUrduKeywords = urduFeeKeywords.any((keyword) => query.contains(keyword));
    final hasEnglishKeywords = englishFeeKeywords.any((keyword) => query.toLowerCase().contains(keyword));
    
    // Check for fee with numbers
    final hasFeeWithNumber = RegExp(r'(?:فیس|fee)\s*\d+|(?:\d+)\s*(?:فیس|fee)').hasMatch(query);
    
    final result = hasUrduKeywords || hasEnglishKeywords || hasFeeWithNumber;
    
    // Debug output
    if (result) {
      print('Fee query detected: "$query" - UrduKeywords: $hasUrduKeywords, EnglishKeywords: $hasEnglishKeywords, FeeWithNumber: $hasFeeWithNumber');
    }
    
    return result;
  }

  List<String> _generateUrduFeeSuggestions(String query, String? amount, bool hasGreater, bool hasLess, bool hasWithFee, bool hasWithoutFee) {
    final suggestions = <String>[];
    
    // Analyze user input patterns for dynamic suggestions
    if (amount != null) {
      if (hasGreater) {
        // User typed "فیس 200 سے زیادہ" - focus on greater than patterns
        suggestions.addAll([
          'فیس $amount سے زیادہ والے طلبہ',
          'فیس $amount سے زیادہ کا ریکارڈ',
          'فیس $amount سے اوپر والے طلبہ کی فہرست',
        ]);
      } else if (hasLess) {
        // User typed "فیس 500 سے کم" - focus on less than patterns
        suggestions.addAll([
          'فیس $amount سے کم والے طلبہ',
          'فیس $amount سے کم کا ریکارڈ',
          'فیس $amount سے نیچے والے طلبہ کی فہرست',
        ]);
      } else if (query.contains('سے') && !hasGreater && !hasLess) {
        // User typed "فیس 200 سے" - focus on comparison patterns
        suggestions.addAll([
          'فیس $amount سے زیادہ والے طلبہ',
          'فیس $amount سے کم والے طلبہ',
          'فیس $amount سے برابر والے طلبہ',
        ]);
      } else {
        // Basic amount suggestions
        suggestions.addAll([
          'فیس $amount والے طلبہ',
          'فیس $amount سے زیادہ والے طلبہ',
          'فیس $amount سے کم والے طلبہ',
        ]);
      }
    } else if (hasWithFee) {
      // User mentioned "فیس والے"
      suggestions.addAll([
        'فیس والے طلبہ کا ریکارڈ',
        'فیس والے تمام طلبہ',
        'فیس والے فعال طلبہ',
      ]);
    } else if (hasWithoutFee) {
      // User mentioned "بغیر فیس"
      suggestions.addAll([
        'بغیر فیس والے طلبہ کا ریکارڈ',
        'بغیر فیس والے تمام طلبہ',
        'فیس نہیں والے طلبہ کی فہرست',
      ]);
    } else if (query.contains('فیس و')) {
      // User typed "فیس و" - focus on "والے" patterns
      suggestions.addAll([
        'فیس والے طلبہ',
        'فیس والے طلبہ کا ریکارڈ',
        'فیس والے فعال طلبہ',
      ]);
    } else if (query.contains('بغیر')) {
      // User typed "بغیر" - focus on without fee patterns
      suggestions.addAll([
        'بغیر فیس والے طلبہ',
        'بغیر فیس والے طلبہ کا ریکارڈ',
        'بغیر فیس والے فعال طلبہ',
      ]);
    } else {
      // General fee suggestions
      suggestions.addAll([
        'فیس والے طلبہ',
        'بغیر فیس والے طلبہ',
        'فیس 500 سے زیادہ والے طلبہ',
      ]);
    }
    
    return suggestions;
  }

  List<String> _generateEnglishFeeSuggestions(String query, String? amount, bool hasGreater, bool hasLess, bool hasWithFee, bool hasWithoutFee) {
    final suggestions = <String>[];
    
    // Analyze user input patterns for dynamic suggestions
    if (amount != null) {
      if (hasGreater) {
        // User typed "fee greater than 200" - focus on greater than patterns
        suggestions.addAll([
          'students with fee greater than $amount',
          'fee greater than $amount records',
          'all students with fee above $amount',
        ]);
      } else if (hasLess) {
        // User typed "fee less than 500" - focus on less than patterns
        suggestions.addAll([
          'students with fee less than $amount',
          'fee less than $amount records',
          'all students with fee below $amount',
        ]);
      } else if (query.toLowerCase().contains('than') && !hasGreater && !hasLess) {
        // User typed "fee 200 than" - focus on comparison patterns
        suggestions.addAll([
          'fee greater than $amount',
          'fee less than $amount',
          'students with fee $amount',
        ]);
      } else {
        // Basic amount suggestions
        suggestions.addAll([
          'students with fee $amount',
          'fee greater than $amount',
          'fee less than $amount',
        ]);
      }
    } else if (hasWithFee) {
      // User mentioned "with fee"
      suggestions.addAll([
        'students with fee records',
        'all students with fee',
        'active students with fee',
      ]);
    } else if (hasWithoutFee) {
      // User mentioned "without fee"
      suggestions.addAll([
        'students without fee records',
        'all students without fee',
        'students with no fee',
      ]);
    } else if (query.toLowerCase().contains('fee w')) {
      // User typed "fee w" - focus on "with" patterns
      suggestions.addAll([
        'students with fee',
        'students with fee records',
        'students without fee',
      ]);
    } else {
      // General fee suggestions
      suggestions.addAll([
        'students with fee',
        'students without fee',
        'fee greater than 500',
      ]);
    }
    
    return suggestions;
  }

  bool? _processIntelligentFeeSearch(Map<String, dynamic> admission, String query) {
    // Check if this is a fee search query
    if (!_isFeeSearchQuery(query)) {
      return null; // Not a fee query, use fallback search
    }
    
    final feeStr = admission['fee']?.toString() ?? '0';
    final fee = double.tryParse(feeStr) ?? 0.0;
    
    // Extract multiple amounts: "fee 200 and 500", "fee 100,200,300"
    List<double> extractedAmounts = [];
    final amountMatches = RegExp(r'\d+').allMatches(query);
    for (final match in amountMatches) {
      final amount = double.tryParse(match.group(0)!);
      if (amount != null) {
        extractedAmounts.add(amount);
      }
    }
    
    // Debug fee matching
    print('Fee search debug - fee: $fee, extractedAmounts: $extractedAmounts, query: "$query"');
    
    // Pattern 1: "فیس والے طلبہ" or "students with fee" - students with fee > 0
    if ((query.contains('فیس والے') || query.toLowerCase().contains('with fee')) && 
        !query.contains('بغیر') && !query.toLowerCase().contains('without')) {
      return fee > 0;
    }
    
    // Pattern 2: "بغیر فیس والے طلبہ" or "students without fee" - students with fee = 0
    if (query.contains('بغیر فیس') || query.contains('فیس نہیں') || 
        query.toLowerCase().contains('without fee') || query.toLowerCase().contains('no fee')) {
      return fee == 0;
    }
    
    // Pattern 3: Multiple specific amounts: "fee 200 and 500", "fee 100,200,300"
    if (extractedAmounts.length >= 2 && 
        (query.contains(',') || query.contains('،') || 
         (query.toLowerCase().contains('and') && !query.toLowerCase().contains('between')))) {
      return extractedAmounts.contains(fee);
    }
    
    // Pattern 4: Fee range with comprehensive Urdu support
    // Urdu: "سے ... تک", "درمیان ... اور"
    // English: "from ... to", "between ... and"
    if (extractedAmounts.length >= 2 &&
        ((query.contains('سے') && query.contains('تک')) || 
         (query.contains('درمیان') && query.contains('اور')) ||
         (query.contains('from') && query.contains('to')) ||
         (query.contains('between') && query.contains('and')))) {
      final minFee = extractedAmounts.first;
      final maxFee = extractedAmounts.last;
      return fee >= minFee && fee <= maxFee;
    }
    
    // Pattern 5: Greater than with comprehensive Urdu support
    // Urdu: "سے زیادہ", "سے بڑا", "سے اوپر", "سے آگے"
    // English: "greater than", "more than", "above", ">"
    if (extractedAmounts.isNotEmpty) {
      final targetAmount = extractedAmounts.first;
      
      if (query.contains('سے زیادہ') || 
          query.contains('سے بڑا') ||
          query.contains('سے اوپر') || 
          query.contains('سے آگے') ||
          query.toLowerCase().contains('greater than') || 
          query.toLowerCase().contains('more than') ||
          query.toLowerCase().contains('above') ||
          query.contains('>')) {
        return fee > targetAmount;
      }
      
      // Pattern 6: Less than with comprehensive Urdu support
      // Urdu: "سے کم", "سے چھوٹا", "سے نیچے", "سے پیچھے"
      // English: "less than", "below", "under", "<"
      if (query.contains('سے کم') || 
          query.contains('سے چھوٹا') ||
          query.contains('سے نیچے') || 
          query.contains('سے پیچھے') ||
          query.toLowerCase().contains('less than') || 
          query.toLowerCase().contains('below') ||
          query.toLowerCase().contains('under') ||
          query.contains('<')) {
        return fee < targetAmount;
      }
      
      // Pattern 7: "فیس 300" or "fee 300" - exact fee match
      return fee == targetAmount;
    }
    
    // Pattern 8: General fee search without specific criteria
    if (query.contains('فیس') || query.toLowerCase().contains('fee')) {
      // Return true for any record with fee information
      return true;
    }
    
    return null; // No valid fee pattern found
  }

  List<String> _generateIntelligentStatusSuggestions(String query, bool isUrdu) {
    final suggestions = <String>[];
    
    // Detect status search patterns
    final isStatusQuery = _isStatusSearchQuery(query);
    
    if (!isStatusQuery) {
      return suggestions; // Return empty if not status query
    }
    
    // Detect which status is being searched
    final hasActive = query.contains('فعال') || query.toLowerCase().contains('active');
    final hasStruckOff = query.contains('اخراج') || query.contains('خارج') || query.toLowerCase().contains('struck');
    final hasGraduate = query.contains('فارغ') || query.contains('گریجویٹ') || query.toLowerCase().contains('grad');
    
    // Analyze what user has typed for dynamic suggestions
    if (isUrdu) {
      suggestions.addAll(_generateUrduStatusSuggestions(query, hasActive, hasStruckOff, hasGraduate));
    } else {
      suggestions.addAll(_generateEnglishStatusSuggestions(query, hasActive, hasStruckOff, hasGraduate));
    }
    
    // Ensure exactly 3 unique suggestions
    final uniqueSuggestions = suggestions.toSet().toList();
    return uniqueSuggestions.take(3).toList();
  }

  bool _isStatusSearchQuery(String query) {
    // Check for status keywords
    final urduStatusKeywords = ['فعال', 'اخراج', 'خارج', 'فارغ', 'گریجویٹ', 'حیثیت', 'طلباء', 'طلبہ'];
    final englishStatusKeywords = ['active', 'struck', 'expelled', 'graduate', 'graduated', 'status', 'students'];
    
    // Check for status-related keywords
    final hasUrduKeywords = urduStatusKeywords.any((keyword) => query.contains(keyword));
    final hasEnglishKeywords = englishStatusKeywords.any((keyword) => query.toLowerCase().contains(keyword));
    
    // Exclude if it's clearly another type of query
    final isOtherQuery = RegExp(r'20\d{2}').hasMatch(query) || // Has year
                         query.contains('فیس') || query.toLowerCase().contains('fee') || // Fee query
                         query.contains('جماعت') || query.toLowerCase().contains('class') || // Class query
                         query.contains('آئی ڈی') || query.toLowerCase().contains('id'); // ID query
    
    return (hasUrduKeywords || hasEnglishKeywords) && !isOtherQuery;
  }

  List<String> _generateUrduStatusSuggestions(String query, bool hasActive, bool hasStruckOff, bool hasGraduate) {
    final suggestions = <String>[];
    
    if (hasActive) {
      suggestions.addAll([
        'فعال طلباء',
        'فعال طلباء کی فہرست',
        'تمام فعال طلبہ',
      ]);
    } else if (hasStruckOff) {
      suggestions.addAll([
        'اخراج شدہ طلباء',
        'خارج شدہ طلباء کی فہرست',
        'تمام اخراج شدہ طلبہ',
      ]);
    } else if (hasGraduate) {
      suggestions.addAll([
        'فارغ التحصیل طلباء',
        'گریجویٹ طلباء کی فہرست',
        'تمام فارغ طلبہ',
      ]);
    } else {
      // General status suggestions
      suggestions.addAll([
        'فعال طلباء',
        'اخراج شدہ طلباء',
        'فارغ التحصیل طلباء',
      ]);
    }
    
    return suggestions;
  }

  List<String> _generateEnglishStatusSuggestions(String query, bool hasActive, bool hasStruckOff, bool hasGraduate) {
    final suggestions = <String>[];
    
    if (hasActive) {
      suggestions.addAll([
        'active students',
        'list of active students',
        'all active students',
      ]);
    } else if (hasStruckOff) {
      suggestions.addAll([
        'struck off students',
        'list of expelled students',
        'all struck off students',
      ]);
    } else if (hasGraduate) {
      suggestions.addAll([
        'graduated students',
        'list of graduates',
        'all graduated students',
      ]);
    } else {
      // General status suggestions
      suggestions.addAll([
        'active students',
        'struck off students',
        'graduated students',
      ]);
    }
    
    return suggestions;
  }

  bool? _processIntelligentStatusSearch(Map<String, dynamic> admission, String query) {
    // Check if this is a status search query
    if (!_isStatusSearchQuery(query)) {
      return null; // Not a status query, use fallback search
    }
    
    final status = admission['status']?.toString().toLowerCase() ?? '';
    
    // Debug status matching
    print('Status search debug - status: "$status", query: "$query"');
    
    // Pattern 1: Active status
    if (query.contains('فعال') || query.toLowerCase().contains('active')) {
      return status == 'active';
    }
    
    // Pattern 2: Struck off status
    if (query.contains('اخراج') || query.contains('خارج') || 
        query.toLowerCase().contains('struck') || query.toLowerCase().contains('expelled')) {
      return status == 'struck off';
    }
    
    // Pattern 3: Graduate status
    if (query.contains('فارغ') || query.contains('گریجویٹ') || 
        query.toLowerCase().contains('graduate') || query.toLowerCase().contains('grad')) {
      return status == 'graduate';
    }
    
    // Pattern 4: General status query - show all
    return true;
  }

  List<String> _generateIntelligentNameSuggestions(String query, bool isUrdu) {
    final suggestions = <String>[];
    
    // Detect name search patterns
    final isNameQuery = _isNameSearchQuery(query);
    
    if (!isNameQuery) {
      return suggestions; // Return empty if not name query
    }
    
    // Clean the query for name processing
    final cleanQuery = query.trim();
    
    // Check if it's a single letter or very short input
    final isSingleLetter = cleanQuery.length == 1;
    final isShortInput = cleanQuery.length <= 3;
    
    // Check for mixed content (name + other elements)
    final hasMixedContent = RegExp(r'\d+|سال|class|جماعت|فیس|fee').hasMatch(query);
    
    // Analyze what user has typed for dynamic suggestions
    if (isUrdu) {
      suggestions.addAll(_generateUrduNameSuggestions(cleanQuery, isSingleLetter, isShortInput, hasMixedContent));
    } else {
      suggestions.addAll(_generateEnglishNameSuggestions(cleanQuery, isSingleLetter, isShortInput, hasMixedContent));
    }
    
    // Ensure exactly 3 unique suggestions
    final uniqueSuggestions = suggestions.toSet().toList();
    return uniqueSuggestions.take(3).toList();
  }

  bool _isNameSearchQuery(String query) {
    final cleanQuery = query.trim();
    
    // If query is empty, not a name query
    if (cleanQuery.isEmpty) return false;
    
    // Check if query contains specific non-name keywords that should take priority
    final nonNameKeywords = [
      'آئی ڈی', 'id', 'سال', 'year', 'مہینہ', 'month', 'تاریخ', 'date',
      'اخراج', 'خارج', 'struck', 'فراغت', 'فارغ', 'grad', 'جماعت', 'class',
      'فیس', 'fee', 'سے زیادہ', 'سے کم', 'greater', 'less', 'والے طلبہ',
      'admitted', 'admission', 'admissions', 'داخلہ', 'داخلے', 'میں داخل'
    ];
    
    // If query contains non-name keywords, it's likely not primarily a name search
    final hasNonNameKeywords = nonNameKeywords.any((keyword) => 
      cleanQuery.toLowerCase().contains(keyword.toLowerCase()));
    
    if (hasNonNameKeywords) {
      // Exception: if it's a mixed query like "Ali 2024", still treat as name if name part is dominant
      final namePattern = RegExp(r'^[a-zA-Zآ-ی\s]+');
      final nameMatch = namePattern.firstMatch(cleanQuery);
      if (nameMatch != null && nameMatch.group(0)!.trim().length >= 2) {
        return true; // Name part is significant enough
      }
      return false;
    }
    
    // Check if it looks like a name (contains letters, possibly with spaces)
    final namePattern = RegExp(r'^[a-zA-Zآ-ی\s]+$');
    final isNameLike = namePattern.hasMatch(cleanQuery);
    
    // Single letters or very short inputs are considered name searches
    if (cleanQuery.length <= 3) return true;
    
    // Longer inputs that look like names
    return isNameLike;
  }

  List<String> _generateUrduNameSuggestions(String query, bool isSingleLetter, bool isShortInput, bool hasMixedContent) {
    final suggestions = <String>[];
    
    if (isSingleLetter) {
      // Single letter suggestions like "A", "ع"
      suggestions.addAll([
        '$query سے شروع ہونے والے طلبہ',
        '$query نام والے طلبہ کا ریکارڈ',
        '$query کے مشابہ نام والے طلبہ',
      ]);
    } else if (isShortInput) {
      // Short input suggestions like "AL", "فی"
      suggestions.addAll([
        '$query سے شروع ہونے والے نام',
        '$query والے طلبہ کا ریکارڈ',
        '$query کے مشابہ نام والے طلبہ',
      ]);
    } else if (hasMixedContent) {
      // Mixed content like "Ali 2024"
      final namePart = RegExp(r'^[a-zA-Zآ-ی\s]+').firstMatch(query)?.group(0)?.trim() ?? query;
      suggestions.addAll([
        '$namePart نام والے طلبہ',
        '$namePart کے نام سے ملتے جلتے طلبہ',
        '$namePart جیسے نام والے طلبہ کا ریکارڈ',
      ]);
    } else {
      // Full name suggestions like "علی", "احمد رضا"
      if (query.contains(' ')) {
        // Full name with spaces
        suggestions.addAll([
          '$query نام والے طلبہ',
          '$query کے نام سے ملتے جلتے طلبہ',
          '$query جیسے مکمل نام والے طلبہ',
        ]);
      } else {
        // Single name word
        suggestions.addAll([
          '$query نام والے طلبہ',
          '$query خان جیسے نام والے طلبہ',
          '$query کے نام سے ملتے جلتے طلبہ',
        ]);
      }
    }
    
    return suggestions;
  }

  List<String> _generateEnglishNameSuggestions(String query, bool isSingleLetter, bool isShortInput, bool hasMixedContent) {
    final suggestions = <String>[];
    
    if (isSingleLetter) {
      // Single letter suggestions like "A", "H"
      suggestions.addAll([
        'students with names starting with $query',
        'all $query names records',
        'students with $query similar names',
      ]);
    } else if (isShortInput) {
      // Short input suggestions like "AL", "HAS"
      suggestions.addAll([
        'names starting with $query',
        'students with $query names',
        '$query similar name records',
      ]);
    } else if (hasMixedContent) {
      // Mixed content like "Hassan 2024"
      final namePart = RegExp(r'^[a-zA-Z\s]+').firstMatch(query)?.group(0)?.trim() ?? query;
      suggestions.addAll([
        'students named $namePart',
        '$namePart name records',
        'students with $namePart similar names',
      ]);
    } else {
      // Full name suggestions like "Hassan", "Ahmad Raza"
      if (query.contains(' ')) {
        // Full name with spaces
        suggestions.addAll([
          'students named $query',
          '$query exact name matches',
          'students with $query similar names',
        ]);
      } else {
        // Single name word
        suggestions.addAll([
          'students named $query',
          '$query Ali type names',
          'students with $query similar names',
        ]);
      }
    }
    
    return suggestions;
  }

  bool? _processIntelligentNameSearch(Map<String, dynamic> admission, String query) {
    // Check if this is a name search query
    if (!_isNameSearchQuery(query)) {
      return null; // Not a name query, use fallback search
    }
    
    final studentName = admission['name']?.toString().toLowerCase() ?? '';
    final fatherName = admission['father_name']?.toString().toLowerCase() ?? '';
    
    if (studentName.isEmpty && fatherName.isEmpty) {
      return false; // No names to search
    }
    
    // Clean the query for name processing
    final cleanQuery = query.trim().toLowerCase();
    
    // For mixed content, extract the name part
    String searchTerm = cleanQuery;
    if (RegExp(r'\d+|سال|class|جماعت|فیس|fee').hasMatch(cleanQuery)) {
      final nameMatch = RegExp(r'^[a-zA-Zآ-ی\s]+').firstMatch(cleanQuery);
      if (nameMatch != null) {
        searchTerm = nameMatch.group(0)!.trim().toLowerCase();
      }
    }
    
    // Parse multiple names: "ali and ahmad", "ali,ahmad,nr", "ali, ahmad"
    List<String> searchTerms = [];
    
    // Check for "and" separator
    if (searchTerm.contains(' and ') || searchTerm.contains(' اور ')) {
      searchTerms = searchTerm.split(RegExp(r'\s+(?:and|اور)\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // Check for comma separator
    else if (searchTerm.contains(',') || searchTerm.contains('،')) {
      searchTerms = searchTerm.split(RegExp(r'[,،]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // Single name
    else {
      searchTerms = [searchTerm];
    }
    
    // PRIORITY 1: Search in student name column FIRST
    bool foundInStudentName = false;
    for (final term in searchTerms) {
      if (_searchInName(studentName, term)) {
        foundInStudentName = true;
        break;
      }
    }
    
    // If found in student name, return true immediately (don't check father name)
    if (foundInStudentName) {
      print('Name search debug - Found in student name: "$studentName", query: "$searchTerm"');
      return true;
    }
    
    // PRIORITY 2: Only if NOT found in student name, then search in father name
    for (final term in searchTerms) {
      if (_searchInName(fatherName, term)) {
        print('Name search debug - Found in father name: "$fatherName", query: "$searchTerm"');
        return true;
      }
    }
    
    print('Name search debug - Not found in either name, student: "$studentName", father: "$fatherName", query: "$searchTerm"');
    return false; // No name match found
  }
  
  bool _searchInName(String name, String searchTerm) {
    if (name.isEmpty || searchTerm.isEmpty) return false;
    
    // Pattern 1: Exact match or contains search
    if (name.contains(searchTerm)) {
      return true;
    }
    
    // Pattern 2: Fuzzy matching for typos (for longer inputs)
    if (searchTerm.length >= 3) {
      // Check if names are similar (allowing for 1-2 character differences)
      if (_isSimilarName(name, searchTerm)) {
        return true;
      }
      
      // Check if any word in the name is similar
      final nameWords = name.split(' ');
      for (final word in nameWords) {
        if (word.isNotEmpty && _isSimilarName(word, searchTerm)) {
          return true;
        }
      }
    }
    
    // Pattern 3: Starts with search (for short inputs)
    if (searchTerm.length <= 3) {
      final nameWords = name.split(' ');
      for (final word in nameWords) {
        if (word.startsWith(searchTerm)) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _isSimilarName(String name, String searchTerm) {
    if (name.isEmpty || searchTerm.isEmpty) return false;
    
    // Simple similarity check - allows for 1-2 character differences
    if (name == searchTerm) return true;
    
    // If lengths are very different, not similar
    if ((name.length - searchTerm.length).abs() > 2) return false;
    
    // Count matching characters in order
    int matches = 0;
    int searchIndex = 0;
    
    for (int i = 0; i < name.length && searchIndex < searchTerm.length; i++) {
      if (name[i] == searchTerm[searchIndex]) {
        matches++;
        searchIndex++;
      }
    }
    
    // Consider similar if most characters match
    final similarity = matches / searchTerm.length;
    return similarity >= 0.7; // 70% similarity threshold
  }

  String _formatDateOnly(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty || dateValue.toString() == 'none') {
      return 'none';
    }
    
    try {
      DateTime date;
      // Handle DateTime object (from PostgreSQL)
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        // Handle String
        date = DateTime.parse(dateValue);
      } else {
        return 'none';
      }
      
      return '${date.year.toString().padLeft(4, '0')}-'
             '${date.month.toString().padLeft(2, '0')}-'
             '${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateValue.toString();
    }
  }
  
  String _translateResidencyStatus(String status) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (!languageProvider.isUrdu) return status;
    
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'resident':
        return 'رہائشی';
      case 'non-resident':
      case 'non resident':
        return 'غیر رہائشی';
      default:
        return status;
    }
  }
  
  String _translateStatus(String status, bool isUrdu) {
    if (!isUrdu) return status;
    
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'active':
        return 'فعال';
      case 'graduate':
        return 'فارغ';
      case 'struck off':
        return 'خارج';
      default:
        return status;
    }
  }

  List<Widget> _buildSmartSuggestions(bool isUrdu) {
    return _smartSuggestions.map((suggestion) => GestureDetector(
      onTap: () {
        _searchAnalytics[suggestion] = (_searchAnalytics[suggestion] ?? 0) + 1;
        _searchController.text = suggestion;
        _filterAdmissions(suggestion);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 14, color: Colors.blue[600]),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }

  Color _getRowColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'graduate':
        return Colors.green.shade100;
      case 'struck off':
        return Colors.red.shade100;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isUrdu ? 'داخلے' : 'Admissions'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              },
              tooltip: 'Home',
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        leadingWidth: 100,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.arrow_downward),
            tooltip: 'Download',
            onSelected: (value) {
              // This will be implemented later
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.grid_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final isUrdu = languageProvider.isUrdu;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: isUrdu ? 'تلاش کریں...' : 'Search...',
                              prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterAdmissions('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _filterAdmissions,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_showSuggestions && _smartSuggestions.isNotEmpty && _searchQuery.trim().isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[800]),
                                SizedBox(width: 4),
                                Text(
                                  isUrdu ? 'تجاویز:' : 'Suggestions:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _buildSmartSuggestions(isUrdu),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),          if
 (_searchQuery.isNotEmpty)
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final isUrdu = languageProvider.isUrdu;
                final count = _getFilteredCount();
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green[50],
                  child: Text(
                    isUrdu 
                        ? 'نتائج: $count طلباء ملے'
                        : 'Results: $count students found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final isUrdu = languageProvider.isUrdu;
                final isWindows = Theme.of(context).platform == TargetPlatform.windows;
                
                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  child: isWindows 
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DataTable(
                          columnSpacing: 20,
                          border: TableBorder.all(
                            color: Colors.grey[400]!,
                            width: 1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.grey[100]!,
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          dataTextStyle: TextStyle(
                            color: Colors.black87,
                          fontSize: 13,
                        ),
                        horizontalMargin: 12,
                        columns: isUrdu ? [
                          DataColumn(label: Text('اعمال')),
                          DataColumn(label: Text('فراغت کی تاریخ')),
                          DataColumn(label: Text('خارج ہونے کی تاریخ')),
                          DataColumn(label: Text('داخلے کی تاریخ')),
                          DataColumn(label: Text('رہائشی حیثیت')),
                          DataColumn(label: Text('حیثیت')),
                          DataColumn(label: Text('فیس')),
                          DataColumn(label: Text('کلاس')),
                          DataColumn(label: Text('موبائل')),
                          DataColumn(label: Text('والد کا نام')),
                          DataColumn(label: Text('نام')),
                          DataColumn(label: Text('تصویر')),
                          DataColumn(label: Text('آئی ڈی')),
                        ] : [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Picture')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Father')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Class')),
                          DataColumn(label: Text('Fee')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Residency Status')),
                          DataColumn(label: Text('Admission Date')),
                          DataColumn(label: Text('Struck Off Date')),
                          DataColumn(label: Text('Graduation Date')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _buildDataRows(),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DataTable(
                          border: TableBorder.all(
                            color: Colors.grey[400]!,
                            width: 1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.grey[100]!,
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          dataTextStyle: TextStyle(
                            color: Colors.black87,
                          ),
                          columns: isUrdu ? [
                            DataColumn(label: Text('اعمال')),
                            DataColumn(label: Text('فراغت کی تاریخ')),
                            DataColumn(label: Text('خارج ہونے کی تاریخ')),
                            DataColumn(label: Text('داخلے کی تاریخ')),
                            DataColumn(label: Text('رہائشی حیثیت')),
                            DataColumn(label: Text('حیثیت')),
                            DataColumn(label: Text('فیس')),
                            DataColumn(label: Text('کلاس')),
                            DataColumn(label: Text('موبائل')),
                            DataColumn(label: Text('والد کا نام')),
                            DataColumn(label: Text('نام')),
                            DataColumn(label: Text('تصویر')),
                            DataColumn(label: Text('آئی ڈی')),
                          ] : [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Picture')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Father')),
                            DataColumn(label: Text('Mobile')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Fee')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Residency Status')),
                            DataColumn(label: Text('Admission Date')),
                            DataColumn(label: Text('Struck Off Date')),
                            DataColumn(label: Text('Graduation Date')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _buildDataRows(),
                        ),
                      ),
                    ),
                  );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!_hasMore)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text("No more data")),
            ),
        ],
      ),
        ],
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    final admissionsData = _admissions;

    List<Map<String, dynamic>> filteredAdmissions;
    
    if (_searchQuery.isEmpty) {
      filteredAdmissions = admissionsData;
      filteredAdmissions.sort((a, b) {
        final aId = a['id'];
        final bId = b['id'];
        final aInt = aId is int ? aId : int.tryParse(aId?.toString() ?? '') ?? 0;
        final bInt = bId is int ? bId : int.tryParse(bId?.toString() ?? '') ?? 0;
        return bInt.compareTo(aInt);
      });
    } else {
      filteredAdmissions = admissionsData
          .where((admission) => _matchesSearchQuery(admission, _searchQuery))
          .toList();
    }

    return filteredAdmissions.map((admission) {
      final status = admission['status']?.toString() ?? 'Active';
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isUrdu = languageProvider.isUrdu;
      final translatedStatus = _translateStatus(status, isUrdu);
      
      // Build cells in English order
      final cells = [
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['id']?.toString() ?? 'N/A'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: admission['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      admission['image'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person),
                  ),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['name'] ?? 'none'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['father_name'] ?? 'none'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['mobile_no']?.toString() ?? 'none'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['class'] ?? 'none'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(admission['fee']?.toString() ?? 'none'),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.toLowerCase() == 'active' 
                    ? Colors.green[100] 
                    : status.toLowerCase() == 'graduate'
                        ? Colors.blue[100]
                        : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status.toLowerCase() == 'active' 
                      ? Colors.green[300]! 
                      : status.toLowerCase() == 'graduate'
                          ? Colors.blue[300]!
                          : Colors.red[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                translatedStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: status.toLowerCase() == 'active' 
                      ? Colors.green[800] 
                      : status.toLowerCase() == 'graduate'
                          ? Colors.blue[800]
                          : Colors.red[800],
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(_translateResidencyStatus(admission['residency_status'] ?? 'Resident')),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(_formatDateOnly(admission['admission_date'])),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(_formatDateOnly(admission['struck_off_date'])),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(_formatDateOnly(admission['graduation_date'])),
          ),
        ),    
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdmissionFormScreen(
                        admission: admission,
                        isEdit: true,
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(isUrdu ? 'تصدیق کریں' : 'Confirm'),
                      content: Text(
                        isUrdu
                            ? 'کیا آپ واقعی اس داخلے کو حذف کرنا چاہتے ہیں؟'
                            : 'Are you sure you want to delete this admission?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            isUrdu ? 'حذف کریں' : 'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      await DatabaseService.deleteAdmission(admission['id'].toString());
                      // Reload the admissions list
                      setState(() {
                        _admissions.clear();
                        _lastId = null;
                        _hasMore = true;
                      });
                      await _fetchAdmissions();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isUrdu ? 'حذف ہو گیا' : 'Deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } else if (value == 'graduate') {
                  await _updateStudentStatus(admission['id'].toString(), 'Graduate');
                } else if (value == 'struck_off') {
                  await _updateStudentStatus(admission['id'].toString(), 'Struck Off');
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(isUrdu ? 'تبدیل کریں' : 'Edit'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(isUrdu ? 'حذف کریں' : 'Delete'),
                  ),
                  PopupMenuItem<String>(
                    value: 'graduate',
                    child: Text(isUrdu ? 'فارغ کے طور پر نشان زد کریں' : 'Mark as Graduate'),
                  ),
                  PopupMenuItem<String>(
                    value: 'struck_off',
                    child: Text(isUrdu ? 'خارج کے طور پر نشان زد کریں' : 'Mark as Struck Off'),
                  ),
                ];
              },
            ),
          ),
        ),
      ];
      
      return DataRow(
        color: WidgetStateColor.resolveWith((states) => _getRowColor(status)),
        cells: isUrdu ? cells.reversed.toList() : cells,
      );
    }).toList();
  }
  
  int _getFilteredCount() {
    if (_searchQuery.isEmpty) return _admissions.length;

    final admissionsData = _admissions;

    return admissionsData.where((admission) => _matchesSearchQuery(admission, _searchQuery)).length;
  }
}