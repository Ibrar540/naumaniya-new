# Intelligent Search System Test Examples

## ✅ Struck-Off Date Search Examples

### Urdu Examples:
1. **"سال 2024 کے اخراج شدہ طلبہ"** → Finds all students struck off in 2024
   - Suggestions: "سال 2024 کے اخراج شدہ طلبہ", "سال 2024 سے 2025 تک اخراج کا ریکارڈ", "سال 2024 میں خارج ہونے والے طلبہ"

2. **"مہینہ جون سال 2023 کے اخراج شدہ طلبہ"** → Finds students struck off in June 2023
   - Suggestions: "مہینہ جون سال 2023 کے اخراج شدہ طلبہ", "سال 2023 میں جون کے خارج شدہ طلبہ", "جون 2023 میں اخراج شدہ طلبہ"

3. **"تاریخ 5 سال 2024 کے اخراج شدہ طلبہ"** → Finds students struck off on day 5 of 2024
   - Suggestions: "تاریخ 5 سال 2024 کے اخراج شدہ طلبہ", "سال 2024 میں 5 تاریخ کے خارج شدہ طلبہ", "5/2024 کے اخراج شدہ طلبہ"

4. **"سال 2020 سے 2025 تک اخراج شدہ طلبہ"** → Range search 2020-2025
   - Suggestions: "سال 2020 سے 2025 تک اخراج شدہ طلبہ", "سال 2020 سے 2025 تک خارج شدہ طلبہ", "سال 2020 سے اب تک اخراج کا ریکارڈ"

5. **"اخراج 2024"** → Simple query for 2024 struck-off students
   - Suggestions: "سال 2024 کے اخراج شدہ طلبہ", "سال 2024 سے 2025 تک اخراج کا ریکارڈ", "سال 2024 میں خارج ہونے والے طلبہ"

### English Examples:
1. **"struck off in 2024"** → Finds all students struck off in 2024
   - Suggestions: "struck off in 2024", "struck off from 2024 to 2025", "students expelled in 2024"

2. **"expelled in june 2023"** → Finds students expelled in June 2023
   - Suggestions: "struck off in june 2023", "students expelled in june 2023", "struck off from june 2023"

3. **"struck off from 2020 to 2025"** → Range search
   - Suggestions: "struck off from 2020 to 2025", "expelled from 2020 to 2025", "struck off from 2020 onwards"

### Mixed Language Examples:
1. **"struck off 2024 میں"** → Mixed Urdu-English
2. **"2024 اخراج"** → Year with Urdu keyword
3. **"stuck off 2024"** → Handles typos (stuck → struck)

## ✅ Admission Date Search Examples

### Urdu Examples:
1. **"سال 2024 میں داخل ہونے والے طلبہ"** → Students admitted in 2024
2. **"مہینہ جون سال 2023 کے داخلے"** → Admissions in June 2023
3. **"تاریخ 5 سال 2024 والے داخلے"** → Admissions on day 5 of 2024
4. **"سال 2020 سے 2025 تک داخلے"** → Admission range 2020-2025
5. **"داخلہ 2024"** → Simple admission query for 2024

### English Examples:
1. **"admitted in 2024"** → Students admitted in 2024
2. **"admissions in june 2023"** → June 2023 admissions
3. **"admission from 2020 to 2025"** → Admission range

## ✅ Graduation Date Search Examples

### Urdu Examples:
1. **"سال 2024 کے فارغ التحصیل طلبہ"** → Students graduated in 2024
2. **"فراغت 2024"** → Simple graduation query
3. **"گریجویٹ 2023"** → Graduate students from 2023

### English Examples:
1. **"graduated in 2024"** → Students graduated in 2024
2. **"graduation 2023"** → Graduation records from 2023

## ✅ Class Search Examples (NEW)

### Urdu Examples:
1. **"جماعت A والے طلبہ"** → All students in class A
   - Suggestions: "جماعت A والے طلبہ", "جماعت A کے فعال طلبہ", "جماعت A اور B والے طلبہ"

2. **"جماعت A کے فعال طلبہ"** → Active students in class A
   - Suggestions: "جماعت A کے فعال طلبہ", "جماعت A کے فعال اور باقی فیس والے طلبہ", "جماعت A کے تمام فعال طلبہ"

3. **"جماعت A اور B والے طلبہ"** → Students in class A and B
   - Suggestions: "جماعت A اور B والے طلبہ", "جماعت A اور B کے فعال طلبہ", "جماعت A اور B کے تمام طلبہ"

