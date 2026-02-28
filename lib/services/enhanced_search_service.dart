import '../db/database_helper.dart';
import '../models/class_model.dart';
import '../models/teacher.dart';

class EnhancedSearchService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Enhanced search for students with intelligent logic
  Future<List<Map<String, dynamic>>> searchStudents(String query, {bool isUrdu = false}) async {
    final admissions = await _db.getAdmissions();
    final lowerQuery = query.toLowerCase().trim();
    
    if (lowerQuery.isEmpty) return admissions;
    
    // Simple text search for now
    return admissions.where((student) {
      final studentName = student['student_name']?.toString().toLowerCase() ?? '';
      final fatherName = student['father_name']?.toString().toLowerCase() ?? '';
      final studentId = student['student_id']?.toString().toLowerCase() ?? '';
      final className = student['class']?.toString().toLowerCase() ?? '';
      
      return studentName.contains(lowerQuery) || 
             fatherName.contains(lowerQuery) || 
             studentId.contains(lowerQuery) ||
             className.contains(lowerQuery);
    }).toList();
  }

  // Enhanced search for teachers with intelligent logic
  Future<List<Teacher>> searchTeachers(String query, {bool isUrdu = false}) async {
    final teachersData = await _db.getTeachers();
    final teachers = teachersData.map((data) => Teacher.fromMap(data)).toList();
    final lowerQuery = query.toLowerCase().trim();
    
    if (lowerQuery.isEmpty) return teachers;
    
    // Simple text search for now
    return teachers.where((teacher) {
      final name = teacher.name.toLowerCase();
      final mobile = teacher.mobile.toLowerCase();
      final status = teacher.status.toLowerCase();
      
      return name.contains(lowerQuery) || 
             mobile.contains(lowerQuery) || 
             status.contains(lowerQuery);
    }).toList();
  }

  // Enhanced search for classes with intelligent logic
  Future<List<ClassModel>> searchClasses(String query, {bool isUrdu = false}) async {
    final classesData = await _db.getClasses();
    final classes = classesData.map((data) => ClassModel.fromMap(data)).toList();
    final lowerQuery = query.toLowerCase().trim();
    
    if (lowerQuery.isEmpty) return classes;
    
    // Simple text search for now
    return classes.where((classModel) {
      final name = classModel.name.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }
}

// Simplified search parameters
class SearchParams {
  String? classFilter;
  String? statusFilter;
  TimePeriod? timePeriod;
  double? minFee;
  double? maxFee;
  double? minSalary;
  double? maxSalary;
}

class TimePeriod {
  DateTime? startDate;
  DateTime? endDate;
} 