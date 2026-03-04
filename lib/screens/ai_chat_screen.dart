import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/language_provider.dart';
import '../services/ai_chat_service.dart';
import '../models/chat_message.dart';
import '../widgets/voice_input_button.dart';
import '../screens/home_screen.dart';
import '../utils/ai_export_utils.dart';
import 'dart:ui' as dart_ui;

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _chatService = AIChatService();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  List<String> _dynamicSuggestions = [];
  Timer? _debounceTimer;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer for debounced suggestion fetching
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (text.trim().isNotEmpty && text.trim().length > 2) {
        final suggestions = await _chatService.getSuggestions(text);
        if (mounted) {
          setState(() {
            _dynamicSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _dynamicSuggestions = [];
            _showSuggestions = false;
          });
        }
      }
    });
  }

  void _initializeChat() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final welcomeMessage = _chatService.getWelcomeMessage(languageProvider.isUrdu);
    setState(() {
      _messages = [welcomeMessage];
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    setState(() {
      _isTyping = true;
      _showSuggestions = false; // Hide suggestions when sending
      _dynamicSuggestions = [];
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.processMessage(
        message,
        isUrdu: languageProvider.isUrdu,
      );

      setState(() {
        _messages = _chatService.conversationHistory.toList();
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'خرابی: $e'
              : 'Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _exportMessage(ChatMessage message) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    try {
      final filePath = await AIExportUtils.exportToPDF(
        message.content,
        message.data as Map<String, dynamic>?,
      );
      
      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu
                ? 'PDF محفوظ ہو گیا: $filePath'
                : 'PDF saved: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: languageProvider.isUrdu ? 'کھولیں' : 'Open',
              textColor: Colors.white,
              onPressed: () {
                // Open file
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu
                ? 'ایکسپورٹ میں خرابی: $e'
                : 'Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printMessage(ChatMessage message) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    try {
      await AIExportUtils.printReport(
        message.content,
        message.data as Map<String, dynamic>?,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu
                ? 'پرنٹ میں خرابی: $e'
                : 'Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        return AlertDialog(
          title: Text(languageProvider.isUrdu ? 'چیٹ صاف کریں' : 'Clear Chat'),
          content: Text(languageProvider.isUrdu
              ? 'کیا آپ واقعی تمام چیٹ ہسٹری صاف کرنا چاہتے ہیں؟'
              : 'Are you sure you want to clear all chat history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageProvider.isUrdu ? 'منسوخ' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                _chatService.clearHistory();
                _initializeChat();
                Navigator.pop(context);
              },
              child: Text(
                languageProvider.isUrdu ? 'صاف کریں' : 'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, size: 24),
            SizedBox(width: 8),
            Text(isUrdu ? 'AI اسسٹنٹ' : 'AI Assistant'),
          ],
        ),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.home),
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
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: isUrdu ? 'چیٹ صاف کریں' : 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1976D2).withAlpha((0.05 * 255).toInt()),
                    Colors.white,
                  ],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator(isUrdu);
                  }
                  return _buildMessageBubble(_messages[index], isUrdu);
                },
              ),
            ),
          ),

          // Suggestions and Input area
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic suggestions
              if (_showSuggestions && _dynamicSuggestions.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dynamicSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF1976D2)),
                        title: Text(
                          _dynamicSuggestions[index],
                          style: TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          _messageController.text = _dynamicSuggestions[index];
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              
              // Input area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          decoration: InputDecoration(
                            hintText: isUrdu
                                ? 'اپنا سوال یہاں لکھیں...'
                                : 'Type your question here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sendMessage,
                        ),
                      ),
                  SizedBox(width: 8),
                  VoiceInputButton(
                    isUrdu: isUrdu,
                    onResult: _sendMessage,
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1976D2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isUrdu) {
    final isUser = message.role == MessageRole.user;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: Color(0xFF1976D2),
                  child: Icon(Icons.psychology, color: Colors.white, size: 20),
                  radius: 16,
                ),
                SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Color(0xFF1976D2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: isUrdu
                            ? dart_ui.TextDirection.rtl
                            : dart_ui.TextDirection.ltr,
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      // Export buttons for AI responses with data
                      if (!isUser && message.canExport) ...[
                        SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.download, size: 16),
                              label: Text(isUrdu ? 'ڈاؤن لوڈ' : 'Download'),
                              onPressed: () => _exportMessage(message),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF1976D2),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton.icon(
                              icon: Icon(Icons.print, size: 16),
                              label: Text(isUrdu ? 'پرنٹ' : 'Print'),
                              onPressed: () => _printMessage(message),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF1976D2),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (!isUser && message.suggestions != null && message.suggestions!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: 8),
                        Directionality(
                          textDirection: isUrdu
                              ? dart_ui.TextDirection.rtl
                              : dart_ui.TextDirection.ltr,
                          child: Text(
                            isUrdu ? 'تجاویز:' : 'Suggestions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        ...message.suggestions!.take(3).map((suggestion) =>
                          Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () => _sendMessage(suggestion),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1976D2).withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(0xFF1976D2).withAlpha((0.3 * 255).toInt()),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: Color(0xFF1976D2),
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Directionality(
                                        textDirection: isUrdu
                                            ? dart_ui.TextDirection.rtl
                                            : dart_ui.TextDirection.ltr,
                                        child: Text(
                                          suggestion,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[700], size: 20),
                  radius: 16,
                ),
              ],
            ],
          ),
          
          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 40,
              right: isUser ? 40 : 0,
            ),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isUrdu) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF1976D2),
            child: Icon(Icons.psychology, color: Colors.white, size: 20),
            radius: 16,
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        final opacity = (animValue * 2).clamp(0.3, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