4. **"جماعت A کے اخراج شدہ طلبہ"** → Struck-off students from class A
   - Suggestions: "جماعت A کے اخراج شدہ طلبہ", "جماعت A کے خارج شدہ طلبہ", "جماعت A کے تمام اخراج شدہ طلبہ"

5. **"جماعت A کے فارغ طلبہ"** → Graduated students from class A
   - Suggestions: "جماعت A کے فارغ طلبہ", "جماعت A کے فارغ التحصیل طلبہ", "جماعت A کے گریجویٹ طلبہ"

6. **"جماعت A"** → Simple class A query
   - Suggestions: "جماعت A والے طلبہ", "جماعت A کے فعال طلبہ", "جماعت A اور B والے طلبہ"

7. **"A جماعت"** → Alternative format for class A
   - Suggestions: "جماعت A والے طلبہ", "جماعت A کے فعال طلبہ", "جماعت A اور B والے طلبہ"

### English Examples:
1. **"class A students"** → All students in class A
   - Suggestions: "class A students", "class A active students", "class A and B students"

2. **"class A active students"** → Active students in class A
   - Suggestions: "class A active students", "active students from class A", "class A active with pending fees"

3. **"class A and B students"** → Students in class A and B
   - Suggestions: "class A and B students", "students from class A and B", "class A and B active students"

4. **"class A struck off students"** → Struck-off students from class A
   - Suggestions: "class A struck off students", "struck off students from class A", "class A expelled students"

### Mixed Language Examples:
1. **"class A طلبہ"** → Mixed English-Urdu
2. **"جماعت A students"** → Mixed Urdu-English
3. **"jamart A"** → Handles typos (jamart → جماعت)

### Dynamic Suggestion Examples:
- **User types "جماعت A ف"** → Suggestions focus on "ف" patterns: "فعال طلبہ", "فارغ طلبہ", "فیس باقی"
- **User types "جماعت A ا"** → Suggestions focus on "ا" patterns: "اخراج شدہ طلبہ", "اور B والے طلبہ"
- **User types "جماعت A کے"** → Suggestions focus on possession patterns: "کے فعال طلبہ", "کے اخراج شدہ طلبہ"

## ✅ Fee Search Examples (NEW)

### Urdu Examples:
1. **"فیس والے طلبہ"** → All students with fee > 0
   - Suggestions: "فیس والے طلبہ کا ریکارڈ", "فیس والے تمام طلبہ", "فیس والے فعال طلبہ"

2. **"بغیر فیس والے طلبہ"** → All students with fee = 0
   - Suggestions: "بغیر فیس والے طلبہ کا ریکارڈ", "بغیر فیس والے تمام طلبہ", "فیس نہیں والے طلبہ کی فہرست"

3. **"فیس 200 سے زیادہ"** → Students with fee > 200
   - Suggestions: "فیس 200 سے زیادہ والے طلبہ", "فیس 200 سے زیادہ کا ریکارڈ", "فیس 200 سے اوپر والے طلبہ کی فہرست"

4. **"فیس 500 سے کم"** → Students with fee < 500
   - Suggestions: "فیس 500 سے کم والے طلبہ", "فیس 500 سے کم کا ریکارڈ", "فیس 500 سے نیچے والے طلبہ کی فہرست"

5. **"فیس 300"** → Students with exact fee = 300
   - Suggestions: "فیس 300 والے طلبہ", "فیس 300 سے زیادہ والے طلبہ", "فیس 300 سے کم والے طلبہ"

### English Examples:
1. **"students with fee"** → All students with fee > 0
   - Suggestions: "students with fee records", "all students with fee", "active students with fee"

2. **"students without fee"** → All students with fee = 0
   - Suggestions: "students without fee records", "all students without fee", "students with no fee"

3. **"fee greater than 200"** → Students with fee > 200
   - Suggestions: "students with fee greater than 200", "fee greater than 200 records", "all students with fee above 200"

4. **"fee less than 500"** → Students with fee < 500
   - Suggestions: "students with fee less than 500", "fee less than 500 records", "all students with fee below 500"

### Mixed Language Examples:
1. **"fee والے طلبہ"** → Mixed English-Urdu
2. **"فیس greater than 200"** → Mixed Urdu-English
3. **"fess 500 km"** → Handles typos (fess → fee, km → کم)

