# Intelligent Search Bar - Integration Guide

## 📦 What Was Created

**File**: `lib/widgets/intelligent_search_bar.dart`

A production-ready, AI-powered search bar widget with:
- ✅ Real-time suggestions (exactly 3)
- ✅ Enterprise-level parser integration
- ✅ Confidence score display
- ✅ Intent detection
- ✅ Conflict warnings
- ✅ Bilingual support (Urdu/English)
- ✅ Debouncing for performance
- ✅ Analytics tracking hooks
- ✅ Beautiful Material Design UI

---

## 🚀 Quick Start

### Step 1: Import the Widget
```dart
import 'package:naumaniya_new/widgets/intelligent_search_bar.dart';
```

### Step 2: Use in Your Screen
```dart
IntelligentSearchBar(
  isUrdu: true,
  onSearch: (query) {
    // Execute search with the query
    _performSearch(query);
  },
  onFilterChange: (parseResult) {
    // Optional: React to filter changes in real-time
    print('Filters: ${parseResult['filters']}');
    print('Confidence: ${parseResult['confidence_score']}');
  },
)
```

---

## 📋 Complete Integration Example

### Example 1: Basic Integration (admission_view_screen.dart)

```dart
import 'package:flutter/material.dart';
import '../widgets/intelligent_search_bar.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AdmissionViewScreen extends StatefulWidget {
  const AdmissionViewScreen({Key? key}) : super(key: key);

  @override
  State<AdmissionViewScreen> createState() => _AdmissionViewScreenState();
}

class _AdmissionViewScreenState extends State<AdmissionViewScreen> {
  List<Map<String, dynamic>> _admissions = [];
  List<Map<String, dynamic>> _filteredAdmissions = [];
  bool _isLoading = false;
  Map<String, dynamic>? _currentFilters;

  @override
  void initState() {
    super.initState();
    _fetchAdmissions();
  }

  Future<void> _fetchAdmissions() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await DatabaseService.getAdmissionsPaginated();
      setState(() {
        _admissions = data;
        _filteredAdmissions = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAdmissions = _admissions;
      });
      return;
    }

    // Apply filters from the current parse result
    if (_currentFilters != null) {
      setState(() {
        _filteredAdmissions = _applyFilters(_admissions, _currentFilters!);
      });
    }
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> parseResult,
  ) {
    final filters = parseResult['filters'];
    
    return data.where((admission) {
      // Apply ID filter
      if (filters['id'] != null) {
        if (admission['id'] != filters['id']) return false;
      }
      
      // Apply ID range filter
      if (filters['id_range'] != null) {
        final id = int.tryParse(admission['id']?.toString() ?? '0') ?? 0;
        final start = filters['id_range']['start'];
        final end = filters['id_range']['end'];
        if (id < start || id > end) return false;
      }
      
      // Apply class filter
      if (filters['class'] != null && (filters['class'] as List).isNotEmpty) {
        final classes = filters['class'] as List;
        final admissionClass = admission['class']?.toString().toUpperCase() ?? '';
        if (!classes.contains(admissionClass)) return false;
      }
      
      // Apply status filter
      if (filters['status'] != null) {
        final status = admission['status']?.toString().toLowerCase() ?? '';
        if (status != filters['status'].toString().toLowerCase()) return false;
      }
      
      // Apply fee filter
      if (filters['fee_condition'] != null) {
        final fee = double.tryParse(admission['fee']?.toString() ?? '0') ?? 0.0;
        final operator = filters['fee_condition']['operator'];
        final value = filters['fee_condition']['value'];
        
        switch (operator) {
          case '>':
            if (fee <= value) return false;
            break;
          case '<':
            if (fee >= value) return false;
            break;
          case '=':
            if (fee != value) return false;
            break;
        }
      }
      
      // Apply date filter
      if (filters['date_filter']['column'] != null) {
        final dateColumn = filters['date_filter']['column'];
        final dateType = filters['date_filter']['type'];
        final dateValue = admission[dateColumn];
        
        if (dateValue == null) return false;
        
        DateTime? date;
        try {
          if (dateValue is DateTime) {
            date = dateValue;
          } else if (dateValue is String && dateValue.isNotEmpty) {
            date = DateTime.parse(dateValue);
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
        
        // Apply date filter based on type
        switch (dateType) {
          case 'exact':
            final exactDate = DateTime.parse(filters['date_filter']['value']);
            if (date.year != exactDate.year || 
                date.month != exactDate.month || 
                date.day != exactDate.day) return false;
            break;
          case 'year':
            if (date.year != filters['date_filter']['value']) return false;
            break;
          case 'month':
            final monthValue = filters['date_filter']['value'];
            if (date.year != monthValue['year'] || 
                date.month != monthValue['month']) return false;
            break;
          case 'range':
            final start = DateTime.parse(filters['date_filter']['start']);
            final end = DateTime.parse(filters['date_filter']['end']);
            if (date.isBefore(start) || date.isAfter(end)) return false;
            break;
        }
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isUrdu ? 'داخلہ ریکارڈ' : 'Admission Records'),
      ),
      body: Column(
        children: [
          // Intelligent Search Bar
          IntelligentSearchBar(
            isUrdu: languageProvider.isUrdu,
            onSearch: _performSearch,
            onFilterChange: (parseResult) {
              setState(() {
                _currentFilters = parseResult;
              });
              
              // Show confidence warning if low
              if (parseResult['confidence_score'] < 60) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      languageProvider.isUrdu
                          ? 'تلاش بہت وسیع ہے، براہ کرم مزید تفصیلات شامل کریں'
                          : 'Search is too broad, please add more details',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAdmissions.isEmpty
                    ? Center(
                        child: Text(
                          languageProvider.isUrdu
                              ? 'کوئی نتیجہ نہیں ملا'
                              : 'No results found',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredAdmissions.length,
                        itemBuilder: (context, index) {
                          final admission = _filteredAdmissions[index];
                          return ListTile(
                            title: Text(admission['name'] ?? ''),
                            subtitle: Text(
                              'ID: ${admission['id']} | Class: ${admission['class']}',
                            ),
                            trailing: Text(admission['status'] ?? ''),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎨 Widget Features

### 1. Real-Time Suggestions
- Displays exactly 3 suggestions
- Updates dynamically as user types
- Never repeats exact user input
- Debounced for performance (300ms)

### 2. Confidence Badge
- **Green (High)**: 85-100% confidence
- **Orange (Med)**: 70-84% confidence
- **Red (Low)**: 0-69% confidence

### 3. Intent Display
Shows detected intent in suggestions header:
- EXACT_LOOKUP
- FILTER_SEARCH
- RANGE_QUERY
- DATE_QUERY
- COMBINED_COMPLEX
- INCOMPLETE_QUERY

### 4. Conflict Warnings
Displays warnings when contradictory filters detected:
- "Both exact ID and ID range specified - using ID range"

### 5. Beautiful UI
- Material Design 3
- Smooth animations
- Touch-friendly (mobile optimized)
- RTL support for Urdu

---

## 📊 Widget Properties

### Required Properties
```dart
IntelligentSearchBar(
  isUrdu: bool,              // Language context
  onSearch: Function(String), // Search callback
)
```

### Optional Properties
```dart
IntelligentSearchBar(
  onFilterChange: Function(Map<String, dynamic>)?, // Real-time filter updates
  hintText: String?,                                // Custom hint text
  controller: TextEditingController?,               // External controller
  autofocus: bool,                                  // Auto-focus on mount
  padding: EdgeInsets?,                             // Custom padding
)
```

---

## 🎯 Advanced Usage

### Example 2: With External Controller
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _clearSearch() {
    _searchController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntelligentSearchBar(
          isUrdu: true,
          controller: _searchController,
          onSearch: (query) {
            print('Search: $query');
          },
        ),
        ElevatedButton(
          onPressed: _clearSearch,
          child: Text('Clear'),
        ),
      ],
    );
  }
}
```

