import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_message.dart';

/// Conversational AI Chat Service
/// Provides ChatGPT-like conversational interface for data queries
/// Integrated with Node.js backend for financial queries
class AIChatService {
  final List<ChatMessage> _conversationHistory = [];
  
  // Backend API URL - Update this with your deployed backend URL
  static const String _backendUrl = 'http://localhost:3000/ai-query';
  // For production, use: 'https://your-backend-url.com/ai-query'

  /// Get conversation history
  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Process user message and generate AI response
  Future<ChatMessage> processMessage(String userMessage, {required bool isUrdu}) async {
    // Add user message to history
    final userChatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: userMessage,
    );
    _conversationHistory.add(userChatMessage);

    try {
      // Check if query is financial (budget-related)
      if (_isFinancialQuery(userMessage)) {
        // Use backend AI for financial queries
        final responseContent = await _queryBackendAI(userMessage, isUrdu);
        final suggestions = _generateFinancialSuggestions(isUrdu);

        final assistantMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: responseContent,
          suggestions: suggestions,
        );

        _conversationHistory.add(assistantMessage);
        return assistantMessage;
      } else {
        // Use local response for non-financial queries
        final responseContent = _generateResponse(userMessage, isUrdu);
        final suggestions = _generateSuggestions(userMessage, isUrdu);

        final assistantMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: responseContent,
          suggestions: suggestions,
        );

