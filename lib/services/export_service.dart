import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';

class ExportService {
  /// Export students data to PDF
  Future<File> exportStudentsToPdf({
    required List<Student> students,
    required bool isUrdu,
    String? title,
  }) async {
    final pdf = pw.Document();

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title ?? (isUrdu ? 'طلباء کی فہرست' : 'Students List'),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              isUrdu
                  ? 'کل طلباء: ${students.length}'
                  : 'Total Students: ${students.length}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // Table
          pw.TableHelper.fromTextArray(
            context: context,
            data: <List<String>>[
              // Header row
              isUrdu
                  ? ['فیس', 'حیثیت', 'کلاس', 'داخلے کی تاریخ', 'نام']
                  : ['Name', 'Admission Date', 'Class', 'Status', 'Fee'],
              // Data rows
              ...students.map((student) => isUrdu
                  ? [
                      student.fee,
                      student.status,
                      'Class ${String.fromCharCode(64 + (student.classId ?? 1))}',
                      DateFormat('yyyy-MM-dd').format(student.admissionDate),
                      student.name,
                    ]
                  : [
                      student.name,
                      DateFormat('yyyy-MM-dd').format(student.admissionDate),
                      'Class ${String.fromCharCode(64 + (student.classId ?? 1))}',
                      student.status,
                      student.fee,
                    ]),
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            border: pw.TableBorder.all(),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/students_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Export students data to Excel
  Future<File> exportStudentsToExcel({
    required List<Student> students,
    required bool isUrdu,
    String? title,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];

    // Header row
    final headers = isUrdu
        ? ['فیس', 'حیثیت', 'کلاس', 'داخلے کی تاریخ', 'نام']
        : ['Name', 'Admission Date', 'Class', 'Status', 'Fee'];

    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    // Data rows
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final row = i + 1;

      if (isUrdu) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(student.fee);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(student.status);
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value =
            TextCellValue(
                'Class ${String.fromCharCode(64 + (student.classId ?? 1))}');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value =
            TextCellValue(
                DateFormat('yyyy-MM-dd').format(student.admissionDate));
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(student.name);
      } else {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(student.name);
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                DateFormat('yyyy-MM-dd').format(student.admissionDate));
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value =
            TextCellValue(
                'Class ${String.fromCharCode(64 + (student.classId ?? 1))}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(student.status);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(student.fee);
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }

    // Save Excel file
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/students_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  /// Export teachers data to PDF
  Future<File> exportTeachersToPdf({
    required List<Teacher> teachers,
    required bool isUrdu,
    String? title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title ?? (isUrdu ? 'اساتذہ کی فہرست' : 'Teachers List'),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              isUrdu
                  ? 'کل اساتذہ: ${teachers.length}'
                  : 'Total Teachers: ${teachers.length}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // Table
          pw.TableHelper.fromTextArray(
            context: context,
            data: <List<String>>[
              // Header row
              isUrdu
                  ? ['تنخواہ', 'حیثیت', 'موبائل', 'شروع کی تاریخ', 'نام']
                  : ['Name', 'Starting Date', 'Mobile', 'Status', 'Salary'],
              // Data rows
              ...teachers.map((teacher) => isUrdu
                  ? [
                      teacher.salary.toString(),
                      teacher.status,
                      teacher.mobile,
                      teacher.startingDate != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(teacher.startingDate!)
                          : '-',
                      teacher.name,
                    ]
                  : [
                      teacher.name,
                      teacher.startingDate != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(teacher.startingDate!)
                          : '-',
                      teacher.mobile,
                      teacher.status,
                      teacher.salary.toString(),
                    ]),
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            border: pw.TableBorder.all(),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/teachers_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Export teachers data to Excel
  Future<File> exportTeachersToExcel({
    required List<Teacher> teachers,
    required bool isUrdu,
    String? title,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Teachers'];

    // Header row
    final headers = isUrdu
        ? ['تنخواہ', 'حیثیت', 'موبائل', 'شروع کی تاریخ', 'نام']
        : ['Name', 'Starting Date', 'Mobile', 'Status', 'Salary'];

    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    // Data rows
    for (int i = 0; i < teachers.length; i++) {
      final teacher = teachers[i];
      final row = i + 1;

      if (isUrdu) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(teacher.salary.toString());
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(teacher.status);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(teacher.mobile);
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value =
            TextCellValue(teacher.startingDate != null
                ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!)
                : '-');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(teacher.name);
      } else {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(teacher.name);
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(teacher.startingDate != null
                ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!)
                : '-');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(teacher.mobile);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(teacher.status);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(teacher.salary.toString());
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }

    // Save Excel file
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/teachers_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  /// Export budget data to PDF
  Future<File> exportBudgetToPdf({
    required List<Income> incomes,
    required List<Expenditure> expenditures,
    required bool isUrdu,
    String? title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title ?? (isUrdu ? 'بجٹ رپورٹ' : 'Budget Report'),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isUrdu
                      ? 'کل آمدنی: ${incomes.fold(0.0, (sum, income) => sum + income.amount)}'
                      : 'Total Income: ${incomes.fold(0.0, (sum, income) => sum + income.amount)}',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  isUrdu
                      ? 'کل خرچ: ${expenditures.fold(0.0, (sum, exp) => sum + exp.amount)}'
                      : 'Total Expenditure: ${expenditures.fold(0.0, (sum, exp) => sum + exp.amount)}',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  isUrdu
                      ? 'بقیہ: ${incomes.fold(0.0, (sum, income) => sum + income.amount) - expenditures.fold(0.0, (sum, exp) => sum + exp.amount)}'
                      : 'Balance: ${incomes.fold(0.0, (sum, income) => sum + income.amount) - expenditures.fold(0.0, (sum, exp) => sum + exp.amount)}',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Income Table
          if (incomes.isNotEmpty) ...[
            pw.Text(
              isUrdu ? 'آمدنی' : 'Income',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                // Header row
                isUrdu
                    ? ['رقم', 'تاریخ', 'تفصیل']
                    : ['Description', 'Date', 'Amount'],
                // Data rows
                ...incomes.map((income) => isUrdu
                    ? [
                        income.amount.toString(),
                        income.date,
                        income.description,
                      ]
                    : [
                        income.description,
                        income.date,
                        income.amount.toString(),
                      ]),
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.green),
              border: pw.TableBorder.all(),
              cellHeight: 30,
            ),
            pw.SizedBox(height: 20),
          ],

          // Expenditure Table
          if (expenditures.isNotEmpty) ...[
            pw.Text(
              isUrdu ? 'خرچ' : 'Expenditure',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                // Header row
                isUrdu
                    ? ['رقم', 'تاریخ', 'تفصیل']
                    : ['Description', 'Date', 'Amount'],
                // Data rows
                ...expenditures.map((expenditure) => isUrdu
                    ? [
                        expenditure.amount.toString(),
                        expenditure.date,
                        expenditure.description,
                      ]
                    : [
                        expenditure.description,
                        expenditure.date,
                        expenditure.amount.toString(),
                      ]),
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.red),
              border: pw.TableBorder.all(),
              cellHeight: 30,
            ),
          ],
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/budget_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Export budget data to Excel
  Future<File> exportBudgetToExcel({
    required List<Income> incomes,
    required List<Expenditure> expenditures,
    required bool isUrdu,
    String? title,
  }) async {
    final excel = Excel.createExcel();

    // Income sheet
    final incomeSheet = excel['Income'];
    final incomeHeaders =
        isUrdu ? ['رقم', 'تاریخ', 'تفصیل'] : ['Description', 'Date', 'Amount'];

    for (int i = 0; i < incomeHeaders.length; i++) {
      incomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(incomeHeaders[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    for (int i = 0; i < incomes.length; i++) {
      final income = incomes[i];
      final row = i + 1;

      if (isUrdu) {
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(income.amount.toString());
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(income.date);
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(income.description);
      } else {
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(income.description);
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(income.date);
        incomeSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(income.amount.toString());
      }
    }

    // Expenditure sheet
    final expenditureSheet = excel['Expenditure'];
    final expenditureHeaders =
        isUrdu ? ['رقم', 'تاریخ', 'تفصیل'] : ['Description', 'Date', 'Amount'];

    for (int i = 0; i < expenditureHeaders.length; i++) {
      expenditureSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(expenditureHeaders[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#F44336'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
    }

    for (int i = 0; i < expenditures.length; i++) {
      final expenditure = expenditures[i];
      final row = i + 1;

      if (isUrdu) {
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(expenditure.amount.toString());
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(expenditure.date);
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(expenditure.description);
      } else {
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(expenditure.description);
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(expenditure.date);
        expenditureSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(expenditure.amount.toString());
      }
    }

    // Summary sheet
    final summarySheet = excel['Summary'];
    final totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
    final totalExpenditure =
        expenditures.fold(0.0, (sum, exp) => sum + exp.amount);
    final balance = totalIncome - totalExpenditure;

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue(isUrdu ? 'کل آمدنی' : 'Total Income')
      ..cellStyle = CellStyle(bold: true);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = DoubleCellValue(totalIncome);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue(isUrdu ? 'کل خرچ' : 'Total Expenditure')
      ..cellStyle = CellStyle(bold: true);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
        .value = DoubleCellValue(totalExpenditure);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = TextCellValue(isUrdu ? 'بقیہ' : 'Balance')
      ..cellStyle = CellStyle(bold: true);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = DoubleCellValue(balance);

    // Auto-fit columns
    for (final sheet in [incomeSheet, expenditureSheet, summarySheet]) {
      for (int i = 0; i < 5; i++) {
        sheet.setColumnWidth(i, 15);
      }
    }

    // Save Excel file
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/budget_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  /// Export AI query results
  Future<File> exportAIResults({
    required List<dynamic> data,
    required String module,
    required bool isUrdu,
    required String format, // 'pdf' or 'excel'
  }) async {
    switch (module) {
      case 'students':
        final students = data.cast<Student>();
        return format == 'pdf'
            ? await exportStudentsToPdf(students: students, isUrdu: isUrdu)
            : await exportStudentsToExcel(students: students, isUrdu: isUrdu);

      case 'teachers':
        final teachers = data.cast<Teacher>();
        return format == 'pdf'
            ? await exportTeachersToPdf(teachers: teachers, isUrdu: isUrdu)
            : await exportTeachersToExcel(teachers: teachers, isUrdu: isUrdu);

      case 'budget':
        final incomes = data.whereType<Income>().toList();
        final expenditures = data.whereType<Expenditure>().toList();
        return format == 'pdf'
            ? await exportBudgetToPdf(
                incomes: incomes, expenditures: expenditures, isUrdu: isUrdu)
            : await exportBudgetToExcel(
                incomes: incomes, expenditures: expenditures, isUrdu: isUrdu);

      default:
        throw Exception('Unsupported module: $module');
    }
  }
}
