import 'lib/services/ai_chat_service.dart';

void main() async {
  final service = AIChatService();
  final suggestions = await service.getSuggestions('test');
  print('Suggestions: $suggestions');
}
