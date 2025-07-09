import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher.dart';
import '../db/database_helper.dart';
import 'cloud_data_provider.dart';

class TeacherProvider extends ChangeNotifier {
  final CloudDataProvider _cloudProvider = CloudDataProvider();
  final DatabaseHelper _localDb = DatabaseHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isAuthenticated => _auth.currentUser != null;

  // Stream of teachers
  Stream<List<Teacher>> get teachers {
    if (isAuthenticated) {
      return _cloudProvider.teachers;
    } else {
      // Convert Future to Stream for local
      return Stream.fromFuture(_localDb.getTeachers().then((list) => list.map((e) => Teacher.fromMap(e)).toList()));
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    if (isAuthenticated) {
      await _cloudProvider.addTeacher(teacher);
    } else {
      await _localDb.insertTeacher(teacher.toMap());
    }
    notifyListeners();
  }

  Future<void> updateTeacher(Teacher teacher) async {
    if (isAuthenticated) {
      await _cloudProvider.updateTeacher(teacher);
    } else {
      if (teacher.id != null) {
        await _localDb.updateTeacher(teacher.toMap(), teacher.id!);
      }
    }
    notifyListeners();
  }

  Future<void> deleteTeacher(dynamic teacherId) async {
    if (isAuthenticated) {
      await _cloudProvider.deleteTeacher(teacherId.toString());
    } else {
      await _localDb.deleteTeacher(teacherId is int ? teacherId : int.tryParse(teacherId.toString()) ?? 0);
    }
    notifyListeners();
  }

  // For one-time fetch (not stream)
  Future<List<Teacher>> fetchTeachers() async {
    if (isAuthenticated) {
      return await _cloudProvider.teachers.first;
    } else {
      final list = await _localDb.getTeachers();
      return list.map((e) => Teacher.fromMap(e)).toList();
    }
  }

  Future<void> updateTeacherStatus(int teacherId, String newStatus) async {
    if (isAuthenticated) {
      await _cloudProvider.updateTeacherStatus(teacherId, newStatus);
    } else {
      await _localDb.updateTeacherStatus(teacherId, newStatus);
    }
    notifyListeners();
  }
} 