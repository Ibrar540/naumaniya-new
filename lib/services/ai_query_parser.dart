class AIQueryParser {
  static Map<String, dynamic> parse(String query) {
    return {'module': 'students', 'intent': 'exact_list', 'confidence_score': 50, 'requires_pagination': false, 'filters': {}, 'total_computation': null, 'recommendations': []};
  }
}
