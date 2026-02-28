# Budget Search Bar - Integration Guide for Masjid & Madrasa

## 🎯 Overview
This guide shows how to integrate the AI-powered Budget Search Bar into both Masjid and Madrasa budget management screens.

---

## 📦 Files Created

1. **`lib/services/budget_search_parser.dart`** - Enterprise-level parser
2. **`lib/widgets/budget_search_bar.dart`** - Search bar widget
3. **`test_budget_parser.dart`** - Test suite

---

## 🚀 Integration Steps

### Step 1: Import Required Files

```dart
import 'package:naumaniya_new/widgets/budget_search_bar.dart';
import 'package:naumaniya_new/services/budget_search_parser.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
```

### Step 2: Add State Variables

```dart
class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  Map<String, dynamic>? _currentFilters;
  bool _isLoading = false;
  
  // ... existing code
}
```

### Step 3: Implement Filter Application

```dart
List<Map<String, dynamic>> _applyBudgetFilters(
  List<Map<String, dynamic>> data,
  Map<String, dynamic> parseResult,
) {
  final filters = parseResult['filters'];
  
  return data.where((record) {
    // Apply description filter
    if (filters['description_contains'] != null) {
      final description = record['description']?.toString().toLowerCase() ?? '';
      final searchTerm = filters['description_contains'].toString().toLowerCase();
      if (!description.contains(searchTerm)) return false;
    }
    
    // Apply amount filter
    if (filters['amount_condition']['type'] != null) {
      final amount = double.tryParse(record['rs']?.toString() ?? '0') ?? 0.0;
      final type = filters['amount_condition']['type'];
      
      switch (type) {
        case 'exact':
          if (amount != filters['amount_condition']['value']) return false;
          break;
        case 'greater_than':
          if (amount <= filters['amount_condition']['value']) return false;
          break;
        case 'less_than':
          if (amount >= filters['amount_condition']['value']) return false;
          break;
        case 'range':
          final start = filters['amount_condition']['start'];
          final end = filters['amount_condition']['end'];
          if (amount < start || amount > end) return false;
          break;
      }
    }
    
    // Apply date filter
    if (filters['date_filter']['type'] != null) {
      final dateValue = record['date'];
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
      
      final type = filters['date_filter']['type'];
      
      switch (type) {
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
          final start = DateTime.parse(filters['date_filter']['start']);
          final end = DateTime.parse(filters['date_filter']['end']);
          if (date.isBefore(start) || date.isAfter(end)) return false;
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
```

### Step 4: Implement Search Handler

```dart
void _performBudgetSearch(String query) {
  if (query.isEmpty) {
    setState(() {
      _filteredRecords = _allRecords;
    });
    return;
  }

  if (_currentFilters != null) {
    setState(() {
      _filteredRecords = _applyBudgetFilters(_allRecords, _currentFilters!);
    });
  }
}
```

### Step 5: Add Search Bar to UI

```dart
@override
Widget build(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context);
  
  return Scaffold(
    appBar: AppBar(
      title: Text(languageProvider.isUrdu ? 'بجٹ مینجمنٹ' : 'Budget Management'),
    ),
    body: Column(
      children: [
        // Budget Search Bar
        BudgetSearchBar(
          isUrdu: languageProvider.isUrdu,
          onSearch: _performBudgetSearch,
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
                        ? 'تلاش بہت وسیع ہے'
                        : 'Search is too broad',
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
              : _filteredRecords.isEmpty
                  ? Center(
                      child: Text(
                        languageProvider.isUrdu
                            ? 'کوئی نتیجہ نہیں ملا'
                            : 'No results found',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = _filteredRecords[index];
                        return ListTile(
                          title: Text(record['description'] ?? ''),
                          subtitle: Text(
                            'Rs: ${record['rs']} | Date: ${record['date']}',
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
  );
}
```

---

## 📝 Complete Example for Masjid Budget

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/budget_search_bar.dart';
import '../services/database_service.dart';
import '../providers/language_provider.dart';

class MasjidBudgetScreen extends StatefulWidget {
  const MasjidBudgetScreen({Key? key}) : super(key: key);

  @override
  State<MasjidBudgetScreen> createState() => _MasjidBudgetScreenState();
}