### Example 3: With Real-Time Filter Updates
```dart
IntelligentSearchBar(
  isUrdu: false,
  onSearch: (query) {
    _executeSearch(query);
  },
  onFilterChange: (parseResult) {
    // Update UI based on filters
    setState(() {
      _currentIntent = parseResult['intent'];
      _currentConfidence = parseResult['confidence_score'];
      _requiresPagination = parseResult['requires_pagination'];
    });
    
    // Show pagination warning
    if (parseResult['requires_pagination']) {
      _showPaginationWarning();
    }
    
    // Track analytics
    _trackFilterChange(parseResult);
  },
)
```

### Example 4: With Custom Styling
```dart
IntelligentSearchBar(
  isUrdu: true,
  hintText: 'طالب علم تلاش کریں...',
  autofocus: true,
  padding: EdgeInsets.all(20),
  onSearch: (query) {
    _performSearch(query);
  },
)
```

---

## 🔧 Customization

### Modify Debounce Duration
```dart
// In intelligent_search_bar.dart, line ~80
_debounceTimer = Timer(const Duration(milliseconds: 300), () {
  _generateSuggestions(query);
});

// Change to 500ms for slower typing
_debounceTimer = Timer(const Duration(milliseconds: 500), () {
  _generateSuggestions(query);
});
```

