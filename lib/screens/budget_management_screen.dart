// DEBUG: This is the file being edited! If you see this, the right file is open.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/section.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import 'package:excel/excel.dart' hide Border;
import '../providers/language_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../utils/file_utils.dart';
import '../providers/budget_provider.dart';
import 'home_screen.dart';

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({Key? key}) : super(key: key);
  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  String? _selectedType; // 'income' or 'expenditure'
  String? _sectionAction; // 'create' or 'view'
  Section? _selectedSection;
  String? _sectionSubScreen; // 'enter' or 'view'

  final _sectionNameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  final BudgetProvider _budgetProvider = BudgetProvider();
  List<Section> _sections = [];
  bool _loadingSections = false;
  List<Income> _sectionIncomes = [];
  List<Expenditure> _sectionExpenditures = [];
  bool _loadingSectionData = false;
  String _searchQuery = '';
  double? _searchSum;
  String _sectionSearchQuery = '';
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _sectionData = [];
  List<Map<String, dynamic>> _filteredSectionData = [];

  Future<void> _loadSections() async {
    setState(() { _loadingSections = true; });
    final data = await _budgetProvider.fetchSections();
    setState(() {
      _sections = data;
      _loadingSections = false;
    });
  }

  Future<void> _createSection() async {
    final name = _sectionNameController.text.trim();
    if (name.isEmpty) return;
    await _budgetProvider.addSection(Section(name: name, institution: 'madrasa', type: _selectedType ?? 'income'));
    _sectionNameController.clear();
    await _loadSections();
    setState(() { _sectionAction = null; });
  }

  Future<void> _saveSectionData() async {
    final desc = _descController.text.trim();
    final amount = _amountController.text.trim();
    final date = _dateController.text.trim();
    if (desc.isEmpty || amount.isEmpty || date.isEmpty) return;
    if (_selectedType == 'income') {
      await _budgetProvider.addIncome(Income(description: desc, amount: double.tryParse(amount) ?? 0.0, date: date));
    } else {
      await _budgetProvider.addExpenditure(Expenditure(description: desc, amount: double.tryParse(amount) ?? 0.0, date: date));
    }
    _descController.clear();
    _amountController.clear();
    _dateController.clear();
    await _loadSectionData();
    setState(() {});
  }

  Future<void> _loadSectionData() async {
    setState(() { _loadingSectionData = true; });
    final data = await _budgetProvider.isAuthenticated
      ? await _budgetProvider.fetchIncomes() // or fetchExpenditures based on _selectedType
      : await _budgetProvider.fetchIncomes(); // fallback for now
    // TODO: Filter by sectionId and type
    setState(() {
      _sectionData = []; // TODO: Map to expected format
      _filteredSectionData = [];
      _loadingSectionData = false;
    });
  }

  Future<void> _editSection(Section section) async {
    _sectionNameController.text = section.name;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text('Edit Section'),
        content: TextField(
          controller: _sectionNameController,
          decoration: InputDecoration(labelText: 'Section Name'),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: _boldButtonStyle,
            onPressed: () async {
              final newName = _sectionNameController.text.trim();
              if (newName.isNotEmpty) {
                await _budgetProvider.updateSection(
                  Section(
                    id: section.id!,
                    name: newName,
                    institution: section.institution,
                    type: section.type,
                  ),
                );
                await _loadSections();
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
            ),
          ],
        ),
      );
    _sectionNameController.clear();
  }

  Future<void> _deleteSection(Section section) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text('Delete Section'),
        content: Text('Are you sure you want to delete this section?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: _boldButtonStyle.copyWith(backgroundColor: MaterialStateProperty.all(Colors.red)),
            onPressed: () async {
              await _budgetProvider.deleteSection(section.id!);
              await _loadSections();
              Navigator.pop(context);
            },
            child: Text('Delete'),
            ),
          ],
        ),
      );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _searchSum = null;
    });
    
    if (_searchQuery.isEmpty) {
      _filteredSectionData = List<Map<String, dynamic>>.from(_sectionData);
      return;
    }
    
    final lowerQuery = _searchQuery.toLowerCase();
    final months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
      'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
      'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
    ];
    final monthMap = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'جنوری': 1, 'فروری': 2, 'مارچ': 3, 'اپریل': 4, 'مئی': 5, 'جون': 6,
      'جولائی': 7, 'اگست': 8, 'ستمبر': 9, 'اکتوبر': 10, 'نومبر': 11, 'دسمبر': 12
    };
    
    final yearRegex = RegExp(r'(20\d{2})');
    final monthRegex = RegExp(months.join('|'), caseSensitive: false);
    int? foundMonthNum;
    int? foundYear;
    final currentYear = DateTime.now().year;
    
    // Find month
    final monthMatch = monthRegex.firstMatch(lowerQuery);
    if (monthMatch != null) {
      final foundMonth = monthMatch.group(0)!.toLowerCase();
      foundMonthNum = monthMap[foundMonth];
    }
    
    // Find year
    final yearMatch = yearRegex.firstMatch(lowerQuery);
    if (yearMatch != null) {
      foundYear = int.tryParse(yearMatch.group(0)!);
    }
    
    // If only month is found, use current year
    if (foundMonthNum != null && foundYear == null) {
      foundYear = currentYear;
    }
    
    final isNumeric = double.tryParse(_searchQuery) != null;
    
    final filtered = _sectionData.where((row) {
      final desc = (row['description'] ?? '').toString().toLowerCase();
      final amount = (row['amount'] ?? '').toString().toLowerCase();
      final date = (row['date'] ?? '').toString().toLowerCase();
      final dateObj = DateTime.tryParse(row['date'] ?? '');
      
      bool matches = false;
      
      // Check if query matches description, amount, or date string
      if (desc.contains(lowerQuery) || amount.contains(lowerQuery) || date.contains(lowerQuery)) {
        matches = true;
      }
      
      // Check month and year match
      if (foundMonthNum != null && foundYear != null && dateObj != null) {
        if (dateObj.month == foundMonthNum && dateObj.year == foundYear) {
          matches = true;
        }
      }
      // Check only year match
      else if (foundYear != null && dateObj != null && dateObj.year == foundYear) {
        matches = true;
      }
      // Check only month match (should not happen with current logic, but keeping for safety)
      else if (foundMonthNum != null && dateObj != null && dateObj.month == foundMonthNum) {
        matches = true;
      }
      
      // Check numeric match
      if (isNumeric) {
        if (amount.contains(_searchQuery) || (dateObj != null && dateObj.year.toString().contains(_searchQuery))) {
          matches = true;
        }
      }
      
      return matches;
    }).toList();
    
    setState(() {
      _filteredSectionData = filtered;
      
      // Calculate sum for month and year search
      if (foundMonthNum != null && foundYear != null) {
        _searchSum = filtered.fold<double>(0, (sum, row) {
          final dateObj = DateTime.tryParse(row['date'] ?? '');
          if (dateObj != null && dateObj.month == foundMonthNum && dateObj.year == foundYear) {
            return sum + (double.tryParse(row['amount'] ?? '') ?? 0);
          }
          return sum;
        });
      } else if (foundYear != null) {
        _searchSum = filtered.fold<double>(0, (sum, row) {
          final dateObj = DateTime.tryParse(row['date'] ?? '');
          if (dateObj != null && dateObj.year == foundYear) {
            return sum + (double.tryParse(row['amount'] ?? '') ?? 0);
          }
          return sum;
        });
      }
    });
  }

  // Helper for bold button text
  ButtonStyle get _boldButtonStyle => ElevatedButton.styleFrom(
    textStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    minimumSize: Size(400, 60),
    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 8,
  );

  // Helper for section card colors/icons
  Color get _sectionCardColor => _selectedType == 'income' ? Colors.green : Colors.red;
  IconData get _sectionCardIcon => _selectedType == 'income' ? Icons.trending_up : Icons.trending_down;

  void _editSectionData(dynamic row) {
    // TODO: Implement edit section data logic
  }

  void _deleteSectionData(dynamic row) {
    // TODO: Implement delete section data logic
  }

  Future<void> _downloadPdf() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    try {
      final pdf = pw.Document();
      
      // Add title
      pdf.addPage(
        pw.Page(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  languageProvider.isUrdu 
                    ? '${_selectedSection?.name} - ${_selectedType == 'income' ? 'آمدنی' : 'خرچ'}'
                    : '${_selectedSection?.name} - ${_selectedType == 'income' ? 'Income' : 'Expenditure'}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      children: [
                        pw.Text(languageProvider.isUrdu ? 'تفصیل' : 'Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'رقم' : 'Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'تاریخ' : 'Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Data rows
                    ..._filteredSectionData.map((row) => pw.TableRow(
                      children: [
                        pw.Text(row['description'] ?? ''),
                        pw.Text(row['amount'] ?? ''),
                        pw.Text(row['date'] ?? ''),
                      ],
                    )).toList(),
                  ],
                ),
                if (_searchSum != null) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '${languageProvider.getText('total_amount')}: ${_searchSum!.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName = '${_selectedSection?.name}_${_selectedType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      await OpenFile.open(file.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ ہو گیا' : 'PDF downloaded successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ میں خرابی' : 'Error downloading PDF: $e'),
        ),
      );
    }
  }

  void _downloadExcel() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final excelDoc = Excel.createExcel();
    final sheet = excelDoc['${_selectedType == 'income' ? 'Income' : 'Expenditure'}'];
    
    // Header
    sheet.appendRow([
      TextCellValue('تفصیل'),
      TextCellValue('رقم'),
      TextCellValue('تاریخ'),
    ]);
    
    // Data
    for (final row in _filteredSectionData) {
      sheet.appendRow([
        TextCellValue(row['description'] ?? ''),
        TextCellValue(row['amount'] ?? ''),
        TextCellValue(row['date'] ?? ''),
      ]);
    }
    
    // Add total if search sum exists
    if (_searchSum != null) {
      sheet.appendRow([]); // Empty row
      sheet.appendRow([
        TextCellValue(languageProvider.getText('total_amount')),
        TextCellValue(_searchSum!.toStringAsFixed(2)),
        TextCellValue(''),
      ]);
    }
    
    final bytes = excelDoc.encode()!;
    // Web download
    final fileName = '${_selectedSection?.name}_${_selectedType}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    FileUtils.downloadExcel(bytes, fileName);
  }

  void _showDownloadDialog() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('download')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(languageProvider.isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ کریں' : 'Download PDF'),
              onTap: () {
                Navigator.pop(context);
                _downloadPdf();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text(languageProvider.isUrdu ? 'ایکسسل ڈاؤن لوڈ کریں' : 'Download Excel'),
              onTap: () {
                Navigator.pop(context);
                _downloadExcel();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).maybePop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.getText('budget_management')),
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Home',
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade100, Colors.green.shade200],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 350),
                      child: ElevatedButton(
                        style: _boldButtonStyle,
                        onPressed: () => setState(() { _selectedType = 'income'; }),
                        child: Text(languageProvider.getText('general_income')),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 350),
                      child: ElevatedButton(
                        style: _boldButtonStyle,
                        onPressed: () => setState(() { _selectedType = 'expenditure'; }),
                        child: Text(languageProvider.getText('general_expenditure')),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      );
    }
}
