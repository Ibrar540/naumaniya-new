// Database Service Wrapper
// This provides a unified interface for database operations

import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/loan.dart';
import '../models/section.dart';
import '../models/class_model.dart';
import 'neon_database_service.dart';

class DatabaseService {
  // Use Neon by default
  static final _neonService = NeonDatabaseService.instance;
  
  // Initialize database connection
  static Future<void> initialize() async {
    await _neonService.initialize();
  }
  
  // Close database connection
  static Future<void> close() async {
    await _neonService.close();
  }

  // ==================== STUDENTS ====================
  
  static Future<List<Map<String, dynamic>>> getAllStudents() {
    return _neonService.getAllStudents();
  }

  static Future<List<Map<String, dynamic>>> getAdmissionsPaginated({
    int? lastId,
    int limit = 10,
  }) {
    return _neonService.getAdmissionsPaginated(lastId: lastId, limit: limit);
  }

  static Future<int> getNextAdmissionId() {
    return _neonService.getNextAdmissionId();
  }

  static Future<void> addAdmission(Map<String, dynamic> admission) {
    return _neonService.addAdmission(admission);
  }

  static Future<void> updateAdmission(String id, Map<String, dynamic> admission) {
    return _neonService.updateAdmission(id, admission);
  }

  static Future<void> deleteAdmission(String id) {
    return _neonService.deleteAdmission(id);
  }

  static Future<List<Map<String, dynamic>>> searchAdmissions(String query) {
    return _neonService.searchAdmissions(query);
  }

  // ==================== TEACHERS ====================
  
  static Future<List<Teacher>> getAllTeachers() {
    return _neonService.getAllTeachers();
  }

  static Future<void> addTeacher(Teacher teacher) {
    return _neonService.addTeacher(teacher);
  }

  static Future<void> updateTeacher(Teacher teacher) {
    return _neonService.updateTeacher(teacher);
  }

  static Future<void> deleteTeacher(String teacherId) {
    return _neonService.deleteTeacher(teacherId);
  }

  static Future<void> updateTeacherStatus(int teacherId, String newStatus) {
    return _neonService.updateTeacherStatus(teacherId, newStatus);
  }

  // ==================== SECTIONS ====================
  
  static Future<List<Section>> getAllSections() {
    return _neonService.getAllSections();
  }

  static Future<List<Section>> getSectionsByType(String institution, String type) {
    return _neonService.getSectionsByType(institution, type);
  }

  static Future<void> addSection(Section section) {
    return _neonService.addSection(section);
  }

  static Future<void> updateSection(Section section) {
    return _neonService.updateSection(section);
  }

  static Future<void> deleteSection(dynamic sectionId) {
    return _neonService.deleteSection(sectionId);
  }

  // ==================== INCOME ====================
  
  static Future<List<Map<String, dynamic>>> getAllIncomes({String institution = 'madrasa'}) {
    return _neonService.getAllIncomes(institution: institution);
  }

  static Future<List<Map<String, dynamic>>> getIncomeBySection(int sectionId, {String institution = 'madrasa'}) {
    return _neonService.getIncomeBySection(sectionId, institution: institution);
  }

  static Future<void> addIncome(Income income) {
    return _neonService.addIncome(income);
  }

  static Future<void> updateIncome(Income income) {
    return _neonService.updateIncome(income);
  }

  static Future<void> deleteIncome(dynamic incomeId, {String institution = 'madrasa'}) {
    return _neonService.deleteIncome(incomeId, institution: institution);
  }

  // ==================== EXPENDITURE ====================
  
  static Future<List<Map<String, dynamic>>> getAllExpenditures({String institution = 'madrasa'}) {
    return _neonService.getAllExpenditures(institution: institution);
  }

  static Future<List<Map<String, dynamic>>> getExpenditureBySection(int sectionId, {String institution = 'madrasa'}) {
    return _neonService.getExpenditureBySection(sectionId, institution: institution);
  }

  static Future<void> addExpenditure(Expenditure expenditure) {
    return _neonService.addExpenditure(expenditure);
  }

  static Future<void> updateExpenditure(Expenditure expenditure) {
    return _neonService.updateExpenditure(expenditure);
  }

  static Future<void> deleteExpenditure(dynamic expenditureId, {String institution = 'madrasa'}) {
    return _neonService.deleteExpenditure(expenditureId, institution: institution);
  }

  // ==================== LOANS (Loan / Payment records) ====================

  static Future<List<Map<String, dynamic>>> getAllLoans({String institution = 'madrasa'}) {
    if (institution != 'madrasa') return Future.value([]);
    return _neonService.getAllLoans(institution: institution);
  }

  static Future<List<Map<String, dynamic>>> getLoanBySection(int sectionId, {String institution = 'madrasa'}) {
    if (institution != 'madrasa') return Future.value([]);
    return _neonService.getLoanBySection(sectionId, institution: institution);
  }

  static Future<void> addLoan(Loan loan) {
    if (loan.institution != null && loan.institution != 'madrasa') return Future.value();
    return _neonService.addLoan(loan);
  }

  static Future<void> updateLoan(Loan loan) {
    return _neonService.updateLoan(loan);
  }

  static Future<void> deleteLoan(dynamic loanId, {String institution = 'madrasa'}) {
    return _neonService.deleteLoan(loanId, institution: institution);
  }

  // ==================== CLASSES ====================
  
  static Future<List<ClassModel>> getAllClasses() {
    return _neonService.getAllClasses();
  }

  static Future<void> addClass(ClassModel classModel) {
    return _neonService.addClass(classModel);
  }

  static Future<void> updateClass(ClassModel classModel) {
    return _neonService.updateClass(classModel);
  }

  static Future<void> deleteClass(int classId) {
    return _neonService.deleteClass(classId);
  }

  static Future<void> updateClassStatus(int classId, String newStatus) {
    return _neonService.updateClassStatus(classId, newStatus);
  }
}
