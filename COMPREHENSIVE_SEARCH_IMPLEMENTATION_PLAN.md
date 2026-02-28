# Comprehensive Search Implementation Plan

## ✅ COMPLETED: Admission Office
- Full Urdu/English support for all operators
- ID search (>, <, between, multiple)
- Fee search (>, <, between, with/without)
- Date search (after, before, between, specific)
- Status search (active, graduate, struck off)
- Class search
- Name search
- All comparison operators working

## 🔄 TO IMPLEMENT:

### 1. Teachers Screen (HIGH PRIORITY)
**Current**: Basic text search (name, mobile, status, ID)
**Needed**:
- **ID Search**: `آئی ڈی 5 سے زیادہ`, `ID > 5`, `between 1 and 10`
- **Salary Search**: `تنخواہ 50000 سے زیادہ`, `salary > 50000`, `between 30000 and 60000`
- **Date Search**: 
  - Starting date: `سال 2020 کے بعد شروع`, `started after 2020`
  - Leaving date: `سال 2023 میں چھوڑا`, `left in 2023`
- **Status Search**: `فعال اساتذہ`, `active teachers`, `سابق اساتذہ`, `former teachers`
- **Name Search**: Urdu/English names
- **Mobile Search**: Full/partial number

### 2. Budget Management Screen (MEDIUM PRIORITY)
**Current**: Basic search with month/year support
**Needed**:
- **Amount Search**: `رقم 1000 سے زیادہ`, `amount > 1000`, `between 500 and 2000`
- **Date Search**: `جنوری 2024`, `January 2024`, `سال 2023 سے 2024 تک`
- **Description Search**: Urdu/English text
- **Section Search**: By section name

### 3. Section Data Screen (MEDIUM PRIORITY)
**Current**: Basic search (description, amount, date)
**Needed**:
- **Amount Search**: `رقم 500 سے کم`, `amount < 500`, `between 100 and 1000`
- **Date Search**: `جنوری میں`, `in January`, `سال 2024`
- **Description Search**: Better Urdu support

### 4. Classes List Screen (LOW PRIORITY)
**Current**: Basic name search
**Needed**:
- **Class Name Search**: Urdu/English
- **Status Search**: `فعال کلاسیں`, `active classes`
- **Student Count**: `10 سے زیادہ طلباء`, `more than 10 students`

### 5. Students Screen (LOW PRIORITY)
**Current**: Basic search (ID, name, father, status, date)
**Needed**:
- Similar to Admission Office but simpler
- Focus on active students only

## Implementation Priority:
1. **Teachers Screen** - Most used after admissions
2. **Budget Management** - Financial data needs good search
3. **Section Data** - Part of budget system
4. **Classes List** - Less critical
5. **Students Screen** - Already has admission office

## Key Urdu Operators to Implement:
- `سے زیادہ` / `سے بڑا` (greater than)
- `سے کم` / `سے چھوٹا` (less than)
- `سے ... تک` (from...to)
- `درمیان ... اور` (between...and)
- `کے بعد` (after)
- `سے پہلے` (before)
- `فعال` (active)
- `سابق` / `غیر فعال` (former/inactive)

## Next Steps:
1. Implement Teachers Screen comprehensive search
2. Test all operators in Urdu and English
3. Move to Budget Management
4. Continue with remaining modules
