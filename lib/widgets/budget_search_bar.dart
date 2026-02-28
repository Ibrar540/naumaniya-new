import 'package:flutter/material.dart';
import 'dart:async';
import '../services/budget_search_parser.dart';

/// AI-Powered Budget Search Bar with Live Suggestions
/// Specialized for Budget Management (description, rs, date)
class BudgetSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Map<String, dynamic>)? onFilterChange;
  final bool isUrdu;
  final String? hintText;
  final TextEditingController? controller;
  final bool autofocus;
  final EdgeInsets? padding;
  
  const BudgetSearchBar({
    Key? key,
    required this.onSearch,
    this.onFilterChange,
    required this.isUrdu,
    this.hintText,
    this.controller,
    this.autofocus = false,
    this.padding,
  }) : super(key: key);

  @override
  State<BudgetSearchBar> createState() => _BudgetSearchBarState();
}

class _BudgetSearchBarState extends State<BudgetSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  Map<String, dynamic>? _currentParseResult;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    } else if (_controller.text.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
        _currentParseResult = null;
      });
      
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(BudgetSearchParser.parse('', widget.isUrdu));
      }
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generateSuggestions(query);
    });
  }

  void _generateSuggestions(String query) {
    try {
      final result = BudgetSearchParser.parse(query, widget.isUrdu);
      
      setState(() {
        _currentParseResult = result;
        _suggestions = List<String>.from(result['recommendations'] ?? []);
        _showSuggestions = _suggestions.isNotEmpty && _focusNode.hasFocus;
      });
      
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(result);
      }
    } catch (e) {
      print('Error generating suggestions: $e');
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
    }
  }

  void _selectSuggestion(String suggestion, int index) {
    _controller.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    
    widget.onSearch(suggestion);
    _focusNode.unfocus();
  }

  void _executeSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _showSuggestions = false;
    });
    
    widget.onSearch(query);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _currentParseResult = null;
    });
    
    if (widget.onFilterChange != null) {
      widget.onFilterChange!(BudgetSearchParser.parse('', widget.isUrdu));
    }
  }

  Widget _buildConfidenceBadge() {
    if (_currentParseResult == null) return const SizedBox.shrink();
    
    final confidence = _currentParseResult!['confidence_score'] ?? 0;
    
    Color badgeColor;
    String badgeText;
    
    if (confidence >= 85) {
      badgeColor = Colors.green;
      badgeText = widget.isUrdu ? 'اعلیٰ' : 'High';
    } else if (confidence >= 70) {
      badgeColor = Colors.orange;
      badgeText = widget.isUrdu ? 'درمیانہ' : 'Med';
    } else {
      badgeColor = Colors.red;
      badgeText = widget.isUrdu ? 'کم' : 'Low';
    }
    
    return Tooltip(
      message: 'Confidence: $confidence%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor, width: 1),
        ),
        child: Text(
          badgeText,
          style: TextStyle(
            color: badgeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, int index) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
                textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
            Icon(
              Icons.north_west,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 
                  (widget.isUrdu ? 'بجٹ تلاش کریں...' : 'Search budget...'),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentParseResult != null) _buildConfidenceBadge(),
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: _clearSearch,
                      tooltip: widget.isUrdu ? 'صاف کریں' : 'Clear',
                    ),
                  ],
                ],
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _executeSearch(),
          ),
        ),
        
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isUrdu ? 'تجاویز' : 'Suggestions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Spacer(),
                        if (_currentParseResult != null)
                          Text(
                            _currentParseResult!['intent'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionItem(_suggestions[index], index);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
