import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../db/database_helper.dart';
import '../services/firebase_service.dart';

class StudentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  // Getters
  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  /// Initialize the provider and load data
  Future<void> initialize() async {
    await _loadStudents();
  }

  /// Load students from local database first, then sync with cloud
  Future<void> _loadStudents() async {
    try {
      _setLoading(true);
      _clearError();

      // Load from local database first
      final localData = await _dbHelper.getStudents();
      _students = localData.map((data) => Student.fromMap(data)).toList();
      notifyListeners();

      // Try to sync with cloud if online
      if (_isOnline) {
        await _syncWithCloud();
      }
    } catch (e) {
      _setError('Failed to load students: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync local data with cloud
  Future<void> _syncWithCloud() async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      // Get cloud data
      final cloudDataRaw = await _firebaseService.getStudents();
      final cloudData = cloudDataRaw.map((e) => Student.fromMap(e)).toList();
      
      // Merge cloud data with local data
      final mergedStudents = <Student>[];
      final cloudMap = {for (var s in cloudData) s.id: s};

      // Add all cloud students
      for (final cloudStudent in cloudData) {
        mergedStudents.add(cloudStudent);
      }

      // Add local students not in cloud
      for (final localStudent in _students) {
        if (!cloudMap.containsKey(localStudent.id)) {
          mergedStudents.add(localStudent);
        }
      }

      // Update local database with merged data
      await _updateLocalDatabase(mergedStudents);
      
      _students = mergedStudents;
      notifyListeners();
    } catch (e) {
      // Don't set error for cloud sync failures - local data is still available
    }
  }

  /// Update local database with new data
  Future<void> _updateLocalDatabase(List<Student> students) async {
    await _dbHelper.clearStudents();
    for (final student in students) {
      await _dbHelper.insertStudent(student.toMap());
    }
  }

  /// Fetch students (public method for other services)
  Future<List<Student>> fetchStudents() async {
    if (_students.isEmpty) {
      await _loadStudents();
    }
    return _students;
  }

  /// Add a new student
  Future<void> addStudent(Student student) async {
    try {
      _setLoading(true);
      _clearError();

      // Add to local database first
      final id = await _dbHelper.insertStudent(student.toMap());
      final newStudent = student.copyWith(id: id);
      
      _students.add(newStudent);
      notifyListeners();

      // Try to sync with cloud
      if (_isOnline) {
        try {
          await _firebaseService.addStudent(newStudent.toMap());
        } catch (e) {
          // Student is still saved locally
        }
      }
    } catch (e) {
      _setError('Failed to add student: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing student
  Future<void> updateStudent(Student student) async {
    try {
      _setLoading(true);
      _clearError();

      // Update local database
      await _dbHelper.updateStudent(student.toMap(), student.id!);
      
      // Update in memory
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
        notifyListeners();
      }

      // Try to sync with cloud
      if (_isOnline) {
        try {
          await _firebaseService.updateStudent(student.toMap());
        } catch (e) {
          // Student is still updated locally
        }
      }
    } catch (e) {
      _setError('Failed to update student: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a student
  Future<void> deleteStudent(int id) async {
    try {
      _setLoading(true);
      _clearError();

      // Delete from local database
      await _dbHelper.deleteStudent(id);
      
      // Remove from memory
      _students.removeWhere((s) => s.id == id);
      notifyListeners();

      // Try to sync with cloud
      if (_isOnline) {
        try {
          await _firebaseService.deleteStudent(id.toString());
        } catch (e) {
          // Student is still deleted locally
        }
      }
    } catch (e) {
      _setError('Failed to delete student: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get student by ID
  Student? getStudentById(int id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get students by class ID
  List<Student> getStudentsByClass(int classId) {
    return _students.where((s) => s.classId == classId).toList();
  }

  /// Get students by status
  List<Student> getStudentsByStatus(String status) {
    return _students.where((s) => s.status.toLowerCase() == status.toLowerCase()).toList();
  }

  /// Get students by name (search)
  List<Student> searchStudentsByName(String name) {
    final searchTerm = name.toLowerCase();
    return _students.where((s) => 
      s.name.toLowerCase().contains(searchTerm)
    ).toList();
  }

  /// Get total number of students
  int get totalStudents => _students.length;

  /// Get students count by status
  Map<String, int> get studentsByStatus {
    final counts = <String, int>{};
    for (final student in _students) {
      counts[student.status] = (counts[student.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get students count by class
  Map<String, int> get studentsByClass {
    final counts = <String, int>{};
    for (final student in _students) {
      final className = 'Class ${String.fromCharCode(64 + (student.classId ?? 1))}';
      counts[className] = (counts[className] ?? 0) + 1;
    }
    return counts;
  }

  /// Force refresh data from cloud
  Future<void> refreshFromCloud() async {
    if (!_isOnline) {
      _setError('No internet connection available');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final cloudDataRaw = await _firebaseService.getStudents();
      final cloudData = cloudDataRaw.map((e) => Student.fromMap(e)).toList();
      await _updateLocalDatabase(cloudData);
      
      _students = cloudData;
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh from cloud: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set online/offline status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  /// Clear all data (for logout)
  void clearData() {
    _students.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 