import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  FirebaseFirestore get firestore => _firestore;

  // Initialize Firebase
  Future<void> initialize() async {
    // Firebase is already initialized in main.dart, so we don't need to initialize again
    // This method is kept for compatibility but does nothing
  }

  // Authentication Methods
  Future<UserCredential> signUp(String email, String password, String institutionName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'institutionName': institutionName,
        'role': 'creator',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Create account settings
      await _firestore.collection('accounts').doc(userCredential.user!.uid).set({
        'creatorId': userCredential.user!.uid,
        'institutionName': institutionName,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedDevices': [],
        'pendingDevices': [],
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check device approval
      await _checkDeviceApproval(userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Device Management
  Future<String> getDeviceId() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return 'web_${webInfo.userAgent.hashCode}';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return 'android_${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return 'ios_${iosInfo.identifierForVendor}';
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    String deviceName = 'Unknown Device';
    String platform = 'Unknown';

    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      deviceName = '${webInfo.browserName.name} on ${webInfo.platform}';
      platform = 'Web';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
      platform = 'Android';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceName = '${iosInfo.name} ${iosInfo.model}';
      platform = 'iOS';
    }

    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _checkDeviceApproval(String userId) async {
    final deviceInfo = await getDeviceInfo();
    final deviceId = deviceInfo['deviceId'];

    final accountDoc = await _firestore.collection('accounts').doc(userId).get();
    if (!accountDoc.exists) return;

    final accountData = accountDoc.data()!;
    final approvedDevices = List<String>.from(accountData['approvedDevices'] ?? []);
    final pendingDevices = List<Map<String, dynamic>>.from(accountData['pendingDevices'] ?? []);

    // Check if device is already approved
    if (approvedDevices.contains(deviceId)) {
      // Update last login time
      await _firestore.collection('accounts').doc(userId).update({
        'approvedDevices': approvedDevices,
      });
      return;
    }

    // Check if device is already pending
    final isPending = pendingDevices.any((device) => device['deviceId'] == deviceId);
    if (isPending) {
      throw Exception('Device access request is pending approval');
    }

    // Add device to pending list
    pendingDevices.add(deviceInfo);
    await _firestore.collection('accounts').doc(userId).update({
      'pendingDevices': pendingDevices,
    });

    throw Exception('Device access request sent. Please wait for approval.');
  }

  // Device Approval Management
  Future<List<Map<String, dynamic>>> getPendingDevices() async {
    if (!isAuthenticated) return [];

    final accountDoc = await _firestore.collection('accounts').doc(currentUser!.uid).get();
    if (!accountDoc.exists) return [];

    final accountData = accountDoc.data()!;
    return List<Map<String, dynamic>>.from(accountData['pendingDevices'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getApprovedDevices() async {
    if (!isAuthenticated) return [];

    final accountDoc = await _firestore.collection('accounts').doc(currentUser!.uid).get();
    if (!accountDoc.exists) return [];

    final accountData = accountDoc.data()!;
    final approvedDeviceIds = List<String>.from(accountData['approvedDevices'] ?? []);
    
    List<Map<String, dynamic>> approvedDevices = [];
    for (String deviceId in approvedDeviceIds) {
      final deviceDoc = await _firestore.collection('devices').doc(deviceId).get();
      if (deviceDoc.exists) {
        approvedDevices.add(deviceDoc.data()!);
      }
    }

    return approvedDevices;
  }

  Future<void> approveDevice(String deviceId) async {
    if (!isAuthenticated) return;

    final accountRef = _firestore.collection('accounts').doc(currentUser!.uid);
    final accountDoc = await accountRef.get();
    
    if (!accountDoc.exists) return;

    final accountData = accountDoc.data()!;
    final pendingDevices = List<Map<String, dynamic>>.from(accountData['pendingDevices'] ?? []);
    final approvedDevices = List<String>.from(accountData['approvedDevices'] ?? []);

    // Find the device in pending list
    final deviceIndex = pendingDevices.indexWhere((device) => device['deviceId'] == deviceId);
    if (deviceIndex == -1) return;

    final deviceInfo = pendingDevices[deviceIndex];
    pendingDevices.removeAt(deviceIndex);
    approvedDevices.add(deviceId);

    // Save device info to devices collection
    await _firestore.collection('devices').doc(deviceId).set(deviceInfo);

    // Update account
    await accountRef.update({
      'pendingDevices': pendingDevices,
      'approvedDevices': approvedDevices,
    });
  }

  Future<void> revokeDevice(String deviceId) async {
    if (!isAuthenticated) return;

    final accountRef = _firestore.collection('accounts').doc(currentUser!.uid);
    final accountDoc = await accountRef.get();
    
    if (!accountDoc.exists) return;

    final accountData = accountDoc.data()!;
    final approvedDevices = List<String>.from(accountData['approvedDevices'] ?? []);

    approvedDevices.remove(deviceId);

    await accountRef.update({
      'approvedDevices': approvedDevices,
    });

    // Remove device from devices collection
    await _firestore.collection('devices').doc(deviceId).delete();
  }

  // Data Synchronization Methods
  Future<void> syncStudents(List<Map<String, dynamic>> students) async {
    if (!isAuthenticated) return;

    final batch = _firestore.batch();
    final studentsRef = _firestore.collection('accounts').doc(currentUser!.uid).collection('students');

    for (final student in students) {
      if (student['id'] != null) {
        batch.set(studentsRef.doc(student['id'].toString()), student);
      } else {
        batch.set(studentsRef.doc(), student);
      }
    }

    await batch.commit();
  }

  Future<void> syncTeachers(List<Map<String, dynamic>> teachers) async {
    if (!isAuthenticated) return;

    final batch = _firestore.batch();
    final teachersRef = _firestore.collection('accounts').doc(currentUser!.uid).collection('teachers');

    for (final teacher in teachers) {
      if (teacher['id'] != null) {
        batch.set(teachersRef.doc(teacher['id'].toString()), teacher);
      } else {
        batch.set(teachersRef.doc(), teacher);
      }
    }

    await batch.commit();
  }

  Future<void> syncIncome(List<Map<String, dynamic>> incomes) async {
    if (!isAuthenticated) return;

    final batch = _firestore.batch();
    final incomeRef = _firestore.collection('accounts').doc(currentUser!.uid).collection('income');

    for (final income in incomes) {
      if (income['id'] != null) {
        batch.set(incomeRef.doc(income['id'].toString()), income);
      } else {
        batch.set(incomeRef.doc(), income);
      }
    }

    await batch.commit();
  }

  Future<void> syncExpenditure(List<Map<String, dynamic>> expenditures) async {
    if (!isAuthenticated) return;

    final batch = _firestore.batch();
    final expenditureRef = _firestore.collection('accounts').doc(currentUser!.uid).collection('expenditure');

    for (final expenditure in expenditures) {
      if (expenditure['id'] != null) {
        batch.set(expenditureRef.doc(expenditure['id'].toString()), expenditure);
      } else {
        batch.set(expenditureRef.doc(), expenditure);
      }
    }

    await batch.commit();
  }

  // Data Retrieval Methods
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Individual CRUD methods for StudentProvider
  Future<List<Map<String, dynamic>>> getStudents() async {
    if (!isAuthenticated) return [];

    final snapshot = await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addStudent(Map<String, dynamic> student) async {
    if (!isAuthenticated) return;

    final data = student;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .add(data);
  }

  Future<void> updateStudent(Map<String, dynamic> student) async {
    if (!isAuthenticated || student['id'] == null) return;

    final data = student;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .doc(student['id'].toString())
        .update(data);
  }

  Future<void> deleteStudent(String id) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .doc(id)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getTeachersStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('teachers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getIncomeStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('income')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getExpenditureStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('expenditure')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Backup and Restore
  Future<Map<String, dynamic>> createBackup() async {
    if (!isAuthenticated) return {};

    final students = await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('students')
        .get();

    final teachers = await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('teachers')
        .get();

    final income = await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('income')
        .get();

    final expenditure = await _firestore
        .collection('accounts')
        .doc(currentUser!.uid)
        .collection('expenditure')
        .get();

    return {
      'students': students.docs.map((doc) => doc.data()).toList(),
      'teachers': teachers.docs.map((doc) => doc.data()).toList(),
      'income': income.docs.map((doc) => doc.data()).toList(),
      'expenditure': expenditure.docs.map((doc) => doc.data()).toList(),
      'backupDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    if (!isAuthenticated) return;

    if (backup['students'] != null) {
      await syncStudents(List<Map<String, dynamic>>.from(backup['students']));
    }
    if (backup['teachers'] != null) {
      await syncTeachers(List<Map<String, dynamic>>.from(backup['teachers']));
    }
    if (backup['income'] != null) {
      await syncIncome(List<Map<String, dynamic>>.from(backup['income']));
    }
    if (backup['expenditure'] != null) {
      await syncExpenditure(List<Map<String, dynamic>>.from(backup['expenditure']));
    }
  }

  // Error Handling
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    return error.toString();
  }
} 