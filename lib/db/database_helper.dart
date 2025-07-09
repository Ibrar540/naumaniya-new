import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences for web
  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'naumaniya.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT UNIQUE,
            roll_no INTEGER,
            name TEXT,
            fatherName TEXT,
            mobile TEXT,
            admissionDate TEXT,
            fee TEXT,
            status TEXT,
            stuckupDate TEXT,
            graduationDate TEXT,
            leftDate TEXT,
            classId INTEGER,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE teachers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            mobile TEXT,
            startingDate TEXT,
            status TEXT,
            leavingDate TEXT,
            salary TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE classes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            created_at TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE income (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            amount TEXT,
            date TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE expenditure (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            amount TEXT,
            date TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE section (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            institution TEXT,
            type TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE admission_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT UNIQUE,
            roll_no INTEGER,
            image BLOB,
            student_name TEXT NOT NULL,
            father_name TEXT NOT NULL,
            father_mobile TEXT NOT NULL,
            address TEXT NOT NULL,
            fee INTEGER NOT NULL,
            class TEXT NOT NULL,
            status TEXT DEFAULT 'Actio',
            admission_date TEXT NOT NULL,
            stackup_date TEXT,
            graduation_date TEXT,
            pending_sync INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // Web-compatible methods
  Future<int> getNextId(String tableName) async {
    await _initPrefs();
    final key = '${tableName}_next_id';
    final nextId = _prefs!.getInt(key) ?? 1;
    await _prefs!.setInt(key, nextId + 1);
    return nextId;
  }

  Future<List<Map<String, dynamic>>> getFromPrefs(String tableName) async {
    await _initPrefs();
    final key = '${tableName}_data';
    final data = _prefs!.getString(key);
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  Future<void> saveToPrefs(String tableName, List<Map<String, dynamic>> data) async {
    await _initPrefs();
    final key = '${tableName}_data';
    await _prefs!.setString(key, jsonEncode(data));
  }

  Future<bool> _isOffline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity == ConnectivityResult.none;
  }

  // Students CRUD
  Future<int> insertStudent(Map<String, dynamic> student) async {
    bool offline = await _isOffline();
    student['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final id = await getNextId('students');
      student['id'] = id;
      students.add(student);
      await saveToPrefs('students', students);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('students', student);
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    if (kIsWeb) {
      return await getFromPrefs('students');
    } else {
      final dbClient = await db;
      return await dbClient.query('students');
    }
  }

  Future<int> updateStudent(Map<String, dynamic> student, int id) async {
    bool offline = await _isOffline();
    student['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final index = students.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        student['id'] = id;
        students[index] = student;
        await saveToPrefs('students', students);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('students', student, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> updateStudentStatus(int id, String newStatus) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final index = students.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        students[index]['status'] = newStatus;
        await saveToPrefs('students', students);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update(
        'students', 
        {'status': newStatus}, 
        where: 'id = ?', 
        whereArgs: [id]
      );
    }
  }

  Future<int> deleteStudent(int id) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      students.removeWhere((s) => s['id'] == id);
      await saveToPrefs('students', students);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('students', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> clearStudents() async {
    if (kIsWeb) {
      await saveToPrefs('students', []);
    } else {
      final dbClient = await db;
      await dbClient.delete('students');
    }
  }

  // Teacher CRUD
  Future<int> insertTeacher(Map<String, dynamic> teacher) async {
    bool offline = await _isOffline();
    teacher['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final teachers = await getFromPrefs('teachers');
      final id = await getNextId('teachers');
      teacher['id'] = id;
      teachers.add(teacher);
      await saveToPrefs('teachers', teachers);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('teachers', teacher);
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    if (kIsWeb) {
      return await getFromPrefs('teachers');
    } else {
      final dbClient = await db;
      return await dbClient.query('teachers');
    }
  }

  Future<int> updateTeacher(Map<String, dynamic> teacher, int id) async {
    bool offline = await _isOffline();
    teacher['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final teachers = await getFromPrefs('teachers');
      final index = teachers.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        teacher['id'] = id;
        teachers[index] = teacher;
        await saveToPrefs('teachers', teachers);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('teachers', teacher, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> updateTeacherStatus(int id, String newStatus) async {
    if (kIsWeb) {
      final teachers = await getFromPrefs('teachers');
      final index = teachers.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        teachers[index]['status'] = newStatus;
        await saveToPrefs('teachers', teachers);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update(
        'teachers',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deleteTeacher(int id) async {
    if (kIsWeb) {
      final teachers = await getFromPrefs('teachers');
      teachers.removeWhere((t) => t['id'] == id);
      await saveToPrefs('teachers', teachers);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('teachers', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Income CRUD
  Future<int> insertIncome(Map<String, dynamic> income) async {
    bool offline = await _isOffline();
    income['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final incomes = await getFromPrefs('income');
      final id = await getNextId('income');
      income['id'] = id;
      incomes.add(income);
      await saveToPrefs('income', incomes);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('income', income);
    }
  }

  Future<List<Map<String, dynamic>>> getIncome() async {
    if (kIsWeb) {
      return await getFromPrefs('income');
    } else {
      final dbClient = await db;
      return await dbClient.query('income');
    }
  }

  Future<int> updateIncome(Map<String, dynamic> income, int id) async {
    bool offline = await _isOffline();
    income['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final incomes = await getFromPrefs('income');
      final index = incomes.indexWhere((i) => i['id'] == id);
      if (index != -1) {
        income['id'] = id;
        incomes[index] = income;
        await saveToPrefs('income', incomes);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('income', income, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteIncome(int id) async {
    if (kIsWeb) {
      final incomes = await getFromPrefs('income');
      incomes.removeWhere((i) => i['id'] == id);
      await saveToPrefs('income', incomes);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('income', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Expenditure CRUD
  Future<int> insertExpenditure(Map<String, dynamic> expenditure) async {
    bool offline = await _isOffline();
    expenditure['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final expenditures = await getFromPrefs('expenditure');
      final id = await getNextId('expenditure');
      expenditure['id'] = id;
      expenditures.add(expenditure);
      await saveToPrefs('expenditure', expenditures);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('expenditure', expenditure);
    }
  }

  Future<List<Map<String, dynamic>>> getExpenditure() async {
    if (kIsWeb) {
      return await getFromPrefs('expenditure');
    } else {
      final dbClient = await db;
      return await dbClient.query('expenditure');
    }
  }

  Future<int> updateExpenditure(Map<String, dynamic> expenditure, int id) async {
    bool offline = await _isOffline();
    expenditure['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final expenditures = await getFromPrefs('expenditure');
      final index = expenditures.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        expenditure['id'] = id;
        expenditures[index] = expenditure;
        await saveToPrefs('expenditure', expenditures);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('expenditure', expenditure, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteExpenditure(int id) async {
    if (kIsWeb) {
      final expenditures = await getFromPrefs('expenditure');
      expenditures.removeWhere((e) => e['id'] == id);
      await saveToPrefs('expenditure', expenditures);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('expenditure', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Classes CRUD
  Future<int> insertClass(Map<String, dynamic> classData) async {
    bool offline = await _isOffline();
    classData['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final classes = await getFromPrefs('classes');
      final id = await getNextId('classes');
      classData['id'] = id;
      classes.add(classData);
      await saveToPrefs('classes', classes);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('classes', classData);
    }
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    if (kIsWeb) {
      return await getFromPrefs('classes');
    } else {
      final dbClient = await db;
      return await dbClient.query('classes');
    }
  }

  Future<int> updateClass(Map<String, dynamic> classData, int id) async {
    bool offline = await _isOffline();
    classData['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final classes = await getFromPrefs('classes');
      final index = classes.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        classData['id'] = id;
        classes[index] = classData;
        await saveToPrefs('classes', classes);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('classes', classData, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteClass(int id) async {
    if (kIsWeb) {
      final classes = await getFromPrefs('classes');
      classes.removeWhere((c) => c['id'] == id);
      await saveToPrefs('classes', classes);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('classes', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Get students by class
  Future<List<Map<String, dynamic>>> getStudentsByClass(int classId) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      return students.where((s) => s['classId'] == classId).toList();
    } else {
      final dbClient = await db;
      return await dbClient.query('students', where: 'classId = ?', whereArgs: [classId]);
    }
  }

  // Section CRUD
  Future<int> insertSection(Map<String, dynamic> section) async {
    bool offline = await _isOffline();
    section['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final sections = await getFromPrefs('section');
      final id = await getNextId('section');
      section['id'] = id;
      sections.add(section);
      await saveToPrefs('section', sections);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('section', section);
    }
  }

  Future<List<Map<String, dynamic>>> getSections({String? institution, String? type}) async {
    if (kIsWeb) {
      final sections = await getFromPrefs('section');
      if (institution == null && type == null) return sections;
      return sections.where((s) {
        final matchInstitution = institution == null || s['institution'] == institution;
        final matchType = type == null || s['type'] == type;
        return matchInstitution && matchType;
      }).toList();
    } else {
      final dbClient = await db;
      String where = '';
      List<dynamic> whereArgs = [];
      if (institution != null) {
        where += 'institution = ?';
        whereArgs.add(institution);
      }
      if (type != null) {
        if (where.isNotEmpty) where += ' AND ';
        where += 'type = ?';
        whereArgs.add(type);
      }
      return await dbClient.query('section', where: where.isNotEmpty ? where : null, whereArgs: whereArgs.isNotEmpty ? whereArgs : null);
    }
  }

  Future<int> updateSection(Map<String, dynamic> section, int id) async {
    bool offline = await _isOffline();
    section['pending_sync'] = offline ? 1 : 0;
    if (kIsWeb) {
      final sections = await getFromPrefs('section');
      final index = sections.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        section['id'] = id;
        sections[index] = section;
        await saveToPrefs('section', sections);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('section', section, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteSection(int id) async {
    if (kIsWeb) {
      final sections = await getFromPrefs('section');
      sections.removeWhere((s) => s['id'] == id);
      await saveToPrefs('section', sections);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('section', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Section Data CRUD
  Future<int> insertSectionData(Map<String, dynamic> sectionData) async {
    if (kIsWeb) {
      final sectionDatas = await getFromPrefs('section_data');
      final id = await getNextId('section_data');
      sectionData['id'] = id;
      sectionDatas.add(sectionData);
      await saveToPrefs('section_data', sectionDatas);
      return id;
    } else {
      final dbClient = await db;
      // Create table if not exists
      await dbClient.execute('''
        CREATE TABLE IF NOT EXISTS section_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          section_id INTEGER,
          description TEXT,
          amount TEXT,
          date TEXT,
          type TEXT
        )
      ''');
      return await dbClient.insert('section_data', sectionData);
    }
  }

  Future<List<Map<String, dynamic>>> getSectionData({required int sectionId, required String type}) async {
    if (kIsWeb) {
      final allData = await getFromPrefs('section_data');
      return allData.where((d) => d['section_id'] == sectionId && d['type'] == type).toList();
    } else {
      final dbClient = await db;
      await dbClient.execute('''
        CREATE TABLE IF NOT EXISTS section_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          section_id INTEGER,
          description TEXT,
          amount TEXT,
          date TEXT,
          type TEXT
        )
      ''');
      return await dbClient.query('section_data', where: 'section_id = ? AND type = ?', whereArgs: [sectionId, type]);
    }
  }

  // Admission CRUD
  Future<int> insertAdmission(Map<String, dynamic> admission) async {
    if (kIsWeb) {
      final admissions = await getFromPrefs('admission_table');
      final id = await getNextId('admission_table');
      admission['id'] = id;
      admissions.add(admission);
      await saveToPrefs('admission_table', admissions);
      return id;
    } else {
      final dbClient = await db;
      return await dbClient.insert('admission_table', admission);
    }
  }

  Future<List<Map<String, dynamic>>> getAdmissions() async {
    if (kIsWeb) {
      return await getFromPrefs('admission_table');
    } else {
      final dbClient = await db;
      return await dbClient.query('admission_table');
    }
  }

  Future<int> updateAdmission(Map<String, dynamic> admission, int id) async {
    if (kIsWeb) {
      final admissions = await getFromPrefs('admission_table');
      final index = admissions.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        admission['id'] = id;
        admissions[index] = admission;
        await saveToPrefs('admission_table', admissions);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('admission_table', admission, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteAdmission(int id) async {
    if (kIsWeb) {
      final admissions = await getFromPrefs('admission_table');
      admissions.removeWhere((a) => a['id'] == id);
      await saveToPrefs('admission_table', admissions);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('admission_table', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Helper: get class by name
  Future<Map<String, dynamic>?> getClassByName(String className) async {
    if (kIsWeb) {
      final classes = await getFromPrefs('classes');
      final result = classes.where((c) => c['name'] == className).toList();
      if (result.isNotEmpty) return result.first;
      return null;
    } else {
      final dbClient = await db;
      final result = await dbClient.query('classes', where: 'name = ?', whereArgs: [className]);
      if (result.isNotEmpty) return result.first;
      return null;
    }
  }

  // Helper: get next roll_no for classId
  Future<int> getNextRollNo(int classId) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final classStudents = students.where((s) => s['classId'] == classId).toList();
      if (classStudents.isEmpty) return 1;
      final maxRoll = classStudents.map((s) => s['roll_no'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
      return maxRoll + 1;
    } else {
      final dbClient = await db;
      final result = await dbClient.rawQuery('SELECT MAX(roll_no) as maxRoll FROM students WHERE classId = ?', [classId]);
      final maxRoll = result.first['maxRoll'] as int?;
      return (maxRoll ?? 0) + 1;
    }
  }

  // Helper: get student by student_id
  Future<Map<String, dynamic>?> getStudentByStudentId(String studentId) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final result = students.where((s) => s['student_id'] == studentId).toList();
      if (result.isNotEmpty) return result.first;
      return null;
    } else {
      final dbClient = await db;
      final result = await dbClient.query('students', where: 'student_id = ?', whereArgs: [studentId]);
      if (result.isNotEmpty) return result.first;
      return null;
    }
  }

  // Helper: update student by student_id
  Future<int> updateStudentByStudentId(Map<String, dynamic> student, String studentId) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      final index = students.indexWhere((s) => s['student_id'] == studentId);
      if (index != -1) {
        student['id'] = students[index]['id'];
        students[index] = student;
        await saveToPrefs('students', students);
        return 1;
      }
      return 0;
    } else {
      final dbClient = await db;
      return await dbClient.update('students', student, where: 'student_id = ?', whereArgs: [studentId]);
    }
  }

  // Helper: delete student by student_id
  Future<int> deleteStudentByStudentId(String studentId) async {
    if (kIsWeb) {
      final students = await getFromPrefs('students');
      students.removeWhere((s) => s['student_id'] == studentId);
      await saveToPrefs('students', students);
      return 1;
    } else {
      final dbClient = await db;
      return await dbClient.delete('students', where: 'student_id = ?', whereArgs: [studentId]);
    }
  }

  // Clear all data (for migration)
  Future<void> clearAllData() async {
    if (kIsWeb) {
      final tables = ['students', 'teachers', 'income', 'expenditure', 'section', 'classes', 'admission_table', 'section_data'];
      for (final table in tables) {
        await saveToPrefs(table, []);
      }
    } else {
      final dbClient = await db;
      final tables = ['students', 'teachers', 'income', 'expenditure', 'section', 'classes', 'admission_table', 'section_data'];
      for (final table in tables) {
        await dbClient.delete(table);
      }
    }
  }

  Future<Map<String, int>> getDataStatistics() async {
    final dbInstance = await db;
    final studentsCount = Sqflite.firstIntValue(await dbInstance.rawQuery('SELECT COUNT(*) FROM students')) ?? 0;
    final teachersCount = Sqflite.firstIntValue(await dbInstance.rawQuery('SELECT COUNT(*) FROM teachers')) ?? 0;
    final incomeCount = Sqflite.firstIntValue(await dbInstance.rawQuery('SELECT COUNT(*) FROM income')) ?? 0;
    final expenditureCount = Sqflite.firstIntValue(await dbInstance.rawQuery('SELECT COUNT(*) FROM expenditure')) ?? 0;
    return {
      'students': studentsCount,
      'teachers': teachersCount,
      'income': incomeCount,
      'expenditure': expenditureCount,
    };
  }
} 