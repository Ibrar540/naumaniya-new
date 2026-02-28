import 'package:flutter/foundation.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/section.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<Income> _incomes = [];
  List<Expenditure> _expenditures = [];
  List<Section> _sections = [];
  bool _isLoading = false;
  String? _error;

  // Always use Neon database (no authentication required)
  bool get isAuthenticated => true;
  String? get currentUserId => null; // Not using auth

  // Getters
  List<Income> get incomes => _incomes;
  List<Expenditure> get expenditures => _expenditures;
  List<Section> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load incomes
  Future<void> loadIncomes({String institution = 'madrasa'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await DatabaseService.getAllIncomes(institution: institution);
      _incomes = data.map((item) => Income.fromMap(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      if (kDebugMode) {
        print('Error loading incomes: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addIncome(Income income) async {
    try {
      if (kDebugMode) {
        print('BudgetProvider.addIncome: saving income for sectionId=${income.sectionId} institution=${income.institution}');
      }
      await DatabaseService.addIncome(income);
      await loadIncomes(institution: income.institution ?? 'madrasa');
      if (kDebugMode) {
        print('BudgetProvider.addIncome: saved income successfully');
      }
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        print('BudgetProvider.addIncome: ERROR saving income: $e\n$st');
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    if (income.id == null) return;
    try {
      await DatabaseService.updateIncome(income);
      await loadIncomes(institution: income.institution ?? 'madrasa');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteIncome(dynamic incomeId, {String institution = 'madrasa'}) async {
    try {
      await DatabaseService.deleteIncome(incomeId, institution: institution);
      await loadIncomes(institution: institution);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load expenditures
  Future<void> loadExpenditures({String institution = 'madrasa'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await DatabaseService.getAllExpenditures(institution: institution);
      _expenditures = data.map((item) => Expenditure.fromMap(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      if (kDebugMode) {
        print('Error loading expenditures: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addExpenditure(Expenditure expenditure) async {
    try {
      if (kDebugMode) {
        print('BudgetProvider.addExpenditure: saving expenditure for sectionId=${expenditure.sectionId} institution=${expenditure.institution}');
      }
      await DatabaseService.addExpenditure(expenditure);
      await loadExpenditures(institution: expenditure.institution ?? 'madrasa');
      if (kDebugMode) {
        print('BudgetProvider.addExpenditure: saved expenditure successfully');
      }
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        print('BudgetProvider.addExpenditure: ERROR saving expenditure: $e\n$st');
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpenditure(Expenditure expenditure) async {
    if (expenditure.id == null) return;
    try {
      await DatabaseService.updateExpenditure(expenditure);
      await loadExpenditures(institution: expenditure.institution ?? 'madrasa');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // New methods to handle string IDs (kept for compatibility)
  Future<void> updateIncomeById(String documentId, Income income) async {
    await updateIncome(income);
  }

  Future<void> updateExpenditureById(String documentId, Expenditure expenditure) async {
    await updateExpenditure(expenditure);
  }

  Future<void> deleteExpenditure(dynamic expenditureId, {String institution = 'madrasa'}) async {
    try {
      await DatabaseService.deleteExpenditure(expenditureId, institution: institution);
      await loadExpenditures(institution: institution);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load sections
  Future<void> loadSections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sections = await DatabaseService.getAllSections();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      if (kDebugMode) {
        print('Error loading sections: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addSection(Section section) async {
    try {
      await DatabaseService.addSection(section);
      await loadSections();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSection(Section section) async {
    if (section.id == null) return;
    try {
      await DatabaseService.updateSection(section);
      await loadSections();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSection(dynamic sectionId) async {
    try {
      await DatabaseService.deleteSection(sectionId);
      await loadSections();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // For one-time fetch (not stream)
  Future<List<Map<String, dynamic>>> fetchIncomes({String institution = 'madrasa'}) async {
    return await DatabaseService.getAllIncomes(institution: institution);
  }

  Future<List<Map<String, dynamic>>> fetchExpenditures({String institution = 'madrasa'}) async {
    return await DatabaseService.getAllExpenditures(institution: institution);
  }

  Future<List<Section>> fetchSections() async {
    return await DatabaseService.getAllSections();
  }

  Future<List<Section>> fetchSectionsByType(String institution, String type) async {
    return await DatabaseService.getSectionsByType(institution, type);
  }

  // Fetch income by section
  Future<List<Map<String, dynamic>>> fetchIncomeBySection(int sectionId, {String institution = 'madrasa'}) async {
    return await DatabaseService.getIncomeBySection(sectionId, institution: institution);
  }

  // New helper: fetch income by Section object
  Future<List<Map<String, dynamic>>> fetchIncomeBySectionObj(Section section) async {
    final sid = section.id;
    if (sid != null) {
      return await fetchIncomeBySection(sid, institution: section.institution);
    }
    return [];
  }

  // Fetch expenditure by section
  Future<List<Map<String, dynamic>>> fetchExpenditureBySection(int sectionId, {String institution = 'madrasa'}) async {
    return await DatabaseService.getExpenditureBySection(sectionId, institution: institution);
  }

  Future<List<Map<String, dynamic>>> fetchExpenditureBySectionObj(Section section) async {
    final sid2 = section.id;
    if (sid2 != null) {
      return await fetchExpenditureBySection(sid2, institution: section.institution);
    }
    return [];
  }

  // Fetch income by institution (kept for compatibility)
  Future<List<Map<String, dynamic>>> getIncomesByInstitution(String institution) async {
    return await DatabaseService.getAllIncomes(institution: institution);
  }

  // Fetch expenditure by institution (kept for compatibility)
  Future<List<Map<String, dynamic>>> getExpendituresByInstitution(String institution) async {
    return await DatabaseService.getAllExpenditures(institution: institution);
  }
}
