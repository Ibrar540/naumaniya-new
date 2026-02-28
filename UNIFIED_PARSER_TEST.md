# Unified Search Parser - Testing & Integration Guide

## Overview
The `UnifiedSearchParser` has been created to convert natural language queries (Urdu/English) into structured JSON filters. This document provides test examples and integration steps.

## Current Status
✅ **COMPLETED**:
- Created `lib/services/unified_search_parser.dart` with full parsing logic
- Integrated with existing date search services (admission, struck-off, graduation)
- Supports all filter types: ID, name, father name, class, fee, status, dates
- Generates exactly 3 smart recommendations per query
- Handles mixed Urdu/English input with typo tolerance

⏳ **PENDING**:
- Test the parser with various query examples
- Integrate into `admission_view_screen.dart`
- Create comprehensive documentation
- Add validation and error handling

---

## Test Examples

### 1. ID Search Tests

#### Test 1.1: Exact ID
```dart
final result = UnifiedSearchParser.parse('ID 7', false);
```
**Expected Output**:
```json
{
  "filters": {
    "id": 7,
    "id_range": null,
    "name": null,
    "father_name": null,
    "class": null,
    "fee_condition": null,
    "status": null,
    "date_filter": {
      "column": null,
      "type": null,
      "value": null,
      "start": null,
      "end": null
    }
  },
  "recommendations": [
    "ID 7 record",
    "ID 7 to 17",
    "Students after ID 7"
  ]
}
```

#### Test 1.2: ID Range
```dart
final result = UnifiedSearchParser.parse('ID 10 to 20', false);
```
**Expected Output**:
```json
{
  "filters": {
    "id": null,
    "id_range": {
      "start": 10,
      "end": 20
    },
    ...
  },
  "recommendations": [...]
}
```

#### Test 1.3: Urdu ID
```dart
final result = UnifiedSearchParser.parse('آئی ڈی 7', true);
```
**Expected Output**: Similar to Test 1.1 but with Urdu recommendations

---

### 2. Date Search Tests

#### Test 2.1: Admission Year
```dart
final result = UnifiedSearchParser.parse('2024 میں داخل ہونے والے طلبہ', true);
```
**Expected Output**:
```json
{
  "filters": {
    "id": null,
    "id_range": null,
    "name": null,
    "father_name": null,
    "class": null,
    "fee_condition": null,
    "status": null,
    "date_filter": {
      "column": "admission_date",
      "type": "year",
      "value": 2024,
      "start": null,
      "end": null
    }
  },
  "recommendations": [
    "2024 میں داخل ہونے والے طلبہ",
    "2024 کے ایڈمیشن کا مکمل ریکارڈ",
    "2024 میں رجسٹر ہونے والے طلبہ"
  ]
}
```

#### Test 2.2: Struck-Off Month
```dart
final result = UnifiedSearchParser.parse('Jan 2024 struck off', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "date_filter": {
      "column": "struck_off_date",
      "type": "month",
      "value": {
        "month": 1,
        "year": 2024
      },
      "start": null,
      "end": null
    }
  },
  "recommendations": [
    "Jan 2024 میں اخراج شدہ طلبہ",
    "January میں اخراج شدہ طلبہ کا ریکارڈ",
    "جنوری میں نکالے گئے طلبہ"
  ]
}
```

#### Test 2.3: Graduation Range
```dart
final result = UnifiedSearchParser.parse('2020 سے 2023 تک فارغ', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "date_filter": {
      "column": "graduation_date",
      "type": "range",
      "value": null,
      "start": "2020-01-01T00:00:00.000",
      "end": "2023-12-31T23:59:59.999"
    }
  },
  "recommendations": [...]
}
```

---

### 3. Class Search Tests

#### Test 3.1: Single Class
```dart
final result = UnifiedSearchParser.parse('class A students', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "class": "A",
    ...
  },
  "recommendations": [
    "All students in class A",
    "Active students in class A",
    "Class A fee details"
  ]
}
```

#### Test 3.2: Urdu Class
```dart
final result = UnifiedSearchParser.parse('جماعت B کے طلبہ', true);
```
**Expected Output**: Similar to Test 3.1 with Urdu recommendations

---

### 4. Fee Search Tests

#### Test 4.1: With Fee
```dart
final result = UnifiedSearchParser.parse('students with fee', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "fee_condition": {
      "operator": ">",
      "value": 0
    },
    ...
  },
  "recommendations": [...]
}
```

#### Test 4.2: Fee Greater Than
```dart
final result = UnifiedSearchParser.parse('فیس 500 سے زیادہ', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "fee_condition": {
      "operator": ">",
      "value": 500
    },
    ...
  },
  "recommendations": [...]
}
```

#### Test 4.3: Fee Less Than
```dart
final result = UnifiedSearchParser.parse('fee less than 1000', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "fee_condition": {
      "operator": "<",
      "value": 1000
    },
    ...
  },
  "recommendations": [...]
}
```

---

### 5. Status Search Tests

#### Test 5.1: Active Status
```dart
final result = UnifiedSearchParser.parse('فعال طلبہ', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "status": "active",
    ...
  },
  "recommendations": [
    "فعال طلبہ کی فہرست",
    "فعال طلبہ کا مکمل ریکارڈ",
    "فعال طلبہ کی تعداد"
  ]
}
```

#### Test 5.2: Struck Off Status
```dart
final result = UnifiedSearchParser.parse('struck off students', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "status": "struck off",
    ...
  },
  "recommendations": [...]
}
```

#### Test 5.3: Graduate Status
```dart
final result = UnifiedSearchParser.parse('فارغ التحصیل', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "status": "graduate",
    ...
  },
  "recommendations": [...]
}
```

---

### 6. Name Search Tests

#### Test 6.1: Name Search
```dart
final result = UnifiedSearchParser.parse('name Ali', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "name": "Ali",
    ...
  },
  "recommendations": [...]
}
```

#### Test 6.2: Father Name Search
```dart
final result = UnifiedSearchParser.parse('والد کا نام احمد', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "father_name": "احمد",
    ...
  },
  "recommendations": [...]
}
```

---

### 7. Combined Filter Tests

#### Test 7.1: Class + Status
```dart
final result = UnifiedSearchParser.parse('class A active students', false);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "class": "A",
    "status": "active",
    ...
  },
  "recommendations": [...]
}
```

#### Test 7.2: Class + Fee
```dart
final result = UnifiedSearchParser.parse('جماعت B فیس والے طلبہ', true);
```
**Expected Output**:
```json
{
  "filters": {
    ...
    "class": "B",
    "fee_condition": {
      "operator": ">",
      "value": 0
    },
    ...
  },
  "recommendations": [...]
}
```

---

## Integration Steps

### Step 1: Test the Parser
Create a test file to verify all functionality:

```dart
// test/unified_search_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naumaniya_new/services/unified_search_parser.dart';

void main() {
  group('UnifiedSearchParser Tests', () {
    test('Parse ID query', () {
      final result = UnifiedSearchParser.parse('ID 7', false);
      expect(result['filters']['id'], 7);
      expect(result['recommendations'].length, 3);
    });
    
    test('Parse admission date query', () {
      final result = UnifiedSearchParser.parse('2024 admission', false);
      expect(result['filters']['date_filter']['column'], 'admission_date');
      expect(result['filters']['date_filter']['type'], 'year');
    });
    
    // Add more tests...
  });
}
```

### Step 2: Integrate into admission_view_screen.dart

Replace the existing search logic with the unified parser:

```dart
// In _generateSmartSuggestions method
void _generateSmartSuggestions(String query) {
  final lowerQuery = query.toLowerCase().trim();
  _smartSuggestions.clear();
  
  if (lowerQuery.isEmpty) {
    return;
  }
  
  if (!mounted) return;
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final isUrdu = languageProvider.isUrdu;
  
  // Use unified parser
  final parseResult = UnifiedSearchParser.parse(query, isUrdu);
  _smartSuggestions = List<String>.from(parseResult['recommendations']);
}

// In _matchesSearchQuery method
bool _matchesSearchQuery(Map<String, dynamic> admission, String query) {
  final lowerQuery = query.toLowerCase().trim();
  if (lowerQuery.isEmpty) return true;
  
  if (!mounted) return false;
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final isUrdu = languageProvider.isUrdu;
  
  // Parse query using unified parser
  final parseResult = UnifiedSearchParser.parse(query, isUrdu);
  final filters = parseResult['filters'];
  
  // Apply filters using AND logic
  return _applyFilters(admission, filters);
}

// New method to apply filters
bool _applyFilters(Map<String, dynamic> admission, Map<String, dynamic> filters) {
  // Check ID filter
  if (filters['id'] != null) {
    final admissionId = int.tryParse(admission['id']?.toString() ?? '0') ?? 0;
    if (admissionId != filters['id']) return false;
  }
  
  // Check ID range filter
  if (filters['id_range'] != null) {
    final admissionId = int.tryParse(admission['id']?.toString() ?? '0') ?? 0;
    final start = filters['id_range']['start'];
    final end = filters['id_range']['end'];
    if (admissionId < start || admissionId > end) return false;
  }
  
  // Check name filter
  if (filters['name'] != null) {
    final name = admission['name']?.toString().toLowerCase() ?? '';
    if (!name.contains(filters['name'].toString().toLowerCase())) return false;
  }
  
  // Check father name filter
  if (filters['father_name'] != null) {
    final fatherName = admission['father_name']?.toString().toLowerCase() ?? '';
    if (!fatherName.contains(filters['father_name'].toString().toLowerCase())) return false;
  }
  
  // Check class filter
  if (filters['class'] != null) {
    final className = admission['class']?.toString().toUpperCase() ?? '';
    if (className != filters['class'].toString().toUpperCase()) return false;
  }
  
  // Check fee condition filter
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
  
  // Check status filter
  if (filters['status'] != null) {
    final status = admission['status']?.toString().toLowerCase() ?? '';
    if (status != filters['status'].toString().toLowerCase()) return false;
  }
  
  // Check date filter
  if (filters['date_filter']['column'] != null) {
    final dateColumn = filters['date_filter']['column'];
    final dateType = filters['date_filter']['type'];
    final dateValue = admission[dateColumn];
    
    if (dateValue == null || dateValue.toString() == 'none') return false;
    
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
  
  // All filters passed
  return true;
}
```

