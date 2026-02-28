import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('naumaniya.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop and recreate teachers table with correct schema
      await db.execute('DROP TABLE IF EXISTS teachers');
      await db.execute('''
        CREATE TABLE teachers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          mobile TEXT,
          starting_date TEXT,
          status TEXT,
          leaving_date TEXT,
          salary INTEGER
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create tables here
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        grade TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE classes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        className TEXT,
        teacherName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE teachers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        mobile TEXT,
        starting_date TEXT,
        status TEXT,
        leaving_date TEXT,
        salary INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE admissions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        admissionDate TEXT,
        FOREIGN KEY (studentId) REFERENCES students(id)
      )
    ''');
  }

  // Student Methods
  Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await instance.database;
    return await db.insert('students', student);
  }

  Future<int> updateStudent(Map<String, dynamic> student, int id) async {
    final db = await instance.database;
    return await db.update('students', student, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await instance.database;
    return await db.query('students');
  }

  Future<Map<String, dynamic>?> getStudentById(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // Method to clear all students
  Future<int> deleteAllStudents() async {
    final db = await instance.database;
    return await db.delete('students');
  }

  Future<void> clearStudents() async {
    final db = await instance.database;
    await db.delete('students');
  }

  // Class Methods
  Future<int> insertClass(Map<String, dynamic> classData) async {
    final db = await instance.database;
    return await db.insert('classes', classData);
  }

  Future<int> updateClass(Map<String, dynamic> classData, int id) async {
    final db = await instance.database;
    return await db.update('classes', classData, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await instance.database;
    return await db.query('classes');
  }

  Future<Map<String, dynamic>?> getClassById(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('classes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> deleteClass(int id) async {
    final db = await instance.database;
    return await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getClassByName(String name) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('classes', where: 'className = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Teacher Methods
  Future<int> insertTeacher(Map<String, dynamic> teacher) async {
    final db = await instance.database;
    return await db.insert('teachers', teacher);
  }

  Future<int> updateTeacher(Map<String, dynamic> teacher, int id) async {
    final db = await instance.database;
    return await db.update('teachers', teacher, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    final db = await instance.database;
    return await db.query('teachers');
  }

  Future<Map<String, dynamic>?> getTeacherById(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('teachers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> deleteTeacher(int id) async {
    final db = await instance.database;
    return await db.delete('teachers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTeacherStatus(int teacherId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'teachers',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [teacherId],
    );
  }

  // Admission Methods
  Future<int> insertAdmission(Map<String, dynamic> admission) async {
    final db = await instance.database;
    return await db.insert('admissions', admission);
  }

  Future<int> updateAdmission(Map<String, dynamic> admission, int id) async {
    final db = await instance.database;
    return await db.update('admissions', admission, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAdmissions() async {
    final db = await instance.database;
    return await db.query('admissions');
  }

  Future<Map<String, dynamic>?> getAdmissionById(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('admissions', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> deleteAdmission(int id) async {
    final db = await instance.database;
    return await db.delete('admissions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getIncome() async {
    final db = await instance.database;
    // Assuming you have a table named 'income'
    return await db.query('income');
  }

  Future<List<Map<String, dynamic>>> getExpenditure() async {
    final db = await instance.database;
    // Assuming you have a table named 'expenditure'
    return await db.query('expenditure');
  }

  Future<List<Map<String, dynamic>>> getPendingIncome() async {
    // This is a placeholder implementation.
    // You should replace this with your actual logic for fetching pending income.
    return [];
  }

  Future<List<Map<String, dynamic>>> getPendingExpenditure() async {
    // This is a placeholder implementation.
    // You should replace this with your actual logic for fetching pending expenditure.
    return [];
  }

  Future<List<Map<String, dynamic>>> getPendingSection() async {
    // This is a placeholder implementation.
    // You should replace this with your actual logic for fetching pending sections.
    return [];
  }
}
