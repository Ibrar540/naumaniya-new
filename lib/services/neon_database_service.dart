import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/section.dart';
import '../models/class_model.dart';

class NeonDatabaseService {
  static NeonDatabaseService? _instance;
  Connection? _connection;
  
  // Singleton pattern
  static NeonDatabaseService get instance {
    _instance ??= NeonDatabaseService._();
    return _instance!;
  }
  
  NeonDatabaseService._();

  // Initialize connection
  Future<void> initialize() async {
    if (_connection != null) return;

    try {
      _connection = await Connection.open(
        Endpoint(
          host: 'ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech',
          database: 'neondb',
          username: 'neondb_owner',
          password: 'npg_eId5vglW0kKO',
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
        ),
      );
      
      if (kDebugMode) {
        print('✅ Connected to Neon database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to Neon: $e');
      }
      rethrow;
    }
  }

  // Close connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  // Ensure connection is active
  Future<void> _ensureConnection() async {
    // If no connection exists, initialize
    if (_connection == null) {
      await initialize();
      return;
    }
    
    // Test if connection is still alive
    try {
      // Try a simple query with timeout
      await _connection!.execute('SELECT 1').timeout(
        Duration(seconds: 2),
        onTimeout: () {
          throw TimeoutException('Connection test timed out');
        },
      );
    } catch (e) {
      // Connection is dead or timed out, close and reconnect
      if (kDebugMode) {
        print('Connection lost or timed out, reconnecting: $e');
      }
      try {
        await _connection?.close();
      } catch (_) {
        // Ignore close errors
      }
      _connection = null;
      await initialize();
    }
  }

  // ==================== STUDENTS ====================
  
  // Get all students
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      'SELECT * FROM students ORDER BY id DESC',
    );
    
    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get students with pagination
  Future<List<Map<String, dynamic>>> getAdmissionsPaginated({
    int? lastId,
    int limit = 10,
  }) async {
    await _ensureConnection();
    
    String query;
    if (lastId != null) {
      query = 'SELECT * FROM students WHERE id < $lastId ORDER BY id DESC LIMIT $limit';
    } else {
      query = 'SELECT * FROM students ORDER BY id DESC LIMIT $limit';
    }
    
    final result = await _connection!.execute(query);
    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get next student ID
  Future<int> getNextAdmissionId() async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      'SELECT id FROM students ORDER BY id DESC LIMIT 1',
    );
    
    if (result.isNotEmpty) {
      final lastId = result.first[0] as int;
      return lastId + 1;
    }
    return 1;
  }

  // Add a new student
  Future<void> addAdmission(Map<String, dynamic> admission) async {
    await _ensureConnection();
    
    final name = admission['student_name'] ?? admission['name'];
    final fatherName = admission['father_name'];
    final mobileNo = admission['mobile'] ?? admission['mobile_no'];
    final className = admission['class'];
    final feeStr = admission['fee'];
    final status = admission['status'] ?? 'active';
    final admissionDate = admission['admission_date'];
    final struckOffDate = admission['struck_off_date'];
    final graduationDate = admission['graduation_date'];
    final image = admission['picture_url'] ?? admission['image'];

    // Convert mobile_no to bigint (handle empty strings and null)
    int? mobileNoInt;
    if (mobileNo != null && mobileNo.toString().trim().isNotEmpty) {
      mobileNoInt = int.tryParse(mobileNo.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    }

    // Convert fee to numeric (handle empty strings and null)
    double? feeDouble;
    if (feeStr != null && feeStr.toString().trim().isNotEmpty) {
      feeDouble = double.tryParse(feeStr.toString());
    }

    await _connection!.execute(
      Sql.named('''
        INSERT INTO students (name, father_name, mobile_no, class, fee, status, 
                             admission_date, struck_off_date, graduation_date, image)
        VALUES (@name, @father_name, @mobile_no, @class, @fee, @status, 
                @admission_date, @struck_off_date, @graduation_date, @image)
      '''),
      parameters: {
        'name': name,
        'father_name': fatherName,
        'mobile_no': mobileNoInt,
        'class': className,
        'fee': feeDouble,
        'status': status,
        'admission_date': admissionDate,
        'struck_off_date': struckOffDate,
        'graduation_date': graduationDate,
        'image': image,
      },
    );
    
    if (kDebugMode) {
      print('✅ Student added to Neon database');
    }

    // Post audit log to backend (non-blocking)
    try {
      final studentName = name ?? admission['name'] ?? 'unknown';
      final details = 'Added student $studentName';
      AuthService().postAudit('add_student', details: details);
    } catch (_) {}
  }

  // Update a student
  Future<void> updateAdmission(String id, Map<String, dynamic> admission) async {
    await _ensureConnection();
    
    // Fetch current record to detect lifecycle changes
    final prevResult = await _connection!.execute(
      Sql.named('SELECT * FROM students WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    Map<String, dynamic>? prev;
    if (prevResult.isNotEmpty) prev = prevResult.first.toColumnMap();

    // If this is a partial update (only a few fields), merge with existing
    final isPartialUpdate = admission.length < 5;
    Map<String, dynamic> fullData = admission;
    if (isPartialUpdate && prev != null) {
      fullData = {
        'student_name': admission['student_name'] ?? admission['name'] ?? prev['name'],
        'father_name': admission['father_name'] ?? prev['father_name'],
        'mobile': admission['mobile'] ?? admission['mobile_no'] ?? prev['mobile_no'],
        'class': admission['class'] ?? prev['class'],
        'fee': admission['fee'] ?? prev['fee'],
        'status': admission['status'] ?? prev['status'],
        'admission_date': admission['admission_date'] ?? prev['admission_date'],
        'struck_off_date': admission.containsKey('struck_off_date')
            ? admission['struck_off_date']
            : prev['struck_off_date'],
        'graduation_date': admission.containsKey('graduation_date')
            ? admission['graduation_date']
            : prev['graduation_date'],
        'picture_url': admission['picture_url'] ?? admission['image'] ?? prev['image'],
      };
    }
    
    final name = fullData['student_name'] ?? fullData['name'];
    final fatherName = fullData['father_name'];
    final mobileNo = fullData['mobile'] ?? fullData['mobile_no'];
    final className = fullData['class'];
    final feeStr = fullData['fee'];
    final status = fullData['status'];
    final admissionDate = fullData['admission_date'];
    final struckOffDate = fullData['struck_off_date'];
    final graduationDate = fullData['graduation_date'];
    final image = fullData['picture_url'] ?? fullData['image'];

    // Convert mobile_no to bigint (handle empty strings and null)
    int? mobileNoInt;
    if (mobileNo != null && mobileNo.toString().trim().isNotEmpty) {
      mobileNoInt = int.tryParse(mobileNo.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    }

    // Convert fee to numeric (handle empty strings and null)
    double? feeDouble;
    if (feeStr != null && feeStr.toString().trim().isNotEmpty) {
      feeDouble = double.tryParse(feeStr.toString());
    }

    await _connection!.execute(
      Sql.named('''
        UPDATE students 
        SET name = @name, father_name = @father_name, mobile_no = @mobile_no,
            class = @class, fee = @fee, status = @status,
            admission_date = @admission_date, struck_off_date = @struck_off_date,
            graduation_date = @graduation_date, image = @image,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': int.parse(id),
        'name': name,
        'father_name': fatherName,
        'mobile_no': mobileNoInt,
        'class': className,
        'fee': feeDouble,
        'status': status,
        'admission_date': admissionDate,
        'struck_off_date': struckOffDate,
        'graduation_date': graduationDate,
        'image': image,
      },
    );

    // Post audit log
    try {
      final updatedName = name ?? 'id=$id';
      final details = 'Updated student ${updatedName} (id=$id)';
      AuthService().postAudit('update_student', details: details);
    } catch (_) {}
  }

  // Delete a student
  Future<void> deleteAdmission(String id) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('DELETE FROM students WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    // Post audit log
    try {
      AuthService().postAudit('delete_student', details: 'Deleted student id=$id');
    } catch (_) {}
  }

  // Search students
  Future<List<Map<String, dynamic>>> searchAdmissions(String query) async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      Sql.named('''
        SELECT * FROM students 
        WHERE name ILIKE @query 
           OR father_name ILIKE @query 
           OR class ILIKE @query 
           OR CAST(mobile_no AS TEXT) ILIKE @query
        ORDER BY id DESC
      '''),
      parameters: {'query': '%$query%'},
    );
    
    return result.map((row) => row.toColumnMap()).toList();
  }

  // ==================== TEACHERS ====================
  
  // Get all teachers
  Future<List<Teacher>> getAllTeachers() async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      'SELECT * FROM teachers ORDER BY id DESC',
    );
    
    return result.map((row) => Teacher.fromMap(row.toColumnMap())).toList();
  }

  // Add a new teacher
  Future<void> addTeacher(Teacher teacher) async {
    await _ensureConnection();
    
    // Parse mobile number safely
    int? mobileNo;
    if (teacher.mobile.isNotEmpty) {
      // Remove any non-numeric characters
      final cleanMobile = teacher.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      mobileNo = int.tryParse(cleanMobile);
    }
    
    await _connection!.execute(
      Sql.named('''
        INSERT INTO teachers (name, mobile_no, starting_date, status, leaving_date, salary)
        VALUES (@name, @mobile_no, @starting_date, @status, @leaving_date, @salary)
      '''),
      parameters: {
        'name': teacher.name,
        'mobile_no': mobileNo,
        'starting_date': teacher.startingDate?.toIso8601String().split('T')[0],
        'status': teacher.status.isNotEmpty ? teacher.status : 'Active',
        'leaving_date': teacher.leavingDate.isNotEmpty ? teacher.leavingDate : null,
        'salary': teacher.salary,
      },
    );
    // Audit
    try { AuthService().postAudit('add_teacher', details: 'Added teacher ${teacher.name}'); } catch (_) {}
  }

  Future<void> updateTeacher(Teacher teacher) async {
    if (teacher.id == null) return;
    await _ensureConnection();
    
    // Parse mobile number safely
    int? mobileNo;
    if (teacher.mobile.isNotEmpty) {
      // Remove any non-numeric characters
      final cleanMobile = teacher.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      mobileNo = int.tryParse(cleanMobile);
    }
    
    // Fetch previous salary to detect salary changes
    dynamic prevSalary;
    try {
      final prevRes = await _connection!.execute(
        Sql.named('SELECT salary FROM teachers WHERE id = @id'),
        parameters: {'id': teacher.id},
      );
      if (prevRes.isNotEmpty) prevSalary = prevRes.first.toColumnMap()['salary'];
    } catch (_) {}

    await _connection!.execute(
      Sql.named('''
        UPDATE teachers 
        SET name = @name, mobile_no = @mobile_no, starting_date = @starting_date,
            status = @status, leaving_date = @leaving_date, salary = @salary,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': teacher.id,
        'name': teacher.name,
        'mobile_no': mobileNo,
        'starting_date': teacher.startingDate?.toIso8601String().split('T')[0],
        'status': teacher.status.isNotEmpty ? teacher.status : 'Active',
        'leaving_date': teacher.leavingDate.isNotEmpty ? teacher.leavingDate : null,
        'salary': teacher.salary,
      },
    );
    try { AuthService().postAudit('update_teacher', details: 'Updated teacher ${teacher.name} (id=${teacher.id})'); } catch (_) {}
    try {
      if (prevSalary != null && prevSalary.toString() != (teacher.salary ?? '').toString()) {
        AuthService().postAudit('update_teacher_salary', details: 'Updated salary for ${teacher.name} from ${prevSalary} to ${teacher.salary} (id=${teacher.id})');
      }
    } catch (_) {}
  }

  // Delete a teacher
  Future<void> deleteTeacher(String teacherId) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('DELETE FROM teachers WHERE id = @id'),
      parameters: {'id': int.parse(teacherId)},
    );
    try { AuthService().postAudit('delete_teacher', details: 'Deleted teacher id=$teacherId'); } catch (_) {}
  }

  // Update teacher status
  Future<void> updateTeacherStatus(int teacherId, String newStatus) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('UPDATE teachers SET status = @status WHERE id = @id'),
      parameters: {'id': teacherId, 'status': newStatus},
    );
    try { AuthService().postAudit('update_teacher_status', details: 'Updated teacher status to ${newStatus} (id=${teacherId})'); } catch (_) {}
  }

  // ==================== SECTIONS ====================
  
  // Get all sections
  Future<List<Section>> getAllSections() async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      'SELECT * FROM sections ORDER BY name ASC',
    );
    
    return result.map((row) => Section.fromMap(row.toColumnMap())).toList();
  }

  // Get sections by type and institution
  Future<List<Section>> getSectionsByType(String institution, String type) async {
    await _ensureConnection();
    
    final result = await _connection!.execute(
      Sql.named('''
        SELECT * FROM sections 
        WHERE institution = @institution AND type = @type 
        ORDER BY name ASC
      '''),
      parameters: {'institution': institution, 'type': type},
    );
    
    return result.map((row) => Section.fromMap(row.toColumnMap())).toList();
  }

  // Add a new section
  Future<void> addSection(Section section) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('''
        INSERT INTO sections (name, institution, type)
        VALUES (@name, @institution, @type)
      '''),
      parameters: {
        'name': section.name,
        'institution': section.institution,
        'type': section.type,
      },
    );
    // Audit
    try {
      AuthService().postAudit('add_section', details: 'Added section ${section.name}');
    } catch (_) {}
  }

  // Update a section
  Future<void> updateSection(Section section) async {
    if (section.id == null) return;
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('''
        UPDATE sections 
        SET name = @name, institution = @institution, type = @type,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': section.id,
        'name': section.name,
        'institution': section.institution,
        'type': section.type,
      },
    );
    try { AuthService().postAudit('update_section', details: 'Updated section ${section.name} (id=${section.id})'); } catch (_) {}
  }

  // Delete a section
  Future<void> deleteSection(dynamic sectionId) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('DELETE FROM sections WHERE id = @id'),
      parameters: {'id': sectionId},
    );
    try { AuthService().postAudit('delete_section', details: 'Deleted section id=$sectionId'); } catch (_) {}
  }

  // ==================== BUDGET HELPER ====================
  
  String _getBudgetTableName(String institution, String type) {
    if (institution == 'madrasa' && type == 'income') {
      return 'madrasa_income';
    } else if (institution == 'madrasa' && type == 'expenditure') {
      return 'madrasa_expenditure';
    } else if (institution == 'masjid' && type == 'income') {
      return 'masjid_income';
    } else if (institution == 'masjid' && type == 'expenditure') {
      return 'masjid_expenditure';
    }
    return 'madrasa_income';
  }

  // ==================== INCOME ====================
  
  // Get all incomes
  Future<List<Map<String, dynamic>>> getAllIncomes({String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'income');
    final result = await _connection!.execute(
      'SELECT * FROM $tableName ORDER BY date DESC',
    );
    
    return result.map((row) {
      final map = row.toColumnMap();
      if (map.containsKey('rs') && !map.containsKey('amount')) {
        map['amount'] = map['rs'];
      }
      // Convert DateTime to String for date field
      if (map['date'] is DateTime) {
        map['date'] = (map['date'] as DateTime).toIso8601String().split('T')[0];
      }
      return map;
    }).toList();
  }

  // Get income by section
  Future<List<Map<String, dynamic>>> getIncomeBySection(int sectionId, {String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'income');
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM $tableName WHERE section_id = @section_id ORDER BY date DESC'),
      parameters: {'section_id': sectionId},
    );
    
    return result.map((row) {
      final map = row.toColumnMap();
      if (map.containsKey('rs') && !map.containsKey('amount')) {
        map['amount'] = map['rs'];
      }
      // Convert DateTime to String for date field
      if (map['date'] is DateTime) {
        map['date'] = (map['date'] as DateTime).toIso8601String().split('T')[0];
      }
      return map;
    }).toList();
  }

  // Add a new income
  Future<void> addIncome(Income income) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(income.institution ?? 'madrasa', 'income');
    await _connection!.execute(
      Sql.named('''
        INSERT INTO $tableName (description, rs, date, section_id)
        VALUES (@description, @rs, @date, @section_id)
      '''),
      parameters: {
        'description': income.description,
        'rs': income.amount,
        'date': income.date,
        'section_id': income.sectionId,
      },
    );
    try { AuthService().postAudit('add_income', details: 'Added income ${income.description ?? ''} amount=${income.amount}'); } catch (_) {}
  }

  // Update an income
  Future<void> updateIncome(Income income) async {
    if (income.id == null) return;
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(income.institution ?? 'madrasa', 'income');
    await _connection!.execute(
      Sql.named('''
        UPDATE $tableName 
        SET description = @description, rs = @rs, date = @date, section_id = @section_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': income.id,
        'description': income.description,
        'rs': income.amount,
        'date': income.date,
        'section_id': income.sectionId,
      },
    );
    try { AuthService().postAudit('update_income', details: 'Updated income id=${income.id} description=${income.description ?? ''} amount=${income.amount}'); } catch (_) {}
  }

  // Delete an income
  Future<void> deleteIncome(dynamic incomeId, {String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'income');
    await _connection!.execute(
      Sql.named('DELETE FROM $tableName WHERE id = @id'),
      parameters: {'id': incomeId},
    );
    try { AuthService().postAudit('delete_income', details: 'Deleted income id=$incomeId'); } catch (_) {}
  }

  // ==================== EXPENDITURE ====================
  
  // Get all expenditures
  Future<List<Map<String, dynamic>>> getAllExpenditures({String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'expenditure');
    final result = await _connection!.execute(
      'SELECT * FROM $tableName ORDER BY date DESC',
    );
    
    return result.map((row) {
      final map = row.toColumnMap();
      if (map.containsKey('rs') && !map.containsKey('amount')) {
        map['amount'] = map['rs'];
      }
      // Convert DateTime to String for date field
      if (map['date'] is DateTime) {
        map['date'] = (map['date'] as DateTime).toIso8601String().split('T')[0];
      }
      return map;
    }).toList();
  }

  // Get expenditure by section
  Future<List<Map<String, dynamic>>> getExpenditureBySection(int sectionId, {String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'expenditure');
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM $tableName WHERE section_id = @section_id ORDER BY date DESC'),
      parameters: {'section_id': sectionId},
    );
    
    return result.map((row) {
      final map = row.toColumnMap();
      if (map.containsKey('rs') && !map.containsKey('amount')) {
        map['amount'] = map['rs'];
      }
      // Convert DateTime to String for date field
      if (map['date'] is DateTime) {
        map['date'] = (map['date'] as DateTime).toIso8601String().split('T')[0];
      }
      return map;
    }).toList();
  }

  // Add a new expenditure
  Future<void> addExpenditure(Expenditure expenditure) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(expenditure.institution ?? 'madrasa', 'expenditure');
    await _connection!.execute(
      Sql.named('''
        INSERT INTO $tableName (description, rs, date, section_id)
        VALUES (@description, @rs, @date, @section_id)
      '''),
      parameters: {
        'description': expenditure.description,
        'rs': expenditure.amount,
        'date': expenditure.date,
        'section_id': expenditure.sectionId,
      },
    );
    try { AuthService().postAudit('add_expenditure', details: 'Added expenditure ${expenditure.description ?? ''} amount=${expenditure.amount}'); } catch (_) {}
  }

  // Update an expenditure
  Future<void> updateExpenditure(Expenditure expenditure) async {
    if (expenditure.id == null) return;
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(expenditure.institution ?? 'madrasa', 'expenditure');
    await _connection!.execute(
      Sql.named('''
        UPDATE $tableName 
        SET description = @description, rs = @rs, date = @date, section_id = @section_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': expenditure.id,
        'description': expenditure.description,
        'rs': expenditure.amount,
        'date': expenditure.date,
        'section_id': expenditure.sectionId,
      },
    );
    try { AuthService().postAudit('update_expenditure', details: 'Updated expenditure id=${expenditure.id} description=${expenditure.description ?? ''} amount=${expenditure.amount}'); } catch (_) {}
  }

  // Delete an expenditure
  Future<void> deleteExpenditure(dynamic expenditureId, {String institution = 'madrasa'}) async {
    await _ensureConnection();
    
    final tableName = _getBudgetTableName(institution, 'expenditure');
    await _connection!.execute(
      Sql.named('DELETE FROM $tableName WHERE id = @id'),
      parameters: {'id': expenditureId},
    );
    try { AuthService().postAudit('delete_expenditure', details: 'Deleted expenditure id=$expenditureId'); } catch (_) {}
  }

  // ==================== CLASSES ====================
  
  // Get all classes
  Future<List<ClassModel>> getAllClasses() async {
    await _ensureConnection();
    
    if (kDebugMode) {
      print('🔍 Querying classes table...');
    }
    
    final result = await _connection!.execute(
      'SELECT * FROM classes ORDER BY name ASC',
    );
    
    if (kDebugMode) {
      print('✅ Query returned ${result.length} rows');
      if (result.isNotEmpty) {
        final sampleMap = result.first.toColumnMap();
        print('📋 Sample row: $sampleMap');
        print('📋 created_at type: ${sampleMap['created_at'].runtimeType}');
      }
    }
    
    return result.map((row) {
      final map = row.toColumnMap();
      // Convert DateTime to String for created_at
      if (map['created_at'] is DateTime) {
        map['created_at'] = (map['created_at'] as DateTime).toIso8601String();
      }
      return ClassModel.fromMap(map);
    }).toList();
  }

  // Add a new class
  Future<void> addClass(ClassModel classModel) async {
    await _ensureConnection();
    
    if (kDebugMode) {
      print('📝 Inserting class: ${classModel.name}');
    }
    
    await _connection!.execute(
      Sql.named('''
        INSERT INTO classes (name)
        VALUES (@name)
      '''),
      parameters: {
        'name': classModel.name,
      },
    );
    
    if (kDebugMode) {
      print('✅ Class inserted successfully');
    }
    try { AuthService().postAudit('add_class', details: 'Added class ${classModel.name}'); } catch (_) {}
  }

  // Update a class
  Future<void> updateClass(ClassModel classModel) async {
    if (classModel.id == null) return;
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('''
        UPDATE classes 
        SET name = @name, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'id': classModel.id,
        'name': classModel.name,
      },
    );
    try { AuthService().postAudit('update_class', details: 'Updated class ${classModel.name} (id=${classModel.id})'); } catch (_) {}
  }

  // Delete a class
  Future<void> deleteClass(int classId) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('DELETE FROM classes WHERE id = @id'),
      parameters: {'id': classId},
    );
    try { AuthService().postAudit('delete_class', details: 'Deleted class id=$classId'); } catch (_) {}
  }

  // Update class status
  Future<void> updateClassStatus(int classId, String newStatus) async {
    await _ensureConnection();
    
    await _connection!.execute(
      Sql.named('UPDATE classes SET status = @status WHERE id = @id'),
      parameters: {'id': classId, 'status': newStatus},
    );
  }
}