### Step 3: Add Import Statement

Add the import at the top of `admission_view_screen.dart`:

```dart
import '../services/unified_search_parser.dart';
```

### Step 4: Remove Old Search Methods

After integration, remove the old individual search methods:
- `_generateIntelligentIdSuggestions`
- `_generateIntelligentDateSuggestions`
- `_generateIntelligentStruckOffSuggestions`
- `_generateIntelligentGraduationSuggestions`
- `_generateIntelligentClassSuggestions`
- `_generateIntelligentFeeSuggestions`
- `_generateIntelligentStatusSuggestions`
- `_generateIntelligentNameSuggestions`
- `_processIntelligentIdSearch`
- `_processIntelligentDateSearch`
- `_processIntelligentStruckOffSearch`
- `_processIntelligentGraduationSearch`
- `_processIntelligentClassSearch`
- `_processIntelligentFeeSearch`
- `_processIntelligentStatusSearch`
- `_processIntelligentNameSearch`

---

## Benefits of Unified Parser

### 1. Centralized Logic
- All search parsing in one place
- Easier to maintain and debug
- Consistent behavior across all search types

### 2. Structured Output
- JSON format makes it easy to understand what was parsed
- Clear separation between filters and recommendations
- Easy to extend with new filter types

### 3. Combined Filters
- Supports multiple filters in one query
- AND logic for combining filters
- More powerful search capabilities

### 4. Reusability
- Can be used in other screens (teachers, students, etc.)
- Can be exported as API for external use
- Can be tested independently

### 5. Better UX
- Consistent recommendations across all search types
- Smart suggestions based on parsed filters
- Handles complex queries naturally

---

## Next Steps

1. ✅ Create test file with comprehensive examples
2. ⏳ Run tests to verify parser functionality
3. ⏳ Integrate parser into admission_view_screen.dart
4. ⏳ Test integration with real data
5. ⏳ Remove old search methods
6. ⏳ Create comprehensive documentation
7. ⏳ Add error handling and validation
8. ⏳ Consider adding to other screens

---

## Known Limitations

1. **Name Extraction**: Currently basic - could be improved with NLP
2. **Multiple Values**: Limited support for multiple values per filter
3. **Complex Queries**: Very complex queries might not parse correctly
4. **Validation**: No validation of parsed values yet
5. **Error Handling**: Basic error handling - needs improvement

---

## Future Enhancements

1. **Natural Language Processing**: Use NLP for better name extraction
2. **Query History**: Learn from user's search patterns
3. **Auto-correction**: Suggest corrections for invalid queries
4. **Voice Input**: Support voice-based queries
5. **Export Functionality**: Export parsed queries as SQL
6. **Analytics**: Track popular search patterns
7. **Multi-language**: Support more languages beyond Urdu/English

---

## Conclusion

The Unified Search Parser provides a powerful, centralized way to handle all search queries in the application. It converts natural language input into structured JSON filters, making it easy to apply complex search logic while maintaining clean, maintainable code.

The parser is ready for testing and integration. Once integrated, it will significantly improve the search experience and make the codebase more maintainable.
