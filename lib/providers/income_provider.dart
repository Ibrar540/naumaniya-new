import 'package:flutter/foundation.dart';
import '../models/income.dart';

class IncomeProvider with ChangeNotifier {
  List<Income> _incomes = [];

  List<Income> get incomes => _incomes;

  void addIncome(Income income) {
    _incomes.add(income);
    notifyListeners();
  }

  void removeIncome(int id) {
    _incomes.removeWhere((income) => income.id == id);
    notifyListeners();
  }

  void updateIncome(Income updatedIncome) {
    final index = _incomes.indexWhere((income) => income.id == updatedIncome.id);
    if (index != -1) {
      _incomes[index] = updatedIncome;
      notifyListeners();
    }
  }
} 