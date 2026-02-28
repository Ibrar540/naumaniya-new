import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/expenditure.dart';
import '../models/income.dart';

class DataProvider extends ChangeNotifier {
  // Students
  final List<Student> _students = [];
  List<Student> get students => _students;
  void addStudent(Student s) { _students.add(s); notifyListeners(); }
  void updateStudent(int i, Student s) { _students[i] = s; notifyListeners(); }
  void deleteStudent(int i) { _students.removeAt(i); notifyListeners(); }

  // Expenditures
  final List<Expenditure> _expenditures = [];
  List<Expenditure> get expenditures => _expenditures;
  void addExpenditure(Expenditure e) { _expenditures.add(e); notifyListeners(); }
  void updateExpenditure(int i, Expenditure e) { _expenditures[i] = e; notifyListeners(); }
  void deleteExpenditure(int i) { _expenditures.removeAt(i); notifyListeners(); }

  // Incomes
  final List<Income> _incomes = [];
  List<Income> get incomes => _incomes;
  void addIncome(Income i) { _incomes.add(i); notifyListeners(); }
  void updateIncome(int i, Income i2) { _incomes[i] = i2; notifyListeners(); }
  void deleteIncome(int i) { _incomes.removeAt(i); notifyListeners(); }
} 