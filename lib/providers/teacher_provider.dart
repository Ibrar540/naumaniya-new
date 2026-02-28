import 'package:flutter/foundation.dart';
import '../models/teacher.dart';
import '../db/database_helper.dart';
import '../services/database_service.dart';

class TeacherProvider extends ChangeNotifier {
  final DatabaseHelper _localDb = DatabaseHelper.instance;
  List<Teacher> _teachers = [];
  bool _isLoading = false;
  String? _error;

  // Always use Neon database (no authentication required)
  bool get isAuthenticated => true;

  // Getters
  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load teachers from database
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
      if (kDebugMode) {
        print('Error loading teachers: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    try {
      await DatabaseService.addTeacher(teacher);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error adding teacher: $e');
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      await DatabaseService.updateTeacher(teacher);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating teacher: $e');
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeacher(dynamic teacherId) async {
    try {
      await DatabaseService.deleteTeacher(teacherId.toString());
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting teacher: $e');
      }
      notifyListeners();
      rethrow;
    }
  }

  // For one-time fetch (not stream)
  Future<List<Teacher>> fetchTeachers() async {
    return await DatabaseService.getAllTeachers();
  }

  Future<void> updateTeacherStatus(int teacherId, String newStatus) async {
    try {
      await DatabaseService.updateTeacherStatus(teacherId, newStatus);
      await loadTeachers(); // Reload to get updated list
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating teacher status: $e');
      }
      notifyListeners();
      rethrow;
    }
  }
}