class _MasjidBudgetScreenState extends State<MasjidBudgetScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  Map<String, dynamic>? _currentFilters;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMasjidBudget();
  }

  Future<void> _fetchMasjidBudget() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch both income and expenditure
      final income = await DatabaseService.getMasjidIncome();
      final expenditure = await DatabaseService.getMasjidExpenditure();
      
      setState(() {
        _allRecords = [...income, ...expenditure];
        _filteredRecords = _allRecords;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _performBudgetSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRecords = _allRecords;
      });
      return;
    }

    if (_currentFilters != null) {
      setState(() {
        _filteredRecords = _applyBudgetFilters(_allRecords, _currentFilters!);
      });
    }
  }

  List<Map<String, dynamic>> _applyBudgetFilters(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> parseResult,
  ) {
    final filters = parseResult['filters'];
    
    return data.where((record) {
      // Description filter
      if (filters['description_contains'] != null) {
        final description = record['description']?.toString().toLowerCase() ?? '';
        final searchTerm = filters['description_contains'].toString().toLowerCase();
        if (!description.contains(searchTerm)) return false;
      }
      
      // Amount filter
      if (filters['amount_condition']['type'] != null) {
        final amount = double.tryParse(record['rs']?.toString() ?? '0') ?? 0.0;
        final type = filters['amount_condition']['type'];
        
        switch (type) {
          case 'exact':
            if (amount != filters['amount_condition']['value']) return false;
            break;
          case 'greater_than':
            if (amount <= filters['amount_condition']['value']) return false;
            break;
          case 'less_than':
            if (amount >= filters['amount_condition']['value']) return false;
            break;
          case 'range':
            final start = filters['amount_condition']['start'];
            final end = filters['amount_condition']['end'];
            if (amount < start || amount > end) return false;
            break;
        }
      }
      
      // Date filter
      if (filters['date_filter']['type'] != null) {
        final dateValue = record['date'];
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
        
        final type = filters['date_filter']['type'];
        
        switch (type) {
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
        title: Text(
          languageProvider.isUrdu ? 'مسجد بجٹ' : 'Masjid Budget',
        ),
      ),
      body: Column(
        children: [
          BudgetSearchBar(
            isUrdu: languageProvider.isUrdu,
            onSearch: _performBudgetSearch,
            onFilterChange: (parseResult) {
              setState(() {
                _currentFilters = parseResult;
              });
            },
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                          languageProvider.isUrdu
                              ? 'کوئی نتیجہ نہیں ملا'
                              : 'No results found',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(record['description'] ?? ''),
                              subtitle: Text(
                                'Date: ${record['date']}',
                              ),
                              trailing: Text(
                                'Rs ${record['rs']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
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

## 📝 Complete Example for Madrasa Budget

```dart
// Same structure as Masjid, just change:
// - Screen name: MadrasaBudgetScreen
// - Title: 'مدرسہ بجٹ' / 'Madrasa Budget'
// - Data fetch: DatabaseService.getMadrasaIncome() / getMadrasaExpenditure()
```

---

## 🎯 Search Examples

### Amount Searches
```
"5000 rs" → Exact amount
"greater than 5000" → Amount > 5000
"2000 to 5000" → Amount range
"5000 se zyada" → Urdu: Amount > 5000
```

### Description Searches
```
"electricity bill" → Contains "electricity bill"
"salary" → Contains "salary"
"بجلی کا بل" → Urdu description
"مرمت" → Urdu: repair
```

### Date Searches
```
"2024" → Year 2024
"Jan 2024" → January 2024
"جنوری 2024" → Urdu: January 2024
"2020 to 2023" → Date range
"15-08-2024" → Exact date
```

### Combined Searches
```
"salary 50000" → Description + amount
"electricity bill 2024" → Description + date
"5000 Jan 2024" → Amount + date
```

---

## 🎨 UI Features

### Confidence Badge
- **Green (High)**: 85-100% - Exact/specific queries
- **Orange (Med)**: 70-84% - Single filter queries
- **Red (Low)**: 0-69% - Incomplete queries

### Intent Display
Shows in suggestions header:
- EXACT_AMOUNT
- RANGE_QUERY
- DATE_QUERY
- DESCRIPTION_SEARCH
- COMBINED_QUERY
- INCOMPLETE_QUERY

### Smart Suggestions
Always shows exactly 3 suggestions that:
- Start with user input
- Extend naturally
- Never repeat exact input
- Update dynamically

---

## 📊 Performance Tips

1. **Debouncing**: Already implemented (300ms)
2. **Pagination**: Check `requires_pagination` flag
3. **Caching**: Cache frequent queries
4. **Indexing**: Ensure database indexes on description, rs, date

---

## 🐛 Troubleshooting

### Issue: Suggestions not showing
**Solution**: Check if focus is on TextField and query is not empty

### Issue: Wrong filters applied
**Solution**: Verify `_applyBudgetFilters` handles all filter types

### Issue: Performance lag
**Solution**: Increase debounce duration or implement caching

---

## ✅ Integration Checklist

### For Masjid Budget
- [ ] Import BudgetSearchBar widget
- [ ] Add state variables
- [ ] Implement `_applyBudgetFilters` method
- [ ] Implement `_performBudgetSearch` method
- [ ] Add BudgetSearchBar to UI
- [ ] Test with sample queries
- [ ] Test with real data

### For Madrasa Budget
- [ ] Same steps as Masjid
- [ ] Update screen title
- [ ] Update data fetch methods
- [ ] Test independently

---

## 🎉 Summary

The Budget Search Bar provides:

✅ **AI-Powered** - Enterprise-level parser  
✅ **Real-Time** - Updates as user types  
✅ **Intelligent** - Intent detection & confidence scoring  
✅ **Bilingual** - Urdu + English support  
✅ **Specialized** - Built for budget management  
✅ **Easy Integration** - Drop-in widget  

**Status**: Ready for integration into both Masjid and Madrasa screens!
