# Screen Files That Need Manual Updates

## Issue
Several screen files use `StreamBuilder` with `SupabaseService().getAdmissionsStream()`. 
Since Neon doesn't support real-time streams, these need to be converted to use `FutureBuilder` or `StatefulWidget` with manual refresh.

## Files Requiring Updates

### 1. lib/screens/students_screen.dart
- Line 90: Uses `StreamBuilder` with `_supabaseService.getAdmissionsStream()`
- Line 190: Uses `_supabaseService.deleteAdmission()`
- Line 195: Uses `_supabaseService.updateAdmission()`
- Line 200: Uses `_supabaseService.updateAdmission()`

**Solution**: Replace `StreamBuilder` with `FutureBuilder` and add manual refresh

### 2. lib/screens/class_students_screen.dart
- Line 93: Uses `StreamBuilder` with `_supabaseService.getAdmissionsStream()`
- Line 269: Uses `_supabaseService.deleteAdmission()`
- Line 281: Uses `_supabaseService.updateAdmission()`
- Line 297: Uses `_supabaseService.updateAdmission()`

**Solution**: Replace `StreamBuilder` with `FutureBuilder` and add manual refresh

### 3. lib/screens/admission_view_screen.dart
- Line 30: Declares `_supabaseService`
- Line 104: Uses `_supabaseService.getAdmissionsPaginated()`
- Line 129: Uses `_supabaseService.updateAdmission()`
- Line 3620: Uses `_supabaseService.deleteAdmission()`

**Solution**: Replace `_supabaseService` with `DatabaseService` static calls

### 4. lib/screens/admission_form_screen.dart
- Line 45: Declares `_supabaseService`
- Line 213: Uses `_supabaseService.updateAdmission()`
- Line 219: Uses `_supabaseService.addAdmission()`

**Solution**: Replace `_supabaseService` with `DatabaseService` static calls

### 5. lib/screens/classes_list_screen.dart
- Line 201: Uses `SupabaseService()` to get students
- Line 294: Uses `SupabaseService()` to get students

**Solution**: Replace with `DatabaseService` static calls

## Conversion Pattern

### From StreamBuilder to FutureBuilder with Refresh

**Before:**
```dart
class _StudentsScreenState extends State<StudentsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabaseService.getAdmissionsStream(),
      builder: (context, snapshot) {
        // ...
      },
    );
  }
}
```

**After:**
```dart
class _StudentsScreenState extends State<StudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await DatabaseService.getAllStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                // Build list items
              },
            ),
    );
  }
}
```

## Quick Fix Commands

Replace all `_supabaseService.` calls with `DatabaseService.`:
- `_supabaseService.getAllStudents()` → `DatabaseService.getAllStudents()`
- `_supabaseService.addAdmission()` → `DatabaseService.addAdmission()`
- `_supabaseService.updateAdmission()` → `DatabaseService.updateAdmission()`
- `_supabaseService.deleteAdmission()` → `DatabaseService.deleteAdmission()`

## Status

- ✅ Imports updated (database_service.dart)
- ⏳ StreamBuilder conversions needed
- ⏳ Instance method calls need to be static

## Next Steps

I'll update these files now with the proper conversions.
