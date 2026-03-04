# Dynamic Section Detection - Complete

## Overview
Enhanced the AI Assistant backend to dynamically detect user-created section names in financial queries. The system now recognizes any section name stored in the database, not just fixed keywords.

## Problem Solved
Previously, only fixed keywords like "income", "masjid", "total" were recognized. If a user created a section named "Ali" in masjid_income, queries like "Give me total income from Ali" would ignore the section and return totals for all sections.

## Solution Implemented

### 1. Enhanced Section Detection in `aiEngine.js`
- Improved `detectSection()` method with two-pass matching:
  - **First pass**: Exact substring match (case-insensitive)
  - **Second pass**: Word boundary match
- Added detailed logging for debugging
- Returns lowercase section name for consistent matching

### 2. Dynamic Section Detection in `index.js`
- Added `detectDynamicSection()` helper function
- Triggered when initial parsing doesn't find a section
- Queries database for sections matching the module and type
- Filters out common words to focus on potential section names
- Matches section names against message words
- Logs detected sections for debugging

### 3. Enhanced Query Flow
```javascript
// 1. Parse intent from message
const intent = await aiEngine.parse(message);

// 2. If no section detected, try dynamic detection
if (!intent.section && intent.module && intent.type !== 'both') {
  const dynamicSection = await detectDynamicSection(message, intent.module, intent.type);
  if (dynamicSection) {
    intent.section = dynamicSection;
  }
}

// 3. Build and execute query with detected section
const { query, params } = queryBuilder.buildQuery(intent);
const queryResult = await db.query(query, params);
```

## How It Works

### Example Query: "Give me total income from Ali"

1. **Initial Parsing** (`aiEngine.parse()`)
   - Module: "masjid" (default)
   - Type: "income" (detected from "income" keyword)
   - Section: null (no match in initial scan)
   - Intent: "total" (detected from "total" keyword)

2. **Dynamic Detection** (`detectDynamicSection()`)
   - Queries: `SELECT DISTINCT name FROM sections WHERE institution = 'masjid' AND type = 'income'`
   - Extracts words from message: ["give", "me", "total", "income", "from", "ali"]
   - Filters common words: ["ali"]
   - Matches "ali" against section names
   - Finds section "Ali" in database
   - Returns: "ali" (lowercase)

3. **Query Building** (`queryBuilder.buildQuery()`)
   - Generates SQL with section filter:
   ```sql
   SELECT SUM(t.rs) as total 
   FROM masjid_income t
   LEFT JOIN sections s ON t.section_id = s.id
   WHERE 1=1 
   AND LOWER(s.name) = $1
   ```
   - Parameters: ["ali"]

4. **Result**
   - Returns sum of income only for "Ali" section
   - Formatted response with section name included

## Features

### Case-Insensitive Matching
- "Ali", "ali", "ALI" all match the same section
- Database comparison uses `LOWER()` function

### Multi-Word Section Names
- Supports sections like "Sadqa Jariya", "Zakat Fund"
- Matches if full name appears in message

### Filtered Word Matching
- Ignores common words: "give", "me", "total", "income", etc.
- Focuses on meaningful words that could be section names

### Module and Type Specific
- Only searches sections for the detected module (masjid/madrasa)
- Only searches sections for the detected type (income/expenditure)
- Prevents false matches from other categories

### Logging for Debugging
All detection steps are logged:
```
🤖 Processing query: Give me total income from Ali
📋 Parsed intent: { module: 'masjid', type: 'income', section: null, ... }
🎯 Found section match: "Ali" via word "ali"
✨ Dynamic section detected: ali
🔍 SQL Query: SELECT SUM(t.rs) as total FROM masjid_income t LEFT JOIN sections s...
📊 Parameters: ["ali"]
```

## Test Cases

### Test 1: Basic Dynamic Section
```
Query: "Give me total income from Ali"
Expected: Detects "Ali" section, returns sum for Ali only
```

### Test 2: With Year Filter
```
Query: "Total income from Ali in 2025"
Expected: Detects "Ali" section, filters by year 2025
```

### Test 3: Different Module
```
Query: "Show me madrasa income from Zakat"
Expected: Detects "Zakat" in madrasa income
```

### Test 4: Expenditure Type
```
Query: "Total masjid expenditure from Electricity"
Expected: Detects "Electricity" in masjid expenditure
```

### Test 5: No Section (All Sections)
```
Query: "Total masjid income in 2025"
Expected: No section detected, returns total for all sections
```

### Test 6: Multi-Word Section
```
Query: "Give me income from Sadqa Jariya"
Expected: Detects "Sadqa Jariya" as complete section name
```

### Test 7: Case Insensitive
```
Query: "total income from DONATION"
Expected: Detects "donation" regardless of case
```

## Common Words Filtered
The following words are ignored during dynamic detection:
- give, me, total, income, expenditure, expense
- from, of, in, for, the, a, an
- masjid, madrasa, مسجد, مدرسہ
- آمدنی, خرچ, کل

## Database Schema Reference

### Sections Table
```sql
CREATE TABLE sections (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    institution VARCHAR(50) NOT NULL,  -- 'masjid' or 'madrasa'
    type VARCHAR(50) NOT NULL,         -- 'income' or 'expenditure'
    ...
);
```

### Income/Expenditure Tables
```sql
CREATE TABLE masjid_income (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rs NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    section_id INTEGER REFERENCES sections(id),
    ...
);
```

## Testing

### Local Testing
1. Start backend: `npm start` or `node index.js`
2. Run test suite: `node test/testDynamicSections.js`

### Vercel Testing
1. Update `BASE_URL` in `testDynamicSections.js` to your Vercel URL
2. Run: `node test/testDynamicSections.js`

### Manual Testing with curl
```bash
curl -X POST https://your-app.vercel.app/ai-query \
  -H "Content-Type: application/json" \
  -d '{"message": "Give me total income from Ali"}'
```

## Files Modified

### ✅ `backend/index.js`
- Added `detectDynamicSection()` helper function
- Enhanced `/ai-query` endpoint with dynamic detection
- Added comprehensive logging

### ✅ `backend/utils/aiEngine.js`
- Enhanced `detectSection()` with two-pass matching
- Added logging for section detection
- Improved word boundary matching

### ✅ `backend/test/testDynamicSections.js` (NEW)
- Comprehensive test suite for dynamic section detection
- 8 test cases covering various scenarios

## Backward Compatibility
✅ All existing queries continue to work
✅ Fixed keywords still recognized
✅ No breaking changes to API
✅ Existing functionality preserved

## Performance Considerations
- Dynamic detection only runs if initial parsing finds no section
- Single database query per request (when needed)
- Efficient word filtering reduces comparison overhead
- Early return on first match

## Next Steps
1. Deploy updated backend to Vercel
2. Run test suite against production
3. Monitor logs for section detection accuracy
4. Add more common words to filter list if needed
5. Consider caching section names for better performance

## Status: ✅ COMPLETE
Dynamic section detection is fully implemented and ready for deployment. Users can now query any section they create in the database without needing to update backend code.
