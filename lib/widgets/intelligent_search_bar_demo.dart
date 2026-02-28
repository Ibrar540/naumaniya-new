import 'package:flutter/material.dart';
import 'intelligent_search_bar.dart';

/// Demo screen showing IntelligentSearchBar in action
/// Use this as a reference for integration
class IntelligentSearchBarDemo extends StatefulWidget {
  const IntelligentSearchBarDemo({Key? key}) : super(key: key);

  @override
  State<IntelligentSearchBarDemo> createState() => _IntelligentSearchBarDemoState();
}

class _IntelligentSearchBarDemoState extends State<IntelligentSearchBarDemo> {
  bool _isUrdu = true;
  String _lastSearch = '';
  Map<String, dynamic>? _lastParseResult;
  final List<String> _searchHistory = [];

  void _performSearch(String query) {
    setState(() {
      _lastSearch = query;
      if (query.isNotEmpty && !_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      }
    });

    // Show search result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isUrdu ? 'تلاش کا نتیجہ' : 'Search Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isUrdu ? 'تلاش:' : 'Query:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(query),
            const SizedBox(height: 16),
            if (_lastParseResult != null) ...[
              Text(
                _isUrdu ? 'ارادہ:' : 'Intent:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_lastParseResult!['intent'] ?? 'N/A'),
              const SizedBox(height: 8),
              Text(
                _isUrdu ? 'اعتماد:' : 'Confidence:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${_lastParseResult!['confidence_score']}%'),
              const SizedBox(height: 8),
              Text(
                _isUrdu ? 'صفحہ بندی:' : 'Pagination:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_lastParseResult!['requires_pagination'].toString()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isUrdu ? 'بند کریں' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _handleFilterChange(Map<String, dynamic> parseResult) {
    setState(() {
      _lastParseResult = parseResult;
    });
  }

  Widget _buildInfoCard(String title, String value, {Color? color}) {
    return Card(
      color: color?.withOpacity(0.1) ?? Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUrdu ? 'ذہین تلاش بار ڈیمو' : 'Intelligent Search Bar Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              setState(() {
                _isUrdu = !_isUrdu;
              });
            },
            tooltip: _isUrdu ? 'Switch to English' : 'اردو میں تبدیل کریں',
          ),
        ],
      ),
      body: Column(
        children: [
          // Intelligent Search Bar
          IntelligentSearchBar(
            isUrdu: _isUrdu,
            onSearch: _performSearch,
            onFilterChange: _handleFilterChange,
            autofocus: false,
          ),

          // Info Cards
          if (_lastParseResult != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isUrdu ? 'تلاش کی معلومات' : 'Search Information',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          _isUrdu ? 'ارادہ' : 'Intent',
                          _lastParseResult!['intent'] ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          _isUrdu ? 'اعتماد' : 'Confidence',
                          '${_lastParseResult!['confidence_score']}%',
                          color: _getConfidenceColor(
                            _lastParseResult!['confidence_score'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    _isUrdu ? 'صفحہ بندی کی ضرورت' : 'Requires Pagination',
                    _lastParseResult!['requires_pagination'].toString(),
                    color: _lastParseResult!['requires_pagination']
                        ? Colors.orange
                        : Colors.green,
                  ),
                  if (_lastParseResult!['conflict_warning'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lastParseResult!['conflict_warning'],
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Search History
          if (_searchHistory.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isUrdu ? 'تلاش کی تاریخ' : 'Search History',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchHistory.clear();
                            });
                          },
                          child: Text(_isUrdu ? 'صاف کریں' : 'Clear'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        final query = _searchHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query),
                          trailing: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _performSearch(query),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Example Queries
          if (_searchHistory.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isUrdu ? 'مثال کی تلاشیں' : 'Example Queries',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: _getExampleQueries()
                            .map((query) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.lightbulb_outline),
                                    title: Text(query),
                                    trailing: const Icon(Icons.arrow_forward),
                                    onTap: () => _performSearch(query),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 85) return Colors.green;
    if (confidence >= 70) return Colors.orange;
    return Colors.red;
  }

  List<String> _getExampleQueries() {
    if (_isUrdu) {
      return [
        'آئی ڈی 7',
        'جماعت A کے طلبہ',
        'فعال طلبہ',
        '2024 میں داخل ہونے والے طلبہ',
        'فیس والے طلبہ',
        'جماعت B فعال طلبہ',
        'ID 10 سے 20 تک',
        'اخراج شدہ طلبہ',
        'فیس 500 سے زیادہ',
        'جنوری 2024 میں داخلہ',
      ];
    } else {
      return [
        'ID 7',
        'class A students',
        'active students',
        'students admitted in 2024',
        'students with fee',
        'class B active students',
        'ID 10 to 20',
        'struck off students',
        'fee greater than 500',
        'admission Jan 2024',
      ];
    }
  }
}
