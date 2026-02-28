# Update Providers for Neon Database

## Quick Reference: Replace SupabaseService with DatabaseService

### Search and Replace Pattern

In all provider files, replace:
```dart
import '../services/supabase_service.dart';
final _supabaseService = SupabaseService();
```

With:
```dart
import '../services/database_service.dart';
// DatabaseService is static, no instance needed
```

Then replace all method calls:
```dart
// OLD
await _supabaseService.getAllTeachers();

// NEW
await DatabaseService.getAllTeachers();
```

## Files to Update

### 1. lib/providers/teacher_provider.dart

**Remove streams** (Neon doesn't support real-time):
```dart
// REMOVE THIS
Stream<List<Teacher>> getTeachersStream() {
  return _supabaseService.getTeachersStream();
}
```

**Replace with polling or manual refresh**:
```dart
Future<void> loadTeachers() async {
  try {
    final teachers = await DatabaseService.getAllTeachers();
    // Update your state
    notifyListeners();
  } catch (e) {
    print('Error loading teachers: $e');
  }
}
```

### 2. lib/providers/budget_provider.dart

Same pattern - remove streams, use manual loading:

```dart
// OLD - Remove
Stream<List<Income>> getIncomesStream() {
  return _supabaseService.getIncomesStream();
}

// NEW - Add
Future<void> loadIncomes({String institution = 'madrasa'}) async {
  try {
    final incomes = await DatabaseService.getAllIncomes(institution: institution);
    // Update your state
    notifyListeners();
  } catch (e) {
    print('Error loading incomes: $e');
  }
}
```

### 3. Screen Files

Search your project for `SupabaseService()` and replace with `DatabaseService`.

**Example in students_screen.dart**:
```dart
// OLD
final students = await SupabaseService().getAllStudents();

// NEW
final students = await DatabaseService.getAllStudents();
```

## Handling Real-Time Updates

Since Neon doesn't have real-time subscriptions, use one of these approaches:

### Option 1: Pull-to-Refresh (Recommended)

Add RefreshIndicator to your screens:

```dart
RefreshIndicator(
  onRefresh: () async {
    await loadData();
  },
  child: ListView(...),
)
```

### Option 2: Auto-Refresh with Timer

```dart
Timer? _refreshTimer;

@override
void initState() {
  super.initState();
  loadData();
  
  // Refresh every 30 seconds
  _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    loadData();
  });
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}
```

### Option 3: Manual Refresh Button

```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () => loadData(),
)
```

## Complete Example: Teacher Provider Update

```dart
import 'package:flutter/foundation.dart';
import '../models/teacher.dart';
import '../services/database_service.dart';

class TeacherProvider with ChangeNotifier {
  List<Teacher> _teachers = [];
  bool _isLoading = false;
  String? _error;

  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all teachers
  Future<void> loadTeachers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teachers = await DatabaseService.getAllTeachers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add teacher
  Future<void> addTeacher(Teacher teacher) async {
    try {
      await DatabaseService.addTeacher(teacher);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update teacher
  Future<void> updateTeacher(Teacher teacher) async {
    try {
      await DatabaseService.updateTeacher(teacher);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete teacher
  Future<void> deleteTeacher(String teacherId) async {
    try {
      await DatabaseService.deleteTeacher(teacherId);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update teacher status
  Future<void> updateTeacherStatus(int teacherId, String newStatus) async {
    try {
      await DatabaseService.updateTeacherStatus(teacherId, newStatus);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

## Testing Checklist

After updating providers:

- [ ] App compiles without errors
- [ ] Can load data from Neon
- [ ] Can add new records
- [ ] Can update records
- [ ] Can delete records
- [ ] Error handling works
- [ ] Loading states work
- [ ] Refresh functionality works

## Common Issues

### Issue: "Instance member can't be accessed"
**Solution**: DatabaseService methods are static, don't create an instance:
```dart
// WRONG
final db = DatabaseService();
await db.getAllTeachers();

// CORRECT
await DatabaseService.getAllTeachers();
```

### Issue: "Data not updating in UI"
**Solution**: Call `notifyListeners()` after data changes:
```dart
await DatabaseService.addTeacher(teacher);
await loadTeachers(); // This should call notifyListeners()
```

### Issue: "Connection timeout"
**Solution**: Check Neon database is active (not paused) in Neon Console.

---

**Next Step**: After updating providers, test each screen thoroughly!
