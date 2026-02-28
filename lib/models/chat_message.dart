import 'package:flutter/material.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<String>? suggestions;
  final List<ChatAction>? actions;
  final dynamic data; // For storing query results
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.suggestions,
    this.actions,
    this.data,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    List<String>? suggestions,
    List<ChatAction>? actions,
    dynamic data,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      suggestions: suggestions ?? this.suggestions,
      actions: actions ?? this.actions,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatAction {
  final String title;
  final String description;
  final IconData icon;
  final Function() onTap;

  ChatAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}