        _conversationHistory.add(assistantMessage);
        return assistantMessage;
      }
    } catch (e) {
      debugPrint('Error processing message: $e');
      
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: isUrdu
            ? 'معذرت، میں آپ کی درخواست کو سمجھنے میں ناکام رہا۔ براہ کرم دوبارہ کوشش کریں یا اپنا سوال مختلف انداز میں پوچھیں۔'
            : 'I apologize, but I couldn\'t understand your request. Please try again or rephrase your question.',
        suggestions: _getDefaultSuggestions(isUrdu),
      );

      _conversationHistory.add(errorMessage);
      return errorMessage;
    }
  }

  /// Check if query is financial/budget-related
  bool _isFinancialQuery(String message) {
    final lowerMessage = message.toLowerCase();
    final financialKeywords = [
      'budget', 'income', 'expenditure', 'expense', 'masjid', 'madrasa',
      'zakat', 'charity', 'donation', 'total', 'balance', 'summary',
      'بجٹ', 'آمدنی', 'خرچ', 'مسجد', 'مدرسہ', 'زکوٰۃ', 'خیرات',
      'کل', 'بیلنس', 'خلاصہ', 'اخراجات'
    ];
    
    return financialKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Query backend AI for financial queries
  Future<String> _queryBackendAI(String message, bool isUrdu) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Format response based on intent
          return _formatBackendResponse(data, isUrdu);
        } else {
          return isUrdu
              ? 'معذرت، میں آپ کی درخواست کو پروسیس نہیں کر سکا۔'
              : 'Sorry, I couldn\'t process your request.';
        }
      } else {
        return isUrdu
            ? 'سرور سے رابطہ میں خرابی۔ براہ کرم دوبارہ کوشش کریں۔'
            : 'Server connection error. Please try again.';
      }
    } catch (e) {
      debugPrint('Backend AI error: $e');
      return isUrdu
          ? 'AI سرور سے رابطہ نہیں ہو سکا۔ براہ کرم بعد میں کوشش کریں۔'
          : 'Could not connect to AI server. Please try again later.';
    }
  }

  /// Format backend response for display
  String _formatBackendResponse(Map<String, dynamic> data, bool isUrdu) {
    final intent = data['intent'];
    final message = data['message'] ?? '';
    
    // Add emoji and formatting based on intent
    switch (intent) {
      case 'total':
        return '💰 $message';
      case 'net_balance':
        return '📊 $message';
      case 'compare':
        return '📈 $message';
      case 'summary':
        return message; // Already has emoji
      case 'breakdown':
        return message; // Already has emoji
      default:
        return message;
    }
  }

  /// Generate financial suggestions
  List<String> _generateFinancialSuggestions(bool isUrdu) {
    if (isUrdu) {
      return [
        'مسجد کی کل آمدنی 2025',
        'مدرسہ کا خرچ 2024',
        'مسجد کا خلاصہ 2025',
        'زکوٰۃ آمدنی 2025',
      ];
    } else {
      return [
        'Total income of masjid in 2025',
        'Madrasa expenditure 2024',
        'Financial summary of masjid 2025',
        'Zakat income in 2025',
      ];
    }
  }

  /// Generate conversational response
  String _generateResponse(String userMessage, bool isUrdu) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Detect query type
    if (_containsAny(lowerMessage, ['student', 'طلباء', 'طالب علم'])) {
      return isUrdu
          ? 'میں طلباء کی معلومات کے بارے میں آپ کی مدد کر سکتا ہوں۔\n\nآپ مجھ سے پوچھ سکتے ہیں:\n• تمام فعال طلباء دکھائیں\n• کلاس A میں کتنے طلباء ہیں؟\n• 2024 میں داخل ہونے والے طلباء\n\nکیا آپ کوئی مخصوص معلومات چاہتے ہیں؟'
          : 'I can help you with student information.\n\nYou can ask me:\n• Show all active students\n• How many students in class A?\n• Students admitted in 2024\n\nWhat specific information would you like?';
    }
    
    if (_containsAny(lowerMessage, ['teacher', 'اساتذہ', 'استاد'])) {
      return isUrdu
          ? 'میں اساتذہ کی معلومات کے بارے میں آپ کی مدد کر سکتا ہوں۔\n\nآپ مجھ سے پوچھ سکتے ہیں:\n• تمام فعال اساتذہ دکھائیں\n• اساتذہ کی کل تعداد\n• 5000 سے زیادہ تنخواہ والے اساتذہ\n\nکیا آپ کوئی مخصوص معلومات چاہتے ہیں؟'
          : 'I can help you with teacher information.\n\nYou can ask me:\n• Show all active teachers\n• Total number of teachers\n• Teachers with salary > 5000\n\nWhat specific information would you like?';
    }
    
    if (_containsAny(lowerMessage, ['budget', 'income', 'expenditure', 'بجٹ', 'آمدنی', 'خرچ'])) {
      return isUrdu
          ? 'میں بجٹ اور مالیاتی معلومات کے بارے میں آپ کی مدد کر سکتا ہوں۔\n\nآپ مجھ سے پوچھ سکتے ہیں:\n• 2024 کا بجٹ رپورٹ\n• کل آمدنی دکھائیں\n• اخراجات کی فہرست\n\nکیا آپ کوئی مخصوص معلومات چاہتے ہیں؟'
          : 'I can help you with budget and financial information.\n\nYou can ask me:\n• Budget report for 2024\n• Show total income\n• List expenditures\n\nWhat specific information would you like?';
    }
    
    if (_containsAny(lowerMessage, ['class', 'کلاس'])) {
      return isUrdu
          ? 'میں کلاسز کی معلومات کے بارے میں آپ کی مدد کر سکتا ہوں۔\n\nآپ مجھ سے پوچھ سکتے ہیں:\n• تمام کلاسز دکھائیں\n• کلاس A کی تفصیلات\n• کلاس کی گنجائش\n\nکیا آپ کوئی مخصوص معلومات چاہتے ہیں؟'
          : 'I can help you with class information.\n\nYou can ask me:\n• Show all classes\n• Class A details\n• Class capacity\n\nWhat specific information would you like?';
    }
    
    // Default response
    return isUrdu
        ? 'میں آپ کی مدد کے لیے حاضر ہوں! میں آپ کو مندرجہ ذیل معلومات فراہم کر سکتا ہوں:\n\n📚 طلباء کی معلومات\n👨‍🏫 اساتذہ کے ریکارڈز\n💰 بجٹ اور مالیاتی رپورٹس\n🏫 کلاسز کی تفصیلات\n\nبراہ کرم مجھے بتائیں کہ آپ کیا جاننا چاہتے ہیں؟'
        : 'I\'m here to help! I can provide you with:\n\n📚 Student information\n👨‍🏫 Teacher records\n💰 Budget and financial reports\n🏫 Class details\n\nPlease let me know what you\'d like to know?';
  }

  /// Generate smart suggestions
  List<String> _generateSuggestions(String userMessage, bool isUrdu) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (_containsAny(lowerMessage, ['student', 'طلباء'])) {
      return isUrdu
          ? [
              'تمام فعال طلباء دکھائیں',
              'کلاس A میں طلباء کی تعداد',
              '2024 میں داخل ہونے والے طلباء',
            ]
          : [
              'Show all active students',
              'How many students in class A?',
              'Students admitted in 2024',
            ];
    }
    
    if (_containsAny(lowerMessage, ['teacher', 'اساتذہ'])) {
      return isUrdu
          ? [
              'تمام فعال اساتذہ دکھائیں',
              'اساتذہ کی کل تعداد',
              '5000 سے زیادہ تنخواہ والے اساتذہ',
            ]
          : [
              'Show all active teachers',
              'Total number of teachers',
              'Teachers with salary > 5000',
            ];
    }
    
    if (_containsAny(lowerMessage, ['budget', 'بجٹ'])) {
      return isUrdu
          ? [
              '2024 کا بجٹ رپورٹ',
              'کل آمدنی دکھائیں',
              'اخراجات کی فہرست',
            ]
          : [
              'Budget report for 2024',
              'Show total income',
              'List expenditures',
            ];
    }
    
    return _getDefaultSuggestions(isUrdu);
  }

  /// Get default suggestions
  List<String> _getDefaultSuggestions(bool isUrdu) {
    if (isUrdu) {
      return [
        'تمام فعال طلباء دکھائیں',
        'اساتذہ کی کل تعداد بتائیں',
        '2024 کا بجٹ رپورٹ دکھائیں',
      ];
    } else {
      return [
        'Show all active students',
        'How many teachers do we have?',
        'Show budget report for 2024',
      ];
    }
  }

  /// Helper to check if text contains any keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Get welcome message
  ChatMessage getWelcomeMessage(bool isUrdu) {
    final content = isUrdu
        ? '👋 السلام علیکم! میں آپ کا AI اسسٹنٹ ہوں۔\n\n'
            'میں آپ کی مدد کر سکتا ہوں:\n'
            '• طلباء کی معلومات تلاش کرنے میں\n'
            '• اساتذہ کے ریکارڈز دیکھنے میں\n'
            '• بجٹ اور مالیاتی رپورٹس بنانے میں (AI Powered)\n'
            '• کلاسز کی تفصیلات دیکھنے میں\n\n'
            'آپ مجھ سے اردو یا انگریزی میں کچھ بھی پوچھ سکتے ہیں!'
        : '👋 Hello! I\'m your AI Assistant.\n\n'
            'I can help you with:\n'
            '• Finding student information\n'
            '• Viewing teacher records\n'
            '• Generating budget and financial reports (AI Powered)\n'
            '• Checking class details\n\n'
            'Feel free to ask me anything in English or Urdu!';

    final suggestions = isUrdu
        ? [
            'مسجد کی کل آمدنی 2025',
            'مدرسہ کا خرچ 2024',
            'مسجد کا خلاصہ 2025',
            'تمام فعال طلباء دکھائیں',
          ]
        : [
            'Total income of masjid in 2025',
            'Madrasa expenditure 2024',
            'Financial summary of masjid 2025',
            'Show all active students',
          ];

    return ChatMessage(
      id: 'welcome',
      role: MessageRole.assistant,
      content: content,
      suggestions: suggestions,
    );
  }
}