### Dynamic Suggestion Examples:
- **User types "فیس و"** → Suggestions focus on "والے" patterns: "فیس والے طلبہ", "فیس والے طلبہ کا ریکارڈ"
- **User types "200 سے"** → Suggestions focus on comparison patterns: "فیس 200 سے زیادہ", "فیس 200 سے کم"
- **User types "بغیر"** → Suggestions focus on "without fee" patterns: "بغیر فیس والے طلبہ"

## ✅ Name Search Examples (NEW)

### Urdu Examples:
1. **"علی"** → All students with name or father name containing "علی"
   - Suggestions: "علی نام والے طلبہ", "علی خان جیسے نام والے طلبہ", "علی کے نام سے ملتے جلتے طلبہ"

2. **"احمد رضا"** → Students with name or father name containing "احمد رضا"
   - Suggestions: "احمد رضا نام والے طلبہ", "احمد رضا کے نام سے ملتے جلتے طلبہ", "احمد رضا جیسے مکمل نام والے طلبہ"

3. **"ع"** → Single letter search for names starting with "ع"
   - Suggestions: "ع سے شروع ہونے والے طلبہ", "ع نام والے طلبہ کا ریکارڈ", "ع کے مشابہ نام والے طلبہ"

4. **"فی"** → Short input search for names containing "فی"
   - Suggestions: "فی سے شروع ہونے والے نام", "فی والے طلبہ کا ریکارڈ", "فی کے مشابہ نام والے طلبہ"

### English Examples:
1. **"Hassan"** → All students with name or father name containing "Hassan"
   - Suggestions: "students named Hassan", "Hassan Ali type names", "students with Hassan similar names"

2. **"Hassan Ali"** → Students with full name "Hassan Ali"
   - Suggestions: "students named Hassan Ali", "Hassan Ali exact name matches", "students with Hassan Ali similar names"

3. **"A"** → Single letter search for names starting with "A"
   - Suggestions: "students with names starting with A", "all A names records", "students with A similar names"

4. **"AL"** → Short input search for names starting with "AL"
   - Suggestions: "names starting with AL", "students with AL names", "AL similar name records"

### Mixed Language Examples:
1. **"Ali 2024"** → Mixed name and year search (prioritizes name)
   - Suggestions: "Ali نام والے طلبہ", "Ali کے نام سے ملتے جلتے طلبہ", "Ali جیسے نام والے طلبہ کا ریکارڈ"

2. **"Hassan طلبہ"** → Mixed English-Urdu
3. **"علی students"** → Mixed Urdu-English

### Typo Tolerance Examples:
1. **"Alee"** → Matches "Ali" (typo tolerance)
2. **"Alii"** → Matches "Ali" (extra character)
3. **"Hasssan"** → Matches "Hassan" (double character)
4. **"Ahmd"** → Matches "Ahmad" (missing character)
5. **"Ale"** → Matches "Ali" (incomplete)

### Dynamic Suggestion Examples:
- **User types "A"** → Suggestions focus on single letter: "A سے شروع ہونے والے طلبہ"
- **User types "Ali"** → Suggestions focus on full name: "Ali نام والے طلبہ"
- **User types "Ahmad R"** → Suggestions adapt to partial full name

## ✅ ID Search Examples (Existing)

1. **"آئی ڈی 7"** → Student with ID 7
2. **"ID 7 to 20"** → Students with IDs from 7 to 20
3. **"students with id 2 and 5"** → Students with IDs 2 and 5

## 🧠 Smart Features

### Google-like Intelligence:
- **Context Understanding**: Automatically detects search type (ID, admission date, struck-off date, graduation date)
- **Typo Tolerance**: Handles misspellings like "admision" → "admission", "stuck off" → "struck off"
- **Mixed Language**: Processes Urdu/English seamlessly
- **Dynamic Suggestions**: Changes suggestions as user types
- **Learning System**: Improves based on user selections

### Real-time Suggestions:
- Always shows exactly 3 suggestions
- Never repeats user's exact input
- Preserves user's starting text and extends naturally
- Updates live as user continues typing
- Sorted by popularity (Google-like learning)

## 🎯 Search Priority Order:
1. **ID Search** - Highest priority for ID-related queries
2. **Admission Date Search** - For admission date queries
3. **Struck-Off Date Search** - For struck-off date queries  
4. **Graduation Date Search** - For graduation date queries
5. **Class Search** - For class-based queries
6. **Fee Search** - For fee-based queries
7. **Name Search** - For name-based queries (NEW)
8. **Default Suggestions** - Fallback suggestions

This comprehensive search system provides a modern, intelligent search experience similar to Google for the admission management system.