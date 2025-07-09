import 'package:flutter/foundation.dart';
import '../services/auto_sync_service.dart';

class AutoSyncProvider extends ChangeNotifier {
  final AutoSyncService _syncService = AutoSyncService();
  
  // Sync state
  bool _isOnline = false;
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0.0;
  Map<String, dynamic> _syncStats = {};

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  double get syncProgress => _syncProgress;
  Map<String, dynamic> get syncStats => _syncStats;

  /// Initialize the auto sync provider
  Future<void> initialize() async {
    // Set up callbacks
    _syncService.onConnectivityChanged = _onConnectivityChanged;
    _syncService.onSyncStatusUpdate = _onSyncStatusUpdate;
    _syncService.onSyncProgress = _onSyncProgress;
    
    // Initialize the service
    await _syncService.initialize();
    
    // Get initial stats
    await _updateSyncStats();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  /// Handle sync status updates
  void _onSyncStatusUpdate(String status) {
    _syncStatus = status;
    notifyListeners();
  }

  /// Handle sync progress updates
  void _onSyncProgress(double progress) {
    _syncProgress = progress;
    notifyListeners();
  }

  /// Update sync statistics
  Future<void> _updateSyncStats() async {
    try {
      _syncStats = await _syncService.getSyncStatistics();
      notifyListeners();
    } catch (e) {
      print('Error updating sync stats: $e');
      _syncStats = {'error': e.toString()};
      notifyListeners();
    }
  }

  /// Force manual sync
  Future<void> forceSync() async {
    await _syncService.forceSync();
    await _updateSyncStats();
  }

  /// Refresh sync statistics
  Future<void> refreshStats() async {
    await _updateSyncStats();
  }

  /// Add pending operation for offline handling
  Future<void> addPendingOperation(String type, Map<String, dynamic> data) async {
    await _syncService.addPendingOperation(type, data);
  }

  /// Get formatted sync status for display
  String get formattedSyncStatus {
    if (_isSyncing) {
      return 'Syncing... ${(_syncProgress * 100).toInt()}%';
    } else if (!_isOnline) {
      return 'Offline - Data will sync when online';
    } else if (_syncStatus.isNotEmpty) {
      return _syncStatus;
    } else {
      return 'Online - Auto sync active';
    }
  }

  /// Get sync status icon
  String get syncStatusIcon {
    if (_isSyncing) {
      return '🔄';
    } else if (!_isOnline) {
      return '📴';
    } else {
      return '✅';
    }
  }

  /// Get sync status color
  int get syncStatusColor {
    if (_isSyncing) {
      return 0xFF2196F3; // Blue
    } else if (!_isOnline) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFF4CAF50; // Green
    }
  }

  /// Check if there are pending operations
  bool get hasPendingOperations {
    final pending = _syncStats['pending_operations'];
    return pending != null && pending > 0;
  }

  /// Get pending operations count
  int get pendingOperationsCount {
    final pending = _syncStats['pending_operations'];
    return (pending is int) ? pending : 0;
  }

  /// Get local data summary
  String get localDataSummary {
    final local = _syncStats['local'] as Map<String, dynamic>? ?? {};
    final students = local['students'] ?? 0;
    final teachers = local['teachers'] ?? 0;
    final income = local['income'] ?? 0;
    final expenditure = local['expenditure'] ?? 0;
    
    return '$students students, $teachers teachers, $income income, $expenditure expenditure';
  }

  /// Get cloud data summary
  String get cloudDataSummary {
    final cloud = _syncStats['cloud'] as Map<String, dynamic>? ?? {};
    final students = cloud['cloud_students'] ?? 0;
    final teachers = cloud['cloud_teachers'] ?? 0;
    final income = cloud['cloud_income'] ?? 0;
    final expenditure = cloud['cloud_expenditure'] ?? 0;
    
    return '$students students, $teachers teachers, $income income, $expenditure expenditure';
  }

  /// Dispose resources
  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
} 