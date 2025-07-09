import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/section.dart';
import '../models/class_model.dart';

class CloudDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Streams
  Stream<List<Student>> get students => _getStudentsStream();
  Stream<List<Teacher>> get teachers => _getTeachersStream();
  Stream<List<Income>> get income => _getIncomeStream();
  Stream<List<Expenditure>> get expenditure => _getExpenditureStream();
  Stream<List<Section>> get sections => _getSectionsStream();
  Stream<List<ClassModel>> get classes => _getClassesStream();

  // Authentication status
  bool get isAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // Student operations
  Stream<List<Student>> _getStudentsStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addStudent(Student student) async {
    if (!isAuthenticated) return;

    final studentData = student.toMap();
    studentData['createdAt'] = FieldValue.serverTimestamp();
    studentData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('students')
        .add(studentData);
  }

  Future<void> updateStudent(Student student) async {
    if (!isAuthenticated || student.id == null) return;

    final studentData = student.toMap();
    studentData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('students')
        .doc(student.id.toString())
        .update(studentData);
  }

  Future<void> deleteStudent(String studentId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  // Teacher operations
  Stream<List<Teacher>> _getTeachersStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Teacher.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addTeacher(Teacher teacher) async {
    if (!isAuthenticated) return;

    final teacherData = teacher.toMap();
    teacherData['createdAt'] = FieldValue.serverTimestamp();
    teacherData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('teachers')
        .add(teacherData);
  }

  Future<void> updateTeacher(Teacher teacher) async {
    if (!isAuthenticated || teacher.id == null) return;

    final teacherData = teacher.toMap();
    teacherData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('teachers')
        .doc(teacher.id.toString())
        .update(teacherData);
  }

  Future<void> deleteTeacher(String teacherId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .delete();
  }

  // Income operations
  Stream<List<Income>> _getIncomeStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('income')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addIncome(Income income) async {
    if (!isAuthenticated) return;

    final incomeData = income.toMap();
    incomeData['createdAt'] = FieldValue.serverTimestamp();
    incomeData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('income')
        .add(incomeData);
  }

  Future<void> updateIncome(Income income) async {
    if (!isAuthenticated || income.id == null) return;

    final incomeData = income.toMap();
    incomeData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('income')
        .doc(income.id.toString())
        .update(incomeData);
  }

  Future<void> deleteIncome(String incomeId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('income')
        .doc(incomeId)
        .delete();
  }

  // Expenditure operations
  Stream<List<Expenditure>> _getExpenditureStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('expenditure')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expenditure.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addExpenditure(Expenditure expenditure) async {
    if (!isAuthenticated) return;

    final expenditureData = expenditure.toMap();
    expenditureData['createdAt'] = FieldValue.serverTimestamp();
    expenditureData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('expenditure')
        .add(expenditureData);
  }

  Future<void> updateExpenditure(Expenditure expenditure) async {
    if (!isAuthenticated || expenditure.id == null) return;

    final expenditureData = expenditure.toMap();
    expenditureData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('expenditure')
        .doc(expenditure.id.toString())
        .update(expenditureData);
  }

  Future<void> deleteExpenditure(String expenditureId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('expenditure')
        .doc(expenditureId)
        .delete();
  }

  // Section operations
  Stream<List<Section>> _getSectionsStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('sections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Section.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addSection(Section section) async {
    if (!isAuthenticated) return;

    final sectionData = section.toMap();
    sectionData['createdAt'] = FieldValue.serverTimestamp();
    sectionData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('sections')
        .add(sectionData);
  }

  Future<void> updateSection(Section section) async {
    if (!isAuthenticated || section.id == null) return;

    final sectionData = section.toMap();
    sectionData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('sections')
        .doc(section.id.toString())
        .update(sectionData);
  }

  Future<void> deleteSection(String sectionId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('sections')
        .doc(sectionId)
        .delete();
  }

  // Class operations
  Stream<List<ClassModel>> _getClassesStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addClass(ClassModel classModel) async {
    if (!isAuthenticated) return;

    final classData = classModel.toMap();
    classData['createdAt'] = FieldValue.serverTimestamp();
    classData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('classes')
        .add(classData);
  }

  Future<void> updateClass(ClassModel classModel) async {
    if (!isAuthenticated || classModel.id == null) return;

    final classData = classModel.toMap();
    classData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('classes')
        .doc(classModel.id.toString())
        .update(classData);
  }

  Future<void> deleteClass(String classId) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('accounts')
        .doc(currentUserId)
        .collection('classes')
        .doc(classId)
        .delete();
  }

  // Get data statistics
  Future<Map<String, int>> getDataStatistics() async {
    if (!isAuthenticated) return {};

    try {
      final studentsSnapshot = await _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('students')
          .get();

      final teachersSnapshot = await _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('teachers')
          .get();

      final incomeSnapshot = await _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('income')
          .get();

      final expenditureSnapshot = await _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('expenditure')
          .get();

      return {
        'cloud_students': studentsSnapshot.docs.length,
        'cloud_teachers': teachersSnapshot.docs.length,
        'cloud_income': incomeSnapshot.docs.length,
        'cloud_expenditure': expenditureSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting cloud statistics: $e');
      return {};
    }
  }
} 