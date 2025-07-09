import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../providers/cloud_data_provider.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/section.dart';
import '../models/class_model.dart';

class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  final DatabaseHelper _localDb = DatabaseHelper();
  final CloudDataProvider _cloudProvider = CloudDataProvider();
  
  // Sync status
  bool _isOnline = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Callbacks
  Function(bool)? onConnectivityChanged;
  Function(String)? onSyncStatusUpdate;
  Function(double)? onSyncProgress;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize auto-sync service
  Future<void> initialize() async {
    await _checkConnectivity();
    _setupConnectivityListener();
    _startPeriodicSync();
    
    // Initial sync if online
    if (_isOnline) {
      await _performInitialSync();
    }
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final wasOnline = _isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      
      if (onConnectivityChanged != null) {
        onConnectivityChanged!(_isOnline);
      }

      // Handle connectivity change
      if (!wasOnline && _isOnline) {
        // Came online - sync pending data
        _updateSyncStatus('Connection restored. Syncing pending data...');
        await _syncPendingData();
      } else if (wasOnline && !_isOnline) {
        // Went offline
        _updateSyncStatus('Connection lost. Data will be synced when online.');
      }
    });
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isOnline && !_isSyncing) {
        await _performBackgroundSync();
      }
    });
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    _isOnline = connectivityResults.any((result) => result != ConnectivityResult.none);
  }

  /// Perform initial sync when app starts
  Future<void> _performInitialSync() async {
    if (!_isOnline) return;

    try {
      _updateSyncStatus('Performing initial sync...');
      
      // Check if user is authenticated
      if (!_cloudProvider.isAuthenticated) {
        _updateSyncStatus('User not authenticated. Sync will start after login.');
        return;
      }

      // Sync all data types
      await _syncAllData();
      
      _updateSyncStatus('Initial sync completed successfully.');
    } catch (e) {
      _updateSyncStatus('Initial sync failed: ${e.toString()}');
    }
  }

  /// Sync pending data when coming online
  Future<void> _syncPendingData() async {
    if (!_isOnline || _isSyncing) return;

    try {
      _isSyncing = true;
      _updateSyncStatus('Syncing pending data...');

      // Get pending operations from local storage
      final pendingOps = await _getPendingOperations();
      
      if (pendingOps.isEmpty) {
        _updateSyncStatus('No pending data to sync.');
        return;
      }

      // Process pending operations
      for (int i = 0; i < pendingOps.length; i++) {
        final op = pendingOps[i];
        await _processPendingOperation(op);
        
        // Update progress
        final progress = (i + 1) / pendingOps.length;
        if (onSyncProgress != null) {
          onSyncProgress!(progress);
        }
      }

      // Clear pending operations
      await _clearPendingOperations();
      
      _updateSyncStatus('Pending data synced successfully.');
    } catch (e) {
      _updateSyncStatus('Sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    if (!_isOnline || _isSyncing) return;

    try {
      _isSyncing = true;
      
      // Sync in background without user notification
      await _syncAllData();
    } catch (e) {
      print('Background sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync all data
  Future<void> forceSync() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      _updateSyncStatus('Force syncing all data...');
      
      await _syncAllData();
      
      _updateSyncStatus('Force sync completed successfully.');
    } catch (e) {
      _updateSyncStatus('Force sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final localStats = await _localDb.getDataStatistics();
      final cloudStats = await _cloudProvider.getDataStatistics();
      
      return {
        'local': localStats,
        'cloud': cloudStats,
        'is_online': _isOnline,
        'is_syncing': _isSyncing,
        'last_sync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'is_online': _isOnline,
        'is_syncing': _isSyncing,
      };
    }
  }

  /// Sync all data types
  Future<void> _syncAllData() async {
    if (!_isOnline || !_cloudProvider.isAuthenticated) return;

    try {
      // Sync students
      await _syncStudents();
      
      // Sync teachers
      await _syncTeachers();
      
      // Sync income
      await _syncIncome();
      
      // Sync expenditure
      await _syncExpenditure();
      
      // Sync sections
      await _syncSections();
      
      // Sync classes
      await _syncClasses();
      
    } catch (e) {
      throw Exception('Data sync failed: ${e.toString()}');
    }
  }

  /// Sync students data
  Future<void> _syncStudents() async {
    try {
      final localStudents = (await _localDb.getStudents()).where((s) => s['pending_sync'] == 1).toList();
      if (localStudents.isEmpty) return;
      for (final localStudent in localStudents) {
        final student = Student.fromMap(localStudent);
        await _cloudProvider.addStudent(student);
        await _localDb.deleteStudent(localStudent['id']);
      }
    } catch (e) {
      print('Error syncing students: $e');
    }
  }

  /// Sync teachers data
  Future<void> _syncTeachers() async {
    try {
      final localTeachers = (await _localDb.getTeachers()).where((t) => t['pending_sync'] == 1).toList();
      if (localTeachers.isEmpty) return;
      for (final localTeacher in localTeachers) {
        final teacher = Teacher.fromMap(localTeacher);
        await _cloudProvider.addTeacher(teacher);
        await _localDb.deleteTeacher(localTeacher['id']);
      }
    } catch (e) {
      print('Error syncing teachers: $e');
    }
  }

  /// Sync income data
  Future<void> _syncIncome() async {
    try {
      final localIncome = (await _localDb.getIncome()).where((i) => i['pending_sync'] == 1).toList();
      if (localIncome.isEmpty) return;
      for (final localInc in localIncome) {
        final income = Income.fromMap(localInc);
        await _cloudProvider.addIncome(income);
        await _localDb.deleteIncome(localInc['id']);
      }
    } catch (e) {
      print('Error syncing income: $e');
    }
  }

  /// Sync expenditure data
  Future<void> _syncExpenditure() async {
    try {
      final localExpenditure = (await _localDb.getExpenditure()).where((e) => e['pending_sync'] == 1).toList();
      if (localExpenditure.isEmpty) return;
      for (final localExp in localExpenditure) {
        final expenditure = Expenditure.fromMap(localExp);
        await _cloudProvider.addExpenditure(expenditure);
        await _localDb.deleteExpenditure(localExp['id']);
      }
    } catch (e) {
      print('Error syncing expenditure: $e');
    }
  }

  /// Sync sections data
  Future<void> _syncSections() async {
    try {
      final localSections = (await _localDb.getSections()).where((s) => s['pending_sync'] == 1).toList();
      if (localSections.isEmpty) return;
      for (final localSection in localSections) {
        final section = Section.fromMap(localSection);
        await _cloudProvider.addSection(section);
        await _localDb.deleteSection(localSection['id']);
      }
    } catch (e) {
      print('Error syncing sections: $e');
    }
  }

  /// Sync classes data
  Future<void> _syncClasses() async {
    try {
      final localClasses = (await _localDb.getClasses()).where((c) => c['pending_sync'] == 1).toList();
      if (localClasses.isEmpty) return;
      for (final localClass in localClasses) {
        final classModel = ClassModel.fromMap(localClass);
        await _cloudProvider.addClass(classModel);
        await _localDb.deleteClass(localClass['id']);
      }
    } catch (e) {
      print('Error syncing classes: $e');
    }
  }

  /// Get pending operations from local storage
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString('pending_operations');
      if (pendingData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(pendingData));
      }
    } catch (e) {
      print('Error getting pending operations: $e');
    }
    return [];
  }

  /// Process a pending operation
  Future<void> _processPendingOperation(Map<String, dynamic> operation) async {
    try {
      final type = operation['type'] as String;
      final data = operation['data'] as Map<String, dynamic>;
      
      switch (type) {
        case 'add_student':
          final student = Student.fromMap(data);
          await _cloudProvider.addStudent(student);
          break;
        case 'add_teacher':
          final teacher = Teacher.fromMap(data);
          await _cloudProvider.addTeacher(teacher);
          break;
        case 'add_income':
          final income = Income.fromMap(data);
          await _cloudProvider.addIncome(income);
          break;
        case 'add_expenditure':
          final expenditure = Expenditure.fromMap(data);
          await _cloudProvider.addExpenditure(expenditure);
          break;
        case 'add_section':
          final section = Section.fromMap(data);
          await _cloudProvider.addSection(section);
          break;
        case 'add_class':
          final classModel = ClassModel.fromMap(data);
          await _cloudProvider.addClass(classModel);
          break;
      }
    } catch (e) {
      print('Error processing pending operation: $e');
    }
  }

  /// Clear pending operations
  Future<void> _clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_operations');
    } catch (e) {
      print('Error clearing pending operations: $e');
    }
  }

  /// Add operation to pending queue
  Future<void> addPendingOperation(String type, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOps = await _getPendingOperations();
      
      pendingOps.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString('pending_operations', jsonEncode(pendingOps));
    } catch (e) {
      print('Error adding pending operation: $e');
    }
  }

  /// Update sync status
  void _updateSyncStatus(String status) {
    if (onSyncStatusUpdate != null) {
      onSyncStatusUpdate!(status);
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
} 