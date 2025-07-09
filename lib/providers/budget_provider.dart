import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/section.dart';
import '../db/database_helper.dart';
import 'cloud_data_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _localDb = DatabaseHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // INCOME
  Stream<List<Income>> get incomes {
    if (isAuthenticated) {
      return _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('income')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Income.fromMap({...doc.data(), 'id': doc.id})).toList());
    } else {
      return Stream.fromFuture(_localDb.getIncome().then((list) => list.map((e) => Income.fromMap(e)).toList()));
    }
  }

  Future<void> addIncome(Income income) async {
    if (isAuthenticated) {
      final data = income.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('income').add(data);
    } else {
      await _localDb.insertIncome(income.toMap());
    }
    notifyListeners();
  }

  Future<void> updateIncome(Income income) async {
    if (isAuthenticated && income.id != null) {
      final data = income.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('income').doc(income.id.toString()).update(data);
    } else if (income.id != null) {
      await _localDb.updateIncome(income.toMap(), income.id!);
    }
    notifyListeners();
  }

  Future<void> deleteIncome(dynamic incomeId) async {
    if (isAuthenticated) {
      await _firestore.collection('accounts').doc(currentUserId).collection('income').doc(incomeId.toString()).delete();
    } else {
      await _localDb.deleteIncome(incomeId is int ? incomeId : int.tryParse(incomeId.toString()) ?? 0);
    }
    notifyListeners();
  }

  // EXPENDITURE
  Stream<List<Expenditure>> get expenditures {
    if (isAuthenticated) {
      return _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('expenditure')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Expenditure.fromMap({...doc.data(), 'id': doc.id})).toList());
    } else {
      return Stream.fromFuture(_localDb.getExpenditure().then((list) => list.map((e) => Expenditure.fromMap(e)).toList()));
    }
  }

  Future<void> addExpenditure(Expenditure expenditure) async {
    if (isAuthenticated) {
      final data = expenditure.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('expenditure').add(data);
    } else {
      await _localDb.insertExpenditure(expenditure.toMap());
    }
    notifyListeners();
  }

  Future<void> updateExpenditure(Expenditure expenditure) async {
    if (isAuthenticated && expenditure.id != null) {
      final data = expenditure.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('expenditure').doc(expenditure.id.toString()).update(data);
    } else if (expenditure.id != null) {
      await _localDb.updateExpenditure(expenditure.toMap(), expenditure.id!);
    }
    notifyListeners();
  }

  Future<void> deleteExpenditure(dynamic expenditureId) async {
    if (isAuthenticated) {
      await _firestore.collection('accounts').doc(currentUserId).collection('expenditure').doc(expenditureId.toString()).delete();
    } else {
      await _localDb.deleteExpenditure(expenditureId is int ? expenditureId : int.tryParse(expenditureId.toString()) ?? 0);
    }
    notifyListeners();
  }

  // SECTIONS
  Stream<List<Section>> get sections {
    if (isAuthenticated) {
      return _firestore
          .collection('accounts')
          .doc(currentUserId)
          .collection('sections')
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Section.fromMap({...doc.data(), 'id': doc.id})).toList());
    } else {
      return Stream.fromFuture(_localDb.getSections().then((list) => list.map((e) => Section.fromMap(e)).toList()));
    }
  }

  Future<void> addSection(Section section) async {
    if (isAuthenticated) {
      final data = section.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('sections').add(data);
    } else {
      await _localDb.insertSection(section.toMap());
    }
    notifyListeners();
  }

  Future<void> updateSection(Section section) async {
    if (isAuthenticated && section.id != null) {
      final data = section.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('accounts').doc(currentUserId).collection('sections').doc(section.id.toString()).update(data);
    } else if (section.id != null) {
      await _localDb.updateSection(section.toMap(), section.id!);
    }
    notifyListeners();
  }

  Future<void> deleteSection(dynamic sectionId) async {
    if (isAuthenticated) {
      await _firestore.collection('accounts').doc(currentUserId).collection('sections').doc(sectionId.toString()).delete();
    } else {
      await _localDb.deleteSection(sectionId is int ? sectionId : int.tryParse(sectionId.toString()) ?? 0);
    }
    notifyListeners();
  }

  // For one-time fetch (not stream)
  Future<List<Income>> fetchIncomes() async {
    if (isAuthenticated) {
      final snapshot = await _firestore.collection('accounts').doc(currentUserId).collection('income').orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => Income.fromMap({...doc.data(), 'id': doc.id})).toList();
    } else {
      final list = await _localDb.getIncome();
      return list.map((e) => Income.fromMap(e)).toList();
    }
  }

  Future<List<Expenditure>> fetchExpenditures() async {
    if (isAuthenticated) {
      final snapshot = await _firestore.collection('accounts').doc(currentUserId).collection('expenditure').orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => Expenditure.fromMap({...doc.data(), 'id': doc.id})).toList();
    } else {
      final list = await _localDb.getExpenditure();
      return list.map((e) => Expenditure.fromMap(e)).toList();
    }
  }

  Future<List<Section>> fetchSections() async {
    if (isAuthenticated) {
      final snapshot = await _firestore.collection('accounts').doc(currentUserId).collection('sections').orderBy('name').get();
      return snapshot.docs.map((doc) => Section.fromMap({...doc.data(), 'id': doc.id})).toList();
    } else {
      final list = await _localDb.getSections();
      return list.map((e) => Section.fromMap(e)).toList();
    }
  }
} 