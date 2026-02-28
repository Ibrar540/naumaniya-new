import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/database_helper.dart';
import '../providers/language_provider.dart';
import '../models/teacher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import '../utils/file_utils.dart';
import 'teacher_enter_data_screen.dart';
import '../widgets/voice_input_button.dart';
import '../services/enhanced_search_service.dart';
import 'home_screen.dart';
import '../providers/teacher_provider.dart';
import 'dart:ui' as dart_ui;

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({Key? key}) : super(key: key);

  @override
  _TeachersScreenState createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _nameController = TextEditingController();
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedStatus;
  final List<String> _allowedStatuses = ['Active', 'Left'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = List.generate(10, (i) => (DateTime.now().year - 5 + i).toString());
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Teacher> _teachers = [];
  List<Teacher> _filteredTeachers = [];
  final TeacherProvider _teacherProvider = TeacherProvider();
  final EnhancedSearchService _searchService = EnhancedSearchService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() { _isLoading = true; });
    try {
      final teachersData = await _teacherProvider.fetchTeachers();
      setState(() {
        _teachers = teachersData;
        _filteredTeachers = _teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _filterTeachers() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;
    setState(() { _isLoading = true; });
    try {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _filteredTeachers = List<Teacher>.from(_teachers);
          _isLoading = false;
        });
        return;
      }
      final isInt = int.tryParse(query) != null;
      final months = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december',
        'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
      ];
      final monthMap = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      String? foundMonth;
      for (String month in months) {
        if (query.contains(month)) {
          foundMonth = month;
          break;
        }
      }
      final yearRegex = RegExp(r'(20\d{2})');
      final yearMatch = yearRegex.firstMatch(query);
      String? foundYear = yearMatch != null ? yearMatch.group(0) : null;

      // If integer, first check for ID match
      if (isInt && foundMonth == null && foundYear == null) {
        final idMatch = _teachers.where((teacher) => (teacher.id?.toString() ?? '') == query).toList();
        if (idMatch.isNotEmpty) {
          setState(() { _filteredTeachers = idMatch; _isLoading = false; });
          return;
        }
      }

      setState(() {
        _filteredTeachers = _teachers.where((teacher) {
          final teacherMonth = teacher.startingDate?.month;
          final teacherYear = teacher.startingDate?.year.toString();
          bool monthMatch = false;
          bool yearMatch = false;
          if (foundMonth != null && teacherMonth != null) {
            monthMatch = teacherMonth == monthMap[foundMonth];
          }
          if (foundYear != null && teacherYear != null) {
            yearMatch = teacherYear == foundYear;
          }
          // Month-year combo
          if (foundMonth != null && foundYear != null) {
            return monthMatch && yearMatch;
          }
          // Month only
          if (foundMonth != null) {
            return monthMatch;
          }
          // Year only
          if (foundYear != null) {
            return yearMatch;
          }
          // Fallback: normal filter
          final idStr = (teacher.id?.toString() ?? '');
          return teacher.name.toLowerCase().contains(query) ||
                 teacher.mobile.toLowerCase().contains(query) ||
                 (teacher.status ?? '').toLowerCase().contains(query) ||
                 idStr == query;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering teachers: $e');
      setState(() {
        _filteredTeachers = _teachers;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filterTeachers();
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('confirm_delete')),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${teacher.name} کو حذف کرنا چاہتے ہیں؟'
          : 'Are you sure you want to delete ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.getText('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teacherProvider.deleteTeacher(teacher.id!);
        await _loadTeachers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'استاد کامیابی سے حذف ہو گیا'
              : 'Teacher deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'استاد حذف کرنے میں خرابی'
              : 'Error deleting teacher'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  languageProvider.isUrdu ? 'اساتذہ کی فہرست' : 'Teachers List',
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
                        pw.Text(languageProvider.isUrdu ? 'ID' : 'ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'نام' : 'Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'موبائل' : 'Mobile', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'تنخواہ' : 'Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'حیثیت' : 'Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'شروع کرنے کی تاریخ' : 'Starting Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Data rows
                    ..._filteredTeachers.map((teacher) => pw.TableRow(
                      children: [
                        pw.Text(teacher.id?.toString() ?? ''),
                        pw.Text(teacher.name),
                        pw.Text(teacher.mobile),
                        pw.Text(teacher.salary.toString()),
                        pw.Text(teacher.status.isEmpty ? 'Active' : teacher.status),
                        pw.Text(teacher.startingDate != null ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!) : '-'),
                      ],
                    )).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/teachers_list.pdf');
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
    final excel = Excel.createExcel();
    final sheet = excel['Teachers'];
    // Header
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('نام'),
      TextCellValue('موبائل'),
      TextCellValue('تنخواہ'),
      TextCellValue('حیثیت'),
      TextCellValue('شروع کرنے کی تاریخ'),
    ]);
    // Data
    for (final teacher in _filteredTeachers) {
      sheet.appendRow([
        TextCellValue(teacher.id?.toString() ?? ''),
        TextCellValue(teacher.name),
        TextCellValue(teacher.mobile),
        TextCellValue(teacher.salary.toString()),
        TextCellValue(teacher.status.isEmpty ? 'Active' : teacher.status),
        TextCellValue(teacher.startingDate != null ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!) : '-'),
      ]);
    }
    final bytes = excel.encode()!;
    FileUtils.downloadExcel(bytes, 'teachers.xlsx');
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isUrdu ? 'اساتذہ کی فہرست' : 'Teachers List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1976D2),
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              },
              tooltip: 'Home',
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            tooltip: languageProvider.getText('switch_language'),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.arrow_downward),
            tooltip: 'Download',
            onSelected: (value) {
              if (value == 'pdf') {
                _downloadPdf();
              } else if (value == 'excel') {
                _downloadExcel();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('PDF')],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [Icon(Icons.grid_on, color: Colors.green), SizedBox(width: 8), Text('Excel')],
                ),
              ),
            ],
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF1976D2), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: languageProvider.isUrdu
                              ? 'تلاش کریں: نام، موبائل، حیثیت، یا ID'
                              : 'Search by: Name, Mobile, Status, or ID',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: VoiceInputButton(
                            isUrdu: languageProvider.isUrdu,
                            onResult: (text) {
                              _searchController.text = text;
                              _filterTeachers();
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            setState(() { _filteredTeachers = List<Teacher>.from(_teachers); });
                            return;
                          }
                          if (int.tryParse(value.trim()) == null) {
                            _filterTeachers();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
              
              // Loading Indicator
              if (_isLoading)
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 16),
                      Text(
                        languageProvider.isUrdu ? 'تلاش کر رہا ہے...' : 'Searching...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              
              // Results Count
              if (!_isLoading && _searchController.text.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        languageProvider.isUrdu 
                            ? '${_filteredTeachers.length} اساتذہ ملے'
                            : '${_filteredTeachers.length} teachers found',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              // Teachers List
              Expanded(
                child: _filteredTeachers.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              languageProvider.isUrdu 
                                  ? 'کوئی استاد نہیں ملا'
                                  : 'No teachers found',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                languageProvider.isUrdu 
                                    ? 'اپنا تلاش کا سوال تبدیل کریں'
                                    : 'Try changing your search query',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: InteractiveViewer(
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.8,
                            maxScale: 2.5,
                            child: DataTable(
                                border: TableBorder.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                                columns: languageProvider.isUrdu
                                  ? [
                                      DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('عمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text('چھوڑنے کی تاریخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text('شروع کرنے کی تاریخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('حیثیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('تنخواہ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 120, child: Text('موبائل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 150, child: Text('نام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                      DataColumn(label: Container(alignment: Alignment.center, width: 60, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                    ]
                                  : [
                              DataColumn(label: Container(alignment: Alignment.center, width: 60, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 150, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 120, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('Salary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text('Starting Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text('Leaving Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                              DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                                    ],
                            rows: _filteredTeachers.map((teacher) {
                              final cells = [
                                DataCell(Container(width: 60, alignment: Alignment.center, child: Text(teacher.id?.toString() ?? '', textAlign: TextAlign.center))),
                                DataCell(Container(width: 150, alignment: Alignment.center, child: Text(teacher.name, textAlign: TextAlign.center))),
                                DataCell(Container(width: 120, alignment: Alignment.center, child: Text(teacher.mobile, textAlign: TextAlign.center))),
                                DataCell(Container(width: 100, alignment: Alignment.center, child: Text(teacher.salary.toString(), textAlign: TextAlign.center))),
                                DataCell(Container(
                                  width: 100,
                                  alignment: Alignment.center,
                                  child: Text(
                                    (teacher.status == null || teacher.status.trim().isEmpty) ? 'Active' : teacher.status,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )),
                                DataCell(Container(
                                  width: 140,
                                  alignment: Alignment.center,
                                  child: Text(
                                    teacher.startingDate != null
                                        ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!)
                                        : '-',
                                    textAlign: TextAlign.center,
                                  ),
                                )),
                                DataCell(Container(
                                  width: 140,
                                  alignment: Alignment.center,
                                  child: Text(
                                    teacher.leavingDate.isNotEmpty && teacher.leavingDate != 'none'
                                        ? teacher.leavingDate
                                        : '-',
                                    textAlign: TextAlign.center,
                                  ),
                                )),
                                DataCell(Container(
                                  width: 100,
                                  alignment: Alignment.center,
                                  child: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'edit':
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TeacherEnterDataScreen(teacher: teacher),
                                            ),
                                          );
                                          await _loadTeachers();
                                          break;
                                        case 'left':
                                          await _updateStatus(teacher, 'Left');
                                          break;
                                        case 'delete':
                                          await _deleteTeacher(teacher);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.orange, size: 16),
                                            SizedBox(width: 8),
                                            Text(languageProvider.getText('edit')),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'left',
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text(languageProvider.isUrdu ? 'چھوڑ دیا' : 'Left'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: 16),
                                            SizedBox(width: 8),
                                            Text(languageProvider.getText('delete')),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Icon(Icons.more_vert),
                                  ),
                                )),
                              ];
                              return DataRow(cells: languageProvider.isUrdu ? cells.reversed.toList() : cells);
                            }).toList(),
                              ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherEnterDataScreen(),
            ),
          );
          await _loadTeachers();
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: languageProvider.getText('add_teacher'),
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher, LanguageProvider languageProvider) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: teacher.status.toLowerCase() == 'active' 
              ? Colors.green 
              : Colors.red,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          teacher.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'ID: ${teacher.id}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              languageProvider.isUrdu 
                  ? 'موبائل: ${teacher.mobile}'
                  : 'Mobile: ${teacher.mobile}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              languageProvider.isUrdu 
                  ? 'تنخواہ: ${teacher.salary}'
                  : 'Salary: ${teacher.salary}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              languageProvider.isUrdu 
                  ? 'حیثیت: ${teacher.status.isEmpty ? 'Active' : teacher.status}'
                  : 'Status: ${teacher.status.isEmpty ? 'Active' : teacher.status}',
              style: TextStyle(
                color: (teacher.status.isEmpty ? 'Active' : teacher.status).toLowerCase() == 'active' 
                    ? Colors.green 
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (teacher.startingDate != null)
              Text(
                languageProvider.isUrdu 
                    ? 'شروع کی تاریخ: ${DateFormat('yyyy-MM-dd').format(teacher.startingDate!)}'
                    : 'Starting Date: ${DateFormat('yyyy-MM-dd').format(teacher.startingDate!)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherEnterDataScreen(teacher: teacher),
                  ),
                );
                await _loadTeachers();
                break;
              case 'left':
                await _updateStatus(teacher, 'Left');
                break;
              case 'delete':
                await _deleteTeacher(teacher);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(languageProvider.getText('edit')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'left',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text(languageProvider.isUrdu ? 'چھوڑ دیا' : 'Left'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text(languageProvider.getText('delete')),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherEnterDataScreen(teacher: teacher),
            ),
          );
          await _loadTeachers();
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.transparent; // Neutral - no color
      case 'left':
        return Colors.red;
      case 'graduate':
        return Colors.green;
      default:
        // Unknown status treated as active (neutral)
        return Colors.transparent;
    }
  }

  // Returns the sum of all salary values for the currently filtered teachers (active in the selected period)
  int getTotalSalary({int? month, int? year}) {
    return _filteredTeachers.fold(0, (sum, teacher) {
      final salary = teacher.salary;
      if (year != null) {
        DateTime? startingDate;
        DateTime? leavingDate;
        try { startingDate = teacher.startingDate; } catch (_) {}
        try { leavingDate = teacher.leavingDate.isNotEmpty ? DateTime.parse(teacher.leavingDate) : null; } catch (_) {}
        if (startingDate == null || startingDate.year > year) return sum;
        int endMonth = 12;
        if (teacher.status.toLowerCase() == 'left' && leavingDate != null && leavingDate.year == year) {
          endMonth = leavingDate.month;
        }
        if (month != null && month > endMonth) return sum;
        return sum + salary;
      }
      return sum + salary;
    });
  }

  Future<void> _updateStatus(Teacher teacher, String newStatus) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('confirm_status_change')),
        content: Text(languageProvider.isUrdu 
          ? 'آیا آپ واقعی ${teacher.name} کو حیثیت ${newStatus} کرنا چاہتے ہیں؟'
          : 'Are you sure you want to change ${teacher.name} status to ${newStatus}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.getText('change')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teacherProvider.updateTeacherStatus(teacher.id!, newStatus);
        await _loadTeachers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'استاد کامیابی سے حیثیت تبدیل ہو گیا'
              : 'Teacher status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'استاد حیثیت تبدیل کرنے میں خرابی'
              : 'Error updating teacher status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 