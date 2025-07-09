import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../providers/teacher_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/student_provider.dart';
import '../models/ai_query_result.dart';

class AIReportingService {
  final TeacherProvider _teacherProvider = TeacherProvider();
  final BudgetProvider _budgetProvider = BudgetProvider();
  final StudentProvider _studentProvider = StudentProvider();

  /// Process user query and return structured result
  Future<AIQueryResult> processQuery(String query, {required bool isUrdu}) async {
    if (query.trim().isEmpty) {
      throw Exception('Query cannot be empty');
    }

    try {
      // Step 1: Parse the query
      final module = _detectModule(query);
      final status = _detectStatus(query);
      final dateInfo = _extractDateInfo(query);
      final classInfo = _extractClass(query);
      final amountFilter = _extractAmountFilter(query);

      // Step 2: Get data and process based on module
      AIQueryResult result;

      if (module == 'students') {
        result = await _processStudentQuery(
          status: status,
          dateInfo: dateInfo,
          classInfo: classInfo,
          amountFilter: amountFilter,
          isUrdu: isUrdu,
        );
      } else if (module == 'teachers') {
        result = await _processTeacherQuery(
          status: status,
          dateInfo: dateInfo,
          amountFilter: amountFilter,
          isUrdu: isUrdu,
        );
      } else if (module == 'budget') {
        result = await _processBudgetQuery(
          dateInfo: dateInfo,
          amountFilter: amountFilter,
          isUrdu: isUrdu,
        );
      } else {
        // Mixed query - show all data
        result = await _processMixedQuery(isUrdu: isUrdu);
      }

      return result;
    } catch (e) {
      throw Exception('Failed to process query: $e');
    }
  }

  /// Process student queries with filtering logic
  Future<AIQueryResult> _processStudentQuery({
    String? status,
    Map<String, dynamic>? dateInfo,
    String? classInfo,
    Map<String, dynamic>? amountFilter,
    required bool isUrdu,
  }) async {
    // Get students from unified provider
    final students = await _studentProvider.fetchStudents();
    
    // Apply filtering logic
    List<Student> filteredStudents = students.where((student) {
      // Status filter
      if (status != null) {
        final studentStatus = student.status.toLowerCase();
        if (!studentStatus.contains(status.toLowerCase())) {
          return false;
        }
      }
      
      // Date filter for admission
      if (dateInfo != null) {
        if (dateInfo['month'] != null && student.admissionDate.month != dateInfo['month']) {
          return false;
        }
        if (dateInfo['year'] != null && student.admissionDate.year != dateInfo['year']) {
          return false;
        }
      }
      
      // Class filter
      if (classInfo != null) {
        // Assuming classId 1 = A, 2 = B, etc.
        final classId = classInfo == 'A' ? 1 : classInfo == 'B' ? 2 : classInfo == 'C' ? 3 : null;
        if (classId != null && student.classId != classId) {
          return false;
        }
      }
      
      // Amount filter for fee (now using double)
      if (amountFilter != null) {
        final fee = double.tryParse(student.fee) ?? 0;
        final amount = amountFilter['amount'] as int;
        if (amountFilter['operator'] == 'more' && fee <= amount) {
          return false;
        } else if (amountFilter['operator'] == 'less' && fee >= amount) {
          return false;
        }
      }
      
      return true;
    }).toList();

    String summary;
    if (status != null) {
      summary = isUrdu 
        ? 'طلباء با حیثیت "$status": ${filteredStudents.length}'
        : 'Students with status "$status": ${filteredStudents.length}';
    } else {
      summary = isUrdu ? 'کل طلباء: ${filteredStudents.length}' : 'Total students: ${filteredStudents.length}';
    }

    return AIQueryResult(
      module: 'students',
      data: filteredStudents,
      summary: summary,
      filters: {
        'status': status,
        'dateInfo': dateInfo,
        'classInfo': classInfo,
        'amountFilter': amountFilter,
      },
    );
  }

  /// Process teacher queries
  Future<AIQueryResult> _processTeacherQuery({
    String? status,
    Map<String, dynamic>? dateInfo,
    Map<String, dynamic>? amountFilter,
    required bool isUrdu,
  }) async {
    // Get teachers from unified provider
    final teachers = await _teacherProvider.fetchTeachers();
    
    List<Teacher> filteredTeachers = teachers.where((teacher) {
      // Status filter
      if (status != null) {
        final teacherStatus = teacher.status.toLowerCase();
        if (!teacherStatus.contains(status.toLowerCase())) {
          return false;
        }
      }
      
      // Date filter
      if (dateInfo != null) {
        if (teacher.startingDate != null) {
          if (dateInfo['month'] != null && teacher.startingDate!.month != dateInfo['month']) {
            return false;
          }
          if (dateInfo['year'] != null && teacher.startingDate!.year != dateInfo['year']) {
            return false;
          }
        }
      }
      
      // Amount filter for salary (now using int)
      if (amountFilter != null) {
        final salary = teacher.salary.toDouble();
        final amount = amountFilter['amount'] as int;
        if (amountFilter['operator'] == 'more' && salary <= amount) {
          return false;
        } else if (amountFilter['operator'] == 'less' && salary >= amount) {
          return false;
        }
      }
      
      return true;
    }).toList();

    String summary;
    if (status != null) {
      summary = isUrdu 
        ? 'اساتذہ با حیثیت "$status": ${filteredTeachers.length}'
        : 'Teachers with status "$status": ${filteredTeachers.length}';
    } else {
      summary = isUrdu ? 'کل اساتذہ: ${filteredTeachers.length}' : 'Total teachers: ${filteredTeachers.length}';
    }

    return AIQueryResult(
      module: 'teachers',
      data: filteredTeachers,
      summary: summary,
      filters: {
        'status': status,
        'dateInfo': dateInfo,
        'amountFilter': amountFilter,
      },
    );
  }

  /// Process budget queries
  Future<AIQueryResult> _processBudgetQuery({
    Map<String, dynamic>? dateInfo,
    Map<String, dynamic>? amountFilter,
    required bool isUrdu,
  }) async {
    // Get budget data from unified provider
    final incomes = await _budgetProvider.fetchIncomes();
    final expenditures = await _budgetProvider.fetchExpenditures();
    
    // Filter incomes
    List<Income> filteredIncomes = incomes.where((income) {
      if (dateInfo != null) {
        final incomeDate = DateTime.tryParse(income.date);
        if (incomeDate != null) {
          if (dateInfo['month'] != null && incomeDate.month != dateInfo['month']) {
            return false;
          }
          if (dateInfo['year'] != null && incomeDate.year != dateInfo['year']) {
            return false;
          }
        }
      }
      
      if (amountFilter != null) {
        final amount = income.amount; // Now using double
        final filterAmount = amountFilter['amount'] as int;
        if (amountFilter['operator'] == 'more' && amount <= filterAmount) {
          return false;
        } else if (amountFilter['operator'] == 'less' && amount >= filterAmount) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Filter expenditures
    List<Expenditure> filteredExpenditures = expenditures.where((expenditure) {
      if (dateInfo != null) {
        final expenditureDate = DateTime.tryParse(expenditure.date);
        if (expenditureDate != null) {
          if (dateInfo['month'] != null && expenditureDate.month != dateInfo['month']) {
            return false;
          }
          if (dateInfo['year'] != null && expenditureDate.year != dateInfo['year']) {
            return false;
          }
        }
      }
      
      if (amountFilter != null) {
        final amount = expenditure.amount; // Now using double
        final filterAmount = amountFilter['amount'] as int;
        if (amountFilter['operator'] == 'more' && amount <= filterAmount) {
          return false;
        } else if (amountFilter['operator'] == 'less' && amount >= filterAmount) {
          return false;
        }
      }
      
      return true;
    }).toList();

    final filteredBudget = [...filteredIncomes, ...filteredExpenditures];
    String summary = isUrdu ? 'کل بجٹ ریکارڈز: ${filteredBudget.length}' : 'Total budget records: ${filteredBudget.length}';

    return AIQueryResult(
      module: 'budget',
      data: filteredBudget,
      summary: summary,
      filters: {
        'dateInfo': dateInfo,
        'amountFilter': amountFilter,
      },
    );
  }

  /// Process mixed queries
  Future<AIQueryResult> _processMixedQuery({required bool isUrdu}) async {
    // Get all data from unified providers
    final students = await _studentProvider.fetchStudents();
    final teachers = await _teacherProvider.fetchTeachers();
    final incomes = await _budgetProvider.fetchIncomes();
    final expenditures = await _budgetProvider.fetchExpenditures();
    
    List<dynamic> allData = [
      ...students.map((s) => {'type': 'student', 'data': s}),
      ...teachers.map((t) => {'type': 'teacher', 'data': t}),
      ...incomes.map((i) => {'type': 'income', 'data': i}),
      ...expenditures.map((e) => {'type': 'expenditure', 'data': e}),
    ];

    String summary = isUrdu ? 'کل ریکارڈز: ${allData.length}' : 'Total records: ${allData.length}';

    return AIQueryResult(
      module: 'mixed',
      data: allData,
      summary: summary,
    );
  }

  // NLP Functions
  String _detectModule(String query) {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('student') || lowerQuery.contains('admission') || lowerQuery.contains('fee')) {
      return 'students';
    } else if (lowerQuery.contains('teacher') || lowerQuery.contains('salary')) {
      return 'teachers';
    } else if (lowerQuery.contains('budget') || lowerQuery.contains('income') || lowerQuery.contains('expenditure') || lowerQuery.contains('money')) {
      return 'budget';
    }
    return 'general';
  }

  String? _detectStatus(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('active')) return 'Active';
    if (lowerQuery.contains('inactive')) return 'Inactive';
    if (lowerQuery.contains('graduated') || lowerQuery.contains('graduate')) return 'Graduated';
    if (lowerQuery.contains('stuckup') || lowerQuery.contains('stuck up')) return 'Stuckup';
    if (lowerQuery.contains('left')) return 'Left';
    
    return null;
  }

  Map<String, dynamic>? _extractDateInfo(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Extract year
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(lowerQuery);
    final year = yearMatch != null ? int.parse(yearMatch.group(1)!) : null;
    
    // Extract month
    final months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    int? month;
    for (int i = 0; i < months.length; i++) {
      if (lowerQuery.contains(months[i])) {
        month = i + 1;
        break;
      }
    }
    
    if (year != null || month != null) {
      return {
        'year': year,
        'month': month,
      };
    }
    
    return null;
  }

  String? _extractClass(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('class a') || lowerQuery.contains('classa')) return 'A';
    if (lowerQuery.contains('class b') || lowerQuery.contains('classb')) return 'B';
    if (lowerQuery.contains('class c') || lowerQuery.contains('classc')) return 'C';
    
    return null;
  }

  Map<String, dynamic>? _extractAmountFilter(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Extract amount
    final amountMatch = RegExp(r'(\d+)').firstMatch(lowerQuery);
    if (amountMatch == null) return null;
    
    final amount = int.parse(amountMatch.group(1)!);
    
    // Extract operator
    String operator = 'more';
    if (lowerQuery.contains('less') || lowerQuery.contains('under')) {
      operator = 'less';
    }
    
    return {
      'amount': amount,
      'operator': operator,
    };
  }
} 