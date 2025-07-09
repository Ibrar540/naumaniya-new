import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';

class FirestoreDataProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  List<Income> _incomes = [];
  List<Expenditure> _expenditures = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Student> get students => _students;
  List<Teacher> get teachers => _teachers;
  List<Income> get incomes => _incomes;
  List<Expenditure> get expenditures => _expenditures;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize and listen to data changes
  void initialize() {
    if (!_firebaseService.isAuthenticated) return;
    
    // Listen to students
    _firebaseService.getStudentsStream().listen((data) {
      _students = data.map((map) => Student.fromMap(map)).toList();
      notifyListeners();
    });

    // Listen to teachers
    _firebaseService.getTeachersStream().listen((data) {
      _teachers = data.map((map) => Teacher.fromMap(map)).toList();
      notifyListeners();
    });

    // Listen to income
    _firebaseService.getIncomeStream().listen((data) {
      _incomes = data.map((map) => Income.fromMap(map)).toList();
      notifyListeners();
    });

    // Listen to expenditure
    _firebaseService.getExpenditureStream().listen((data) {
      _expenditures = data.map((map) => Expenditure.fromMap(map)).toList();
      notifyListeners();
    });
  }

  // Student operations
  Future<void> addStudent(Student student) async {
    try {
      _setLoading(true);
      await _firebaseService.syncStudents([student.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      _setLoading(true);
      await _firebaseService.syncStudents([student.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteStudent(int studentId) async {
    try {
      _setLoading(true);
      // Remove from local list first
      _students.removeWhere((s) => s.id == studentId);
      notifyListeners();
      
      // Sync the updated list
      await _firebaseService.syncStudents(_students.map((s) => s.toMap()).toList());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Teacher operations
  Future<void> addTeacher(Teacher teacher) async {
    try {
      _setLoading(true);
      await _firebaseService.syncTeachers([teacher.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      _setLoading(true);
      await _firebaseService.syncTeachers([teacher.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTeacher(int teacherId) async {
    try {
      _setLoading(true);
      // Remove from local list first
      _teachers.removeWhere((t) => t.id == teacherId);
      notifyListeners();
      
      // Sync the updated list
      await _firebaseService.syncTeachers(_teachers.map((t) => t.toMap()).toList());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Income operations
  Future<void> addIncome(Income income) async {
    try {
      _setLoading(true);
      await _firebaseService.syncIncome([income.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      _setLoading(true);
      await _firebaseService.syncIncome([income.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteIncome(int incomeId) async {
    try {
      _setLoading(true);
      // Remove from local list first
      _incomes.removeWhere((i) => i.id == incomeId);
      notifyListeners();
      
      // Sync the updated list
      await _firebaseService.syncIncome(_incomes.map((i) => i.toMap()).toList());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Expenditure operations
  Future<void> addExpenditure(Expenditure expenditure) async {
    try {
      _setLoading(true);
      await _firebaseService.syncExpenditure([expenditure.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpenditure(Expenditure expenditure) async {
    try {
      _setLoading(true);
      await _firebaseService.syncExpenditure([expenditure.toMap()]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpenditure(int expenditureId) async {
    try {
      _setLoading(true);
      // Remove from local list first
      _expenditures.removeWhere((e) => e.id == expenditureId);
      notifyListeners();
      
      // Sync the updated list
      await _firebaseService.syncExpenditure(_expenditures.map((e) => e.toMap()).toList());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Backup and restore
  Future<Map<String, dynamic>> createBackup() async {
    try {
      _setLoading(true);
      final backup = await _firebaseService.createBackup();
      _setError(null);
      return backup;
    } catch (e) {
      _setError(e.toString());
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    try {
      _setLoading(true);
      await _firebaseService.restoreBackup(backup);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }
} 