/// Enterprise-Level AI Query Parser
class AIQueryParser {
  static const Map<String, int> _monthMap = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4,
    'may': 5, 'june': 6, 'july': 7, 'august': 8,
    'september': 9, 'october': 10, 'november': 11, 'december': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9,
    'oct': 10, 'nov': 11, 'dec': 12,
    'جنوری': 1, 'فروری': 2, 'مارچ': 3, 'اپریل': 4,
    'مئی': 5, 'جون': 6, 'جولائی': 7, 'اگست': 8,
    'ستمبر': 9, 'اکتوبر': 10, 'نومبر': 11, 'دسمبر': 12,
  };

  static const Map<String, String> _statusMap = {
    'active': 'active',
    'فعال': 'active',
    'graduate': 'graduate',
    'graduated': 'graduate',
    'فارغ التحصیل': 'graduate',
    'فارغ': 'graduate',
    'struck off': 'struck_off',
    'struck-off': 'struck_off',
    'struckoff': 'struck_off',
    'خارج شدہ': 'struck_off',
    'خارج': 'struck_off',
    'left': 'left',
    'چھوڑ گیا': 'left',
  };

  static Map<String, dynamic> parse(String query) {
    final lowerQuery = query.toLowerCase().trim();
    final module = _detectModule(query, lowerQuery);
    final intent = _detectIntent(query, lowerQuery);
    final filters = _extractFilters(query, lowerQuery, module);
    final confidenceScore = _calculateConfidence(filters, intent);
    final requiresPagination = _checkPagination(filters);
    final totalComputation = _detectTotalComputation(query, lowerQuery);
    final recommendations = _generateRecommendations(query, module, filters);
    
    return {
      'module': module,
      'intent': intent,
      'confidence_score': confidenceScore,
      'requires_pagination': requiresPagination,
      'filters': filters,
      'total_computation': totalComputation,
      'recommendations': recommendations,
    };
  }

  static String _detectModule(String query, String lowerQuery) {
    if (_containsAny(lowerQuery, ['student', 'admission', 'طلباء', 'طالب علم', 'داخلہ'])) return 'students';
    if (_containsAny(lowerQuery, ['teacher', 'اساتذہ', 'استاد', 'معلم'])) return 'teachers';
    if (_containsAny(lowerQuery, ['class', 'کلاس', 'capacity', 'گنجائش']) && !_containsAny(lowerQuery, ['student', 'طلباء'])) return 'classes';
    if (_containsAny(lowerQuery, ['masjid income', 'مسجد آمدنی', 'mosque income', 'donation'])) return 'masjid_income';
    if (_containsAny(lowerQuery, ['masjid expenditure', 'مسجد خرچ', 'mosque expense'])) return 'masjid_expenditure';
    if (_containsAny(lowerQuery, ['madrasa budget', 'مدرسہ بجٹ', 'madrasah', 'school budget'])) return 'madrasa_budget';
    if (_containsAny(lowerQuery, ['budget', 'income', 'expenditure', 'بجٹ', 'آمدنی', 'خرچ'])) return 'madrasa_budget';
    return 'students';
  }

  static String _detectIntent(String query, String lowerQuery) {
    if (_containsAny(lowerQuery, ['total', 'sum', 'کل', 'مجموعہ'])) return 'total_computation';
    if (_containsAny(lowerQuery, ['count', 'how many', 'کتنے', 'تعداد'])) return 'filtered_list';
    if (_containsAny(lowerQuery, ['show', 'list', 'display', 'دکھائیں', 'فہرست'])) return 'filtered_list';
    return 'exact_list';
  }

  static Map<String, dynamic> _extractFilters(String query, String lowerQuery, String module) {
    return {
      'id': _extractId(lowerQuery),
      'id_range': null,
      'name': _extractName(query),
      'father_name': null,
      'status': _extractStatus(lowerQuery),
      'class': _extractClass(lowerQuery),
      'description_contains': _extractDescription(query),
      'amount_condition': _extractAmountCondition(lowerQuery),
      'date_filter': _extractDateFilter(query, lowerQuery),
      'module_type': null,
    };
  }

  static int? _extractId(String lowerQuery) {
    final idMatch = RegExp(r'\bid[:\s]+(\d+)').firstMatch(lowerQuery);
    return idMatch != null ? int.tryParse(idMatch.group(1)!) : null;
  }

  static String? _extractName(String query) {
    final nameMatch = RegExp(r'name[:\s]+([a-zA-Z\u0600-\u06FF\s]+)', caseSensitive: false).firstMatch(query);
    return nameMatch != null ? nameMatch.group(1)!.trim() : null;
  }

  static String? _extractStatus(String lowerQuery) {
    for (final entry in _statusMap.entries) {
      if (lowerQuery.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static List<String> _extractClass(String lowerQuery) {
    final classes = <String>[];
    if (lowerQuery.contains('class a') || lowerQuery.contains('کلاس ا')) classes.add('A');
    if (lowerQuery.contains('class b') || lowerQuery.contains('کلاس ب')) classes.add('B');
    if (lowerQuery.contains('class c') || lowerQuery.contains('کلاس ج')) classes.add('C');
    return classes;
  }

  static String? _extractDescription(String query) {
    final descMatch = RegExp(r'description[:\s]+([a-zA-Z\u0600-\u06FF\s]+)', caseSensitive: false).firstMatch(query);
    return descMatch != null ? descMatch.group(1)!.trim() : null;
  }

  static Map<String, dynamic> _extractAmountCondition(String lowerQuery) {
    final greaterMatch = RegExp(r'(?:more than|greater than|>|زیادہ)\s*(\d+)').firstMatch(lowerQuery);
    if (greaterMatch != null) return {'type': 'greater_than', 'value': double.parse(greaterMatch.group(1)!)};
    
    final lessMatch = RegExp(r'(?:less than|<|کم)\s*(\d+)').firstMatch(lowerQuery);
    if (lessMatch != null) return {'type': 'less_than', 'value': double.parse(lessMatch.group(1)!)};
    
    final rangeMatch = RegExp(r'between\s*(\d+)\s*and\s*(\d+)').firstMatch(lowerQuery);
    if (rangeMatch != null) return {'type': 'range', 'start': double.parse(rangeMatch.group(1)!), 'end': double.parse(rangeMatch.group(2)!)};
    
    final exactMatch = RegExp(r'(?:amount|fee|salary|rs)\s*(\d+)').firstMatch(lowerQuery);
    if (exactMatch != null) return {'type': 'exact', 'value': double.parse(exactMatch.group(1)!)};
    
    return {'type': null};
  }

  static Map<String, dynamic> _extractDateFilter(String query, String lowerQuery) {
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(query);
    if (yearMatch != null) {
      final year = int.parse(yearMatch.group(1)!);
      for (final entry in _monthMap.entries) {
        if (lowerQuery.contains(entry.key)) {
          return {'type': 'month', 'value': {'month': entry.value, 'year': year}};
        }
      }
      return {'type': 'year', 'value': year};
    }
    return {'type': null};
  }

  static int _calculateConfidence(Map<String, dynamic> filters, String intent) {
    int score = 50;
    if (filters['id'] != null) score += 50;
    if (filters['status'] != null) score += 20;
    if (filters['class'] != null && (filters['class'] as List).isNotEmpty) score += 15;
    if (filters['date_filter']['type'] != null) score += 10;
    if (filters['amount_condition']['type'] != null) score += 10;
    return score.clamp(0, 100);
  }

  static bool _checkPagination(Map<String, dynamic> filters) {
    return filters['id'] == null && filters['status'] == null && (filters['class'] as List).isEmpty;
  }

  static String? _detectTotalComputation(String query, String lowerQuery) {
    return _containsAny(lowerQuery, ['total', 'sum', 'کل', 'مجموعہ']) ? 'sum' : null;
  }

  static List<String> _generateRecommendations(String query, String module, Map<String, dynamic> filters) {
    final recommendations = <String>[];
    final isUrdu = _isUrdu(query);
    
    switch (module) {
      case 'students':
        recommendations.addAll(isUrdu ? ['تمام فعال طلباء دکھائیں', 'کلاس A میں طلباء کی تعداد', '2024 میں داخل ہونے والے طلباء'] : ['Show all active students', 'How many students in class A?', 'Students admitted in 2024']);
        break;
      case 'teachers':
        recommendations.addAll(isUrdu ? ['تمام فعال اساتذہ دکھائیں', 'اساتذہ کی کل تعداد', '5000 سے زیادہ تنخواہ والے اساتذہ'] : ['Show all active teachers', 'How many teachers total?', 'Teachers with salary > 5000']);
        break;
      default:
        recommendations.addAll(isUrdu ? ['2024 کا بجٹ رپورٹ', 'کل آمدنی دکھائیں', 'اخراجات کی فہرست'] : ['Budget report for 2024', 'Show total income', 'List all expenditures']);
    }
    return recommendations;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  static bool _isUrdu(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}
