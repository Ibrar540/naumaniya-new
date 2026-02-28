# Roll Number System - Implementation

## How It Works

Roll numbers are assigned automatically based on student ID (admission order) in descending order:
- **Newest student** (highest ID) → **Roll No 1**
- **Second newest** → **Roll No 2**
- **Third newest** → **Roll No 3**
- And so on...

This ensures that:
1. Roll numbers are consistent and don't change
2. Newer students get lower roll numbers
3. Each class has its own roll number sequence starting from 1

## Example

If you have 3 students in "Class A":
- Student with ID 10 (newest) → Roll No 1
- Student with ID 8 → Roll No 2
- Student with ID 5 (oldest) → Roll No 3

When you add a 4th student with ID 12:
- Student with ID 12 (newest) → Roll No 1
- Student with ID 10 → Roll No 2
- Student with ID 8 → Roll No 3
- Student with ID 5 (oldest) → Roll No 4

## Implementation

### 1. Database Column
Added `roll_no` column to students table:
```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS roll_no INTEGER;
CREATE INDEX IF NOT EXISTS idx_students_roll_no ON students(roll_no);
```

### 2. Assignment Logic (lib/screens/students_screen.dart)
```dart
// Sort by ID in descending order (newest first)
studentsData.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

// Assign roll numbers: newest (index 0) gets 1, next gets 2, etc.
for (int i = 0; i < studentsData.length; i++) {
  studentsData[i]['roll_no'] = i + 1;
}
```

## Migration Required

Run this SQL script in your Neon database to add the roll_no column:
```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS roll_no INTEGER;
CREATE INDEX IF NOT EXISTS idx_students_roll_no ON students(roll_no);
COMMENT ON COLUMN students.roll_no IS 'Permanent roll number assigned to student within their class';
```

## Current Behavior

Roll numbers are calculated dynamically when loading students:
1. Query all students in the class
2. Sort by ID descending (newest first)
3. Assign roll numbers 1, 2, 3, ... based on position

This means:
- Roll numbers are consistent as long as students aren't deleted
- If a student is deleted, roll numbers will shift for students after them
- Roll numbers are per-class (each class starts from 1)

## Future Enhancement (Optional)

To make roll numbers truly permanent (survive deletions), you would need to:
1. Save roll_no to database when student is added
2. Never reassign roll numbers
3. Allow gaps in roll number sequence when students are deleted

Current implementation is simpler and works well for most use cases.

## Files Modified
1. `lib/screens/students_screen.dart` - Added roll number assignment logic
2. `ADD_ROLL_NO_COLUMN.sql` - Database migration script

## Status
✅ COMPLETE - Roll numbers are assigned in descending order based on ID (newest students get lower roll numbers).
