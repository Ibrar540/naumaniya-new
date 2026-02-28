import 'package:flutter/material.dart';
import 'dart:async';
import '../services/unified_search_parser.dart';

/// AI-Powered Intelligent Search Bar with Live Suggestions
/// Provides real-time, context-aware search suggestions as user types
class IntelligentSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Map<String, dynamic>)? onFilterChange;
  final bool isUrdu;
  final String? hintText;
  final TextEditingController? controller;
  final bool autofocus;
  final EdgeInsets? padding;
  
  const IntelligentSearchBar({
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
  State<IntelligentSearchBar> createState() => _IntelligentSearchBarState();
}

class _IntelligentSearchBarState extends State<IntelligentSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  Map<String, dynamic>? _currentParseResult;
  
  // Analytics tracking
  final Map<String, int> _suggestionSelectionCount = {};
  
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
      // Hide suggestions when focus is lost
      setState(() {
        _showSuggestions = false;
      });
    } else if (_controller.text.isNotEmpty) {
      // Show suggestions when focus is gained and there's text
      setState(() {
        _showSuggestions = true;
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
        _currentParseResult = null;
      });
      
      // Notify parent of filter change
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(UnifiedSearchParser.parse('', widget.isUrdu));
      }
      return;
    }
    
    // Debounce for 300ms to avoid excessive parsing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generateSuggestions(query);
    });
  }

  void _generateSuggestions(String query) {
    try {
      // Parse query using enterprise-level parser
      final result = UnifiedSearchParser.parse(query, widget.isUrdu);
      
      setState(() {
        _currentParseResult = result;
        _suggestions = List<String>.from(result['recommendations'] ?? []);
        _showSuggestions = _suggestions.isNotEmpty && _focusNode.hasFocus;
      });
      
      // Notify parent of filter change
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(result);
      }
      
      // Track suggestion display
      _trackSuggestionShown(query, _suggestions);
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
    
    // Track suggestion selection
    _trackSuggestionSelected(_controller.text, suggestion, index);
    
    // Execute search
    widget.onSearch(suggestion);
    
    // Unfocus to hide keyboard
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
    
    // Notify parent of filter change
    if (widget.onFilterChange != null) {
      widget.onFilterChange!(UnifiedSearchParser.parse('', widget.isUrdu));
    }
  }

  // Analytics tracking methods
  void _trackSuggestionShown(String query, List<String> suggestions) {
    // TODO: Implement analytics tracking
    print('Suggestions shown for "$query": ${suggestions.length}');
  }

  void _trackSuggestionSelected(String query, String suggestion, int index) {
    // Track selection count
    _suggestionSelectionCount[suggestion] = 
        (_suggestionSelectionCount[suggestion] ?? 0) + 1;
    
    // TODO: Implement analytics tracking
    print('Suggestion selected: "$suggestion" (index: $index) for query: "$query"');
  }

  Widget _buildConfidenceBadge() {
    if (_currentParseResult == null) return const SizedBox.shrink();
    
    final confidence = _currentParseResult!['confidence_score'] ?? 0;
    final intent = _currentParseResult!['intent'] ?? '';
    
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
      message: 'Confidence: $confidence%, Intent: $intent',
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
    // Highlight matching part
    final query = _controller.text.toLowerCase();
    final suggestionLower = suggestion.toLowerCase();
    final matchIndex = suggestionLower.indexOf(query);
    
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
        // Search TextField
        Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 
                  (widget.isUrdu ? 'تلاش کریں...' : 'Search...'),
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
        
        // Suggestions Dropdown
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
                  // Suggestions header
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
                  
                  // Suggestion items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionItem(_suggestions[index], index);
                    },
                  ),
                  
                  // Conflict warning (if any)
                  if (_currentParseResult?['conflict_warning'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentParseResult!['conflict_warning'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
