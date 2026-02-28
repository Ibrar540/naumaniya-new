import 'package:flutter/material.dart';

class AIQueryResult {
  final String module; // 'students', 'teachers', 'budget', 'mixed'
  final List<dynamic> data;
  final String summary;
  final List<AIAction> actions;
  final Map<String, dynamic> filters;
  final List<String> suggestions;

  AIQueryResult({
    required this.module,
    required this.data,
    required this.summary,
    this.actions = const [],
    this.filters = const {},
    this.suggestions = const [],
  });
}

class AIAction {
  final String title;
  final String description;
  final IconData icon;
  final Function() onTap;

  AIAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
} 