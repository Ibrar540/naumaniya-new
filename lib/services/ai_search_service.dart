import '../db/database_helper.dart';

class AISearchService {
  final DatabaseHelper _db = DatabaseHelper();
  
  // Query understanding and processing
  Future<SearchResponse> processQuery(String query, {bool isUrdu = false}) async {
    try {
      final db = _db;
      final lowerQuery = query.toLowerCase();
      final months = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december',
        'jan', 'feb', 'mar', 'apr', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
      ];
      final monthMap = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      int? foundMonthNum;
      int? foundYear;
      for (String month in months) {
        if (lowerQuery.contains(month)) {
          foundMonthNum = monthMap[month];
          break;
        }
      }
      final yearRegex = RegExp(r'(20\d{2}|\d{2})');
      final yearMatch = yearRegex.firstMatch(lowerQuery);
      if (yearMatch != null) {
        final yearStr = yearMatch.group(0)!;
        foundYear = yearStr.length == 4 ? int.tryParse(yearStr) : 2000 + int.tryParse(yearStr)!;
      }
      // Class filter
      String? classFilter;
      final classMatch = RegExp(r'class\s*([a-zA-Z0-9]+)').firstMatch(lowerQuery);
      if (classMatch != null) {
        classFilter = classMatch.group(1);
      }
      // Status filter
      String? statusFilter;
      final statusKeywords = ['active', 'stuckup', 'graduated', 'left'];
      for (final status in statusKeywords) {
        if (lowerQuery.contains(status)) {
          statusFilter = status;
          break;
        }
      }
      // Fee logic
      if (lowerQuery.contains('fee')) {
        final admissions = await db.getAdmissions();
        double totalFee = 0;
        for (final adm in admissions) {
          final status = (adm['status']?.toString() ?? '').toLowerCase();
          final fee = double.tryParse(adm['fee']?.toString() ?? '') ?? 0;
          final admissionDateStr = adm['admission_date']?.toString() ?? '';
          final stuckupDateStr = adm['stackup_date']?.toString() ?? '';
          final graduationDateStr = adm['graduation_date']?.toString() ?? '';
          DateTime? admissionDate, stuckupDate, graduationDate;
          try { admissionDate = DateTime.parse(admissionDateStr); } catch (_) {}
          try { stuckupDate = DateTime.parse(stuckupDateStr); } catch (_) {}
          try { graduationDate = DateTime.parse(graduationDateStr); } catch (_) {}
          if (foundYear != null) {
            if (admissionDate == null || admissionDate.year > foundYear) continue;
            int endMonth = 12;
            if (status == 'stuckup' && stuckupDate != null && stuckupDate.year == foundYear) {
              endMonth = stuckupDate.month;
            }
            if (status == 'graduated' && graduationDate != null && graduationDate.year == foundYear) {
              endMonth = graduationDate.month;
            }
            int searchMonth = foundMonthNum ?? 12;
            if (searchMonth > endMonth) continue;
            if (foundMonthNum != null && admissionDate.year == foundYear && admissionDate.month > foundMonthNum) continue;
            totalFee += fee;
          } else {
            totalFee += fee;
          }
        }
        return SearchResponse(
          answer: isUrdu ? 'کل فیس: $totalFee' : 'Total fee: $totalFee',
          summary: isUrdu ? 'فیس رپورٹ' : 'Fee Report',
          details: [],
          error: null,
        );
      }
      // Teacher salary logic
      if (lowerQuery.contains('teacher') && lowerQuery.contains('salary')) {
        final teachers = await db.getTeachers();
        double totalSalary = 0;
        for (final t in teachers) {
          final status = (t['status']?.toString() ?? '').toLowerCase();
          final salary = double.tryParse(t['salary']?.toString() ?? '') ?? 0;
          final startingDateStr = t['startingDate']?.toString() ?? '';
          final leavingDateStr = t['leavingDate']?.toString() ?? '';
          DateTime? startingDate, leavingDate;
          try { startingDate = DateTime.parse(startingDateStr); } catch (_) {}
          try { leavingDate = leavingDateStr.isNotEmpty ? DateTime.parse(leavingDateStr) : null; } catch (_) {}
          if (foundYear != null) {
            if (startingDate == null || startingDate.year > foundYear) continue;
            int endMonth = 12;
            if ((status == 'left' || status == 'stuckup') && leavingDate != null && leavingDate.year == foundYear) {
              endMonth = leavingDate.month;
            }
            int searchMonth = foundMonthNum ?? 12;
            if (searchMonth > endMonth) continue;
            if (foundMonthNum != null && startingDate.year == foundYear && startingDate.month > foundMonthNum) continue;
            totalSalary += salary;
          } else {
            totalSalary += salary;
          }
        }
        return SearchResponse(
          answer: isUrdu ? 'کل تنخواہ: $totalSalary' : 'Total salary: $totalSalary',
          summary: isUrdu ? 'تنخواہ رپورٹ' : 'Salary Report',
          details: [],
          error: null,
        );
      }
      // Teacher by status
      if (lowerQuery.contains('teacher')) {
        final teachers = await db.getTeachers();
        final filtered = teachers.where((t) {
          final status = (t['status']?.toString() ?? '').toLowerCase();
          if (statusFilter != null && status != statusFilter) return false;
          return true;
        }).toList();
        return SearchResponse(
          answer: isUrdu ? 'اساتذہ کی تعداد: ${filtered.length}' : 'Number of teachers: ${filtered.length}',
          summary: isUrdu ? 'اساتذہ رپورٹ' : 'Teachers Report',
          details: filtered,
          error: null,
        );
      }
      // Students by class, month, year, status
      if (lowerQuery.contains('student')) {
        final admissions = await db.getAdmissions();
        final filtered = admissions.where((adm) {
          final status = (adm['status']?.toString() ?? '').toLowerCase();
          final admissionDateStr = adm['admission_date']?.toString() ?? '';
          DateTime? admissionDate;
          try { admissionDate = DateTime.parse(admissionDateStr); } catch (_) {}
          if (classFilter != null && (adm['class']?.toString().toLowerCase() ?? '') != classFilter.toLowerCase()) return false;
          if (statusFilter != null && status != statusFilter) return false;
          if (foundYear != null && (admissionDate == null || admissionDate.year != foundYear)) return false;
          if (foundMonthNum != null && (admissionDate == null || admissionDate.month != foundMonthNum)) return false;
          return true;
        }).toList();
        return SearchResponse(
          answer: isUrdu ? 'طلباء کی تعداد: ${filtered.length}' : 'Number of students: ${filtered.length}',
          summary: isUrdu ? 'طلباء رپورٹ' : 'Students Report',
          details: filtered,
          error: null,
        );
      }
      // Madrasa budget, income, expenditure, and section search
      if (lowerQuery.contains('madrasa')) {
        // Income
        if (lowerQuery.contains('income')) {
          final incomes = await db.getIncome();
          double totalIncome = 0;
          final filtered = incomes.where((inc) {
            final dateStr = inc['date']?.toString() ?? '';
            final section = (inc['section']?.toString() ?? '').toLowerCase();
            DateTime? date;
            try { date = DateTime.parse(dateStr); } catch (_) {}
            if (foundYear != null && (date == null || date.year != foundYear)) return false;
            if (foundMonthNum != null && (date == null || date.month != foundMonthNum)) return false;
            if (lowerQuery.contains('section') && statusFilter != null && section != statusFilter) return false;
            return true;
          }).toList();
          for (final inc in filtered) {
            totalIncome += double.tryParse(inc['amount']?.toString() ?? '') ?? 0;
          }
          return SearchResponse(
            answer: isUrdu ? 'کل آمدنی: $totalIncome' : 'Total income: $totalIncome',
            summary: isUrdu ? 'آمدنی رپورٹ' : 'Income Report',
            details: filtered,
            error: null,
          );
        }
        // Expenditure
        if (lowerQuery.contains('expenditure')) {
          final expenditures = await db.getExpenditure();
          double totalExpenditure = 0;
          final filtered = expenditures.where((exp) {
            final dateStr = exp['date']?.toString() ?? '';
            final section = (exp['section']?.toString() ?? '').toLowerCase();
            DateTime? date;
            try { date = DateTime.parse(dateStr); } catch (_) {}
            if (foundYear != null && (date == null || date.year != foundYear)) return false;
            if (foundMonthNum != null && (date == null || date.month != foundMonthNum)) return false;
            if (lowerQuery.contains('section') && statusFilter != null && section != statusFilter) return false;
            return true;
          }).toList();
          for (final exp in filtered) {
            totalExpenditure += double.tryParse(exp['amount']?.toString() ?? '') ?? 0;
          }
          return SearchResponse(
            answer: isUrdu ? 'کل اخراجات: $totalExpenditure' : 'Total expenditure: $totalExpenditure',
            summary: isUrdu ? 'اخراجات رپورٹ' : 'Expenditure Report',
            details: filtered,
            error: null,
          );
        }
        // Budget (income - expenditure)
        final incomes = await db.getIncome();
        final expenditures = await db.getExpenditure();
        double totalIncome = 0;
        double totalExpenditure = 0;
        final filteredIncome = incomes.where((inc) {
          final dateStr = inc['date']?.toString() ?? '';
          DateTime? date;
          try { date = DateTime.parse(dateStr); } catch (_) {}
          if (foundYear != null && (date == null || date.year != foundYear)) return false;
          if (foundMonthNum != null && (date == null || date.month != foundMonthNum)) return false;
          return true;
        }).toList();
        final filteredExpenditure = expenditures.where((exp) {
          final dateStr = exp['date']?.toString() ?? '';
          DateTime? date;
          try { date = DateTime.parse(dateStr); } catch (_) {}
          if (foundYear != null && (date == null || date.year != foundYear)) return false;
          if (foundMonthNum != null && (date == null || date.month != foundMonthNum)) return false;
          return true;
        }).toList();
        for (final inc in filteredIncome) {
          totalIncome += double.tryParse(inc['amount']?.toString() ?? '') ?? 0;
        }
        for (final exp in filteredExpenditure) {
          totalExpenditure += double.tryParse(exp['amount']?.toString() ?? '') ?? 0;
        }
        final budget = totalIncome - totalExpenditure;
        return SearchResponse(
          answer: isUrdu ? 'کل بجٹ: $budget' : 'Total budget: $budget',
          summary: isUrdu ? 'بجٹ رپورٹ' : 'Budget Report',
          details: [
            {'income': totalIncome, 'expenditure': totalExpenditure, 'budget': budget}
          ],
          error: null,
        );
      }
      // Default
      return SearchResponse(
        answer: isUrdu ? 'آپ کا سوال: $query' : 'Your question: $query',
        summary: isUrdu ? 'آپ کا سوال' : 'Your Question',
        details: [
          {'Question': query},
          {'Status': 'Processing...'},
        ],
        error: null,
      );
    } catch (e) {
      return SearchResponse(
        answer: isUrdu ? 'معذرت، میں آپ کے سوال کو سمجھ نہیں سکا۔ براہ کرم دوبارہ کوشش کریں۔' : 'Sorry, I could not understand your question. Please try again.',
        summary: '',
        details: [],
        error: e.toString(),
      );
    }
  }
}

// Data structures
enum QueryType { fee, salary, income, expenditure, count, general }
enum AmountType { collected, paid, total }

class QueryParams {
  QueryType queryType = QueryType.general;
  TimePeriod timePeriod = TimePeriod();
  String? classFilter;
  String? sectionFilter;
  String? statusFilter;
  AmountType amountType = AmountType.total;
}

class TimePeriod {
  int? startYear;
  int? endYear;
  int? startMonth;
  int? endMonth;
}

class QueryResult {
  final double total;
  final int count;
  final List<Map<String, dynamic>> details;
  final QueryType queryType;

  QueryResult({
    required this.total,
    required this.count,
    required this.details,
    required this.queryType,
  });
}

class SearchResponse {
  final String answer;
  final String summary;
  final List<Map<String, dynamic>> details;
  final String? error;

  SearchResponse({
    required this.answer,
    required this.summary,
    required this.details,
    this.error,
  });
} 