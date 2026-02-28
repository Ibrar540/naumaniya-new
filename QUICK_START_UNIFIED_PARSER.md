# Unified Search Parser - Quick Start Guide

## 🚀 What Is It?
A single service that converts natural language queries (Urdu/English) into structured JSON filters.

## 📦 Installation
Already created! File: `lib/services/unified_search_parser.dart`

## 🎯 Basic Usage

### 1. Import
```dart
import '../services/unified_search_parser.dart';
```

### 2. Parse a Query
```dart
final result = UnifiedSearchParser.parse('ID 7', false);
// Returns: {"filters": {...}, "recommendations": [...]}
```

### 3. Get Recommendations
```dart
final suggestions = result['recommendations'];
// Returns: ["ID 7 record", "ID 7 to 17", "Students after ID 7"]
```

### 4. Apply Filters
```dart
final filters = result['filters'];
if (filters['id'] != null) {
  // Filter by ID
}
```

## 📝 Quick Examples

### English Queries
```dart
UnifiedSearchParser.parse('ID 7', false)
UnifiedSearchParser.parse('class A students', false)
UnifiedSearchParser.parse('students with fee', false)
UnifiedSearchParser.parse('active students', false)
UnifiedSearchParser.parse('admission 2024', false)
```

### Urdu Queries
```dart
UnifiedSearchParser.parse('آئی ڈی 7', true)
UnifiedSearchParser.parse('جماعت A کے طلبہ', true)
UnifiedSearchParser.parse('فیس والے طلبہ', true)
UnifiedSearchParser.parse('فعال طلبہ', true)
UnifiedSearchParser.parse('2024 میں داخلہ', true)
```

### Combined Queries
```dart
UnifiedSearchParser.parse('class A active students', false)
UnifiedSearchParser.parse('جماعت B فیس والے طلبہ', true)
UnifiedSearchParser.parse('ID 10 to 20 active', false)
```

## 🔍 Supported Filters

| Type | Example | Filter Output |
|------|---------|--------------|
| ID | `ID 7` | `{"id": 7}` |
| ID Range | `ID 10 to 20` | `{"id_range": {"start": 10, "end": 20}}` |
| Class | `class A` | `{"class": "A"}` |
| Fee | `fee > 500` | `{"fee_condition": {">", 500}}` |
| Status | `active` | `{"status": "active"}` |
| Date | `2024 admission` | `{"date_filter": {...}}` |
| Name | `name Ali` | `{"name": "Ali"}` |

## 🧪 Testing

### Run Tests
```bash
dart test_unified_parser.dart
```

### Test Output
```
=== UNIFIED SEARCH PARSER TESTS ===

TEST 1: ID Search
Query: "ID 7"
{
  "filters": {
    "id": 7,
    ...
  },
  "recommendations": [...]
}
```

## 🔗 Integration

### In Search Suggestions
```dart
void _generateSmartSuggestions(String query) {
  final result = UnifiedSearchParser.parse(query, isUrdu);
  _smartSuggestions = List<String>.from(result['recommendations']);
}
```

### In Search Filter
```dart
bool _matchesSearchQuery(Map<String, dynamic> admission, String query) {
  final result = UnifiedSearchParser.parse(query, isUrdu);
  final filters = result['filters'];
  
  // Check ID
  if (filters['id'] != null && admission['id'] != filters['id']) {
    return false;
  }
  
  // Check class
  if (filters['class'] != null && admission['class'] != filters['class']) {
    return false;
  }
  
  // Check other filters...
  
  return true;
}
```

## 📚 Documentation

- **UNIFIED_PARSER_TEST.md** - Detailed testing guide
- **UNIFIED_PARSER_COMPLETE.md** - Full implementation details
- **TASK_5_UNIFIED_PARSER_SUMMARY.md** - Task summary

## ✅ Status

**Implementation**: ✅ Complete  
**Testing**: ⏳ Pending  
**Integration**: ⏳ Pending  

## 🎯 Next Steps

1. Run tests: `dart test_unified_parser.dart`
2. Integrate into `admission_view_screen.dart`
3. Test with real data
4. Remove old search methods

## 💡 Tips

- Always pass `isUrdu` flag correctly
- Parser returns exactly 3 recommendations
- Filters use AND logic (all must match)
- Empty query returns default suggestions
- Handles typos and mixed languages

## 🐛 Troubleshooting

**No recommendations?**
- Check if query is empty
- Verify `isUrdu` flag is correct

**Filters not working?**
- Check filter structure in output
- Verify filter application logic

**Date filters not detected?**
- Ensure date keywords are present
- Check date format is supported

## 📞 Support

See full documentation in:
- `UNIFIED_PARSER_TEST.md`
- `UNIFIED_PARSER_COMPLETE.md`

---

**Quick Start Complete!** 🎉
