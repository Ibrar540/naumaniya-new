# Dynamic Section Detection - Usage Guide

## Quick Start

The AI Assistant now automatically detects any section name you create in the database. No code changes needed when adding new sections!

## How to Use

### 1. Create a Section in Database
```sql
INSERT INTO sections (name, institution, type) 
VALUES ('Ali', 'masjid', 'income');
```

### 2. Query Using Natural Language
```
"Give me total income from Ali"
"Show me Ali income in 2025"
"Total income from Ali"
```

### 3. Get Results
The system will automatically:
- Detect "Ali" as a section name
- Filter results to show only Ali's income
- Return formatted response

## Supported Query Patterns

### Basic Queries
```
"Total income from [SECTION_NAME]"
"Give me [SECTION_NAME] income"
"Show me income from [SECTION_NAME]"
```

### With Year Filter
```
"Total income from [SECTION_NAME] in 2025"
"[SECTION_NAME] income for 2024"
```

### With Month Filter
```
"[SECTION_NAME] income in March 2025"
"Total from [SECTION_NAME] last month"
```

### Different Modules
```
"Masjid income from [SECTION_NAME]"
"Madrasa expenditure from [SECTION_NAME]"
```

### Expenditure Queries
```
"Total expenditure from [SECTION_NAME]"
"[SECTION_NAME] expense in 2025"
```

## Examples

### Example 1: Person Name as Section
```
Section in DB: "Ali"
Query: "Give me total income from Ali"
Result: Sum of all income entries for Ali section
```

### Example 2: Category Name
```
Section in DB: "Zakat"
Query: "Show me Zakat income in 2025"
Result: Sum of Zakat income for year 2025
```

### Example 3: Multi-Word Section
```
Section in DB: "Sadqa Jariya"
Query: "Total income from Sadqa Jariya"
Result: Sum of all Sadqa Jariya income
```

### Example 4: Case Insensitive
```
Section in DB: "Donation"
Query: "total income from DONATION"
Result: Works! Case doesn't matter
```

## What Gets Filtered

The system ignores these common words:
- give, me, total, income, expenditure, expense
- from, of, in, for, the, a, an
- masjid, madrasa, مسجد, مدرسہ
- آمدنی, خرچ, کل

This means "Ali" will be detected even in:
- "Give me total income from Ali"
- "Show me the income of Ali"
- "Ali income please"

## Debugging

### Check Logs
When you make a query, check the backend logs:
```
🤖 Processing query: Give me total income from Ali
📋 Parsed intent: { module: 'masjid', type: 'income', section: null, ... }
🎯 Found section match: "Ali" in message
✨ Dynamic section detected: ali
🔍 SQL Query: SELECT SUM(t.rs) as total FROM masjid_income t...
📊 Parameters: ["ali"]
```

### Verify Section Exists
```sql
SELECT * FROM sections WHERE LOWER(name) = 'ali';
```

### Check Section Assignment
```sql
SELECT * FROM masjid_income WHERE section_id = (
  SELECT id FROM sections WHERE LOWER(name) = 'ali'
);
```

## Troubleshooting

### Section Not Detected?

1. **Check spelling**: Section name must match exactly (case-insensitive)
2. **Check database**: Verify section exists in `sections` table
3. **Check institution**: Section must be in correct institution (masjid/madrasa)
4. **Check type**: Section must be in correct type (income/expenditure)

### Wrong Results?

1. **Check section_id**: Verify income/expenditure records have correct section_id
2. **Check data**: Verify records exist for that section
3. **Check filters**: Year/month filters might be excluding data

### Multiple Sections Match?

The system returns the first match found. To avoid ambiguity:
- Use unique section names
- Be specific in queries: "masjid income from Ali" vs "madrasa income from Ali"

## API Response Format

```json
{
  "success": true,
  "intent": "total",
  "module": "masjid",
  "type": "income",
  "section": "ali",
  "year": 2025,
  "month": null,
  "result": 150000,
  "message": "Total Income for Ali of Masjid in 2025 is 150,000 PKR.",
  "data": {
    "total": "150000"
  }
}
```

## Best Practices

### 1. Use Descriptive Section Names
✅ Good: "Ali Donations", "Zakat Fund", "Electricity Bill"
❌ Avoid: "A", "X", "Test"

### 2. Avoid Common Words as Section Names
❌ Avoid: "Total", "Income", "From"
✅ Better: "Total Fund", "Income Tax", "From Abroad"

### 3. Be Consistent with Naming
✅ Good: "Ali", "Ahmed", "Hassan" (all person names)
❌ Confusing: "Ali", "person2", "donor_3"

### 4. Use Proper Capitalization in Database
✅ Good: "Ali", "Zakat", "Sadqa Jariya"
(System handles case-insensitivity automatically)

## Integration with Flutter App

The Flutter app can use this feature without changes:

```dart
// In ai_chat_service.dart
final response = await http.post(
  Uri.parse('$baseUrl/ai-query'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'message': userMessage}),
);

// Response automatically includes detected section
final data = jsonDecode(response.body);
print('Section detected: ${data['section']}');
```

## Performance Notes

- Dynamic detection only runs if initial parsing finds no section
- Single database query per request (when needed)
- Cached section names could improve performance (future enhancement)
- Minimal overhead for most queries

## Future Enhancements

Potential improvements:
1. Cache section names in memory
2. Support fuzzy matching (typo tolerance)
3. Support synonyms (e.g., "electricity" → "electric bill")
4. Support Urdu section names better
5. Support partial matches with confidence scores

## Status
✅ Fully implemented and ready to use
✅ Backward compatible with existing queries
✅ No breaking changes
✅ Production ready
