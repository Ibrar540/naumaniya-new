import 'lib/services/ai_query_parser.dart';

void main() {
  final result = AIQueryParser.parse('test query');
  print(result);
}