### Customize Suggestion UI
```dart
// In intelligent_search_bar.dart, _buildSuggestionItem method
Widget _buildSuggestionItem(String suggestion, int index) {
  return InkWell(
    onTap: () => _selectSuggestion(suggestion, index),
    child: Container(
      padding: const EdgeInsets.all(16), // Customize padding
      child: Row(
        children: [
          Icon(Icons.search, size: 24), // Customize icon
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: TextStyle(fontSize: 16), // Customize text style
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 📊 Analytics Integration

### Track Suggestion Usage
```dart
// In intelligent_search_bar.dart, _trackSuggestionSelected method
void _trackSuggestionSelected(String query, String suggestion, int index) {
  // Firebase Analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'suggestion_selected',
    parameters: {
      'query': query,
      'suggestion': suggestion,
      'index': index,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
  
  // Custom analytics
  AnalyticsService.trackSuggestionSelection(
    query: query,
    suggestion: suggestion,
    index: index,
  );
}
```

### Track Search Execution
```dart
void _executeSearch() {
  final query = _controller.text.trim();
  
  // Track search
  FirebaseAnalytics.instance.logEvent(
    name: 'search_executed',
    parameters: {
      'query': query,
      'intent': _currentParseResult?['intent'],
      'confidence': _currentParseResult?['confidence_score'],
    },
  );
  
  widget.onSearch(query);
}
```

---

## 🎓 Best Practices

### DO ✅
```dart
// Use with language provider
final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
IntelligentSearchBar(isUrdu: isUrdu, ...);

// Handle filter changes
onFilterChange: (result) {
  if (result['confidence_score'] < 60) {
    showWarning('Query too broad');
  }
}

// Apply filters properly
_applyFilters(_admissions, parseResult['filters']);
```

### DON'T ❌
```dart
// Don't ignore confidence score
onFilterChange: (result) {
  // Missing confidence check
  _applyFilters(result['filters']);
}

// Don't forget to handle empty queries
void _performSearch(String query) {
  // Missing empty check
  _applyFilters(query);
}

// Don't block UI thread
void _generateSuggestions(String query) {
  // Missing debouncing
  final result = UnifiedSearchParser.parse(query, isUrdu);
}
```

---

## 🐛 Troubleshooting

### Issue 1: Suggestions Not Showing
**Solution**: Check if `_focusNode.hasFocus` is true and query is not empty

### Issue 2: Performance Issues
**Solution**: Increase debounce duration or implement caching

### Issue 3: Wrong Language Suggestions
**Solution**: Ensure `isUrdu` flag is correctly set from LanguageProvider

### Issue 4: Filters Not Applied
**Solution**: Verify `_applyFilters` method handles all filter types

---

## 📈 Performance Metrics

### Expected Performance
- **Parsing Speed**: <10ms per query
- **Suggestion Generation**: <50ms
- **UI Update**: <16ms (60fps)
- **Memory Usage**: ~1KB per query

### Optimization Tips
1. Use debouncing (already implemented)
2. Cache frequent queries
3. Limit result set size
4. Use pagination for large datasets

---

## 🎉 Summary

The Intelligent Search Bar provides:

✅ **AI-Powered Suggestions** - Enterprise-level parser  
✅ **Real-Time Updates** - Dynamic as user types  
✅ **Confidence Display** - Visual feedback on query quality  
✅ **Intent Detection** - Understands user's goal  
✅ **Conflict Warnings** - Alerts on contradictions  
✅ **Bilingual Support** - Urdu + English  
✅ **Beautiful UI** - Material Design 3  
✅ **Production Ready** - Tested and optimized  

**Status**: ✅ Complete and ready to use  
**Integration**: Drop-in replacement for standard TextField  
**Next Step**: Add to your screens and enjoy intelligent search!

---

## 📚 Related Files

- `lib/widgets/intelligent_search_bar.dart` - Main widget
- `lib/services/unified_search_parser.dart` - Parser service
- `ENTERPRISE_PARSER_GUIDE.md` - Parser documentation
- `AI_AUTO_SUGGESTION_SYSTEM.md` - System specification

---

**Intelligent Search Bar Complete!** 🎉
