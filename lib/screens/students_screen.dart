import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../db/database_helper.dart';
import '../providers/language_provider.dart';
import '../models/student.dart';
import 'student_enter_data_screen.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/student_image_widget.dart';
import '../widgets/student_image_picker.dart';
import '../services/enhanced_search_service.dart';
import 'home_screen.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import '../utils/file_utils.dart';
import 'dart:ui' as dart_ui;

class StudentsScreen extends StatefulWidget {
  final int? classId;
  const StudentsScreen({Key? key, this.classId}) : super(key: key);
  
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _nameController = TextEditingController();
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedStatus;
  final List<String> _allowedStatuses = ['Active', 'Stuckup', 'Graduate'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = List.generate(10, (i) => (DateTime.now().year - 5 + i).toString());
  final _searchController = TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final EnhancedSearchService _searchService = EnhancedSearchService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      List<Map<String, dynamic>> studentsData;
      if (widget.classId != null) {
        // Filter students by class
        studentsData = await _dbHelper.getStudentsByClass(widget.classId!);
        // Filter out stuckup and graduate students (robust)
        studentsData = studentsData.where((data) {
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          return status != 'stuckup' && status != 'graduate';
        }).toList();
      } else {
        // Get all students
        studentsData = await _dbHelper.getStudents();
      }
      // Debug print
      print('Loaded students: ' + studentsData.toString());
      setState(() {
        _students = studentsData.map((data) => Student.fromMap(data)).toList();
        _filteredStudents = _students;
      });
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _filterStudents() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;
    setState(() {
      _isLoading = true;
    });
    try {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _filteredStudents = List<Student>.from(_students);
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _filteredStudents = _students.where((student) {
          final rollNoStr = (student.rollNo ?? '').toString();
          final idStr = (student.id ?? '').toString();
          final feeStr = (student.fee ?? '').toString();
          return rollNoStr.contains(query) ||
                 idStr.contains(query) ||
                 student.name.toLowerCase().contains(query) ||
                 student.fatherName.toLowerCase().contains(query) ||
                 feeStr.contains(query);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _filteredStudents = _students;
        _isLoading = false;
      });
    }
  }

  void _saveStudent(int index) {
    setState(() {
      _students[index].isSaved = true;
    });
  }

  void _applyFilters() {
    _filterStudents();
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
                  languageProvider.isUrdu ? 'طلباء کی فہرست' : 'Students List',
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
                        pw.Text(languageProvider.isUrdu ? 'نام' : 'Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'والد کا نام' : 'Father Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'موبائل' : 'Mobile', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'فیس' : 'Fee', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(languageProvider.isUrdu ? 'حیثیت' : 'Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Data rows
                    ..._filteredStudents.map((student) => pw.TableRow(
                      children: [
                        pw.Text(student.name),
                        pw.Text(student.fatherName),
                        pw.Text(student.mobile),
                        pw.Text(student.fee),
                        pw.Text(student.status),
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
      final file = File('${output.path}/students_list.pdf');
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
    final sheet = excel['Students'];
    // Header
    sheet.appendRow([
      TextCellValue('رول نمبر'),
      TextCellValue('ID'),
      TextCellValue('نام'),
      TextCellValue('والد کا نام'),
      TextCellValue('موبائل'),
      TextCellValue('فیس'),
      TextCellValue('حیثیت'),
      TextCellValue('داخلہ کی تاریخ'),
    ]);
    // Data
    for (final student in _filteredStudents) {
      sheet.appendRow([
        TextCellValue(student.rollNo?.toString() ?? ''),
        TextCellValue(student.id?.toString() ?? ''),
        TextCellValue(student.name),
        TextCellValue(student.fatherName),
        TextCellValue(student.mobile),
        TextCellValue(student.fee),
        TextCellValue(student.status),
        TextCellValue(student.admissionDate?.toString() ?? ''),
      ]);
    }
    final bytes = excel.encode()!;
    FileUtils.downloadExcel(bytes, 'students.xlsx');
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isUrdu ? 'طلباء' : 'Students',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
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
      body: Column(
        children: [
          // Responsive Search and Filter Section
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: languageProvider.isUrdu ? 'تلاش کریں...' : 'Search...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: isMobile ? 20 : 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    // Voice Input Button
                    VoiceInputButton(
                      isUrdu: languageProvider.isUrdu,
                      onResult: (text) {
                        _searchController.text = text;
                        _filterStudents();
                      },
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                // Responsive Filter Row
                if (isMobile) ...[
                  // Mobile: Stacked filters
                  _buildFilterDropdown(
                    context,
                    value: _selectedStatus,
                    items: _allowedStatuses,
                    hint: languageProvider.isUrdu ? 'حیثیت' : 'Status',
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _applyFilters();
                    },
                    isMobile: true,
                  ),
                  SizedBox(height: 8),
                  _buildFilterDropdown(
                    context,
                    value: _selectedMonth,
                    items: _months,
                    hint: languageProvider.isUrdu ? 'مہینہ' : 'Month',
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                      _applyFilters();
                    },
                    isMobile: true,
                  ),
                  SizedBox(height: 8),
                  _buildFilterDropdown(
                    context,
                    value: _selectedYear,
                    items: _years,
                    hint: languageProvider.isUrdu ? 'سال' : 'Year',
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                      _applyFilters();
                    },
                    isMobile: true,
                  ),
                ] else ...[
                  // Desktop/Tablet: Horizontal filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          context,
                          value: _selectedStatus,
                          items: _allowedStatuses,
                          hint: languageProvider.isUrdu ? 'حیثیت' : 'Status',
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                            _applyFilters();
                          },
                          isMobile: false,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown(
                          context,
                          value: _selectedMonth,
                          items: _months,
                          hint: languageProvider.isUrdu ? 'مہینہ' : 'Month',
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value;
                            });
                            _applyFilters();
                          },
                          isMobile: false,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown(
                          context,
                          value: _selectedYear,
                          items: _years,
                          hint: languageProvider.isUrdu ? 'سال' : 'Year',
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value;
                            });
                            _applyFilters();
                          },
                          isMobile: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: isMobile ? 64 : 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: isMobile ? 16 : 24),
                        Text(
                          languageProvider.isUrdu ? 'کوئی طلباء نہیں ملے' : 'No students found',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.8,
                      maxScale: 2.5,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(context, student, index, isMobile);
                    },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentEnterDataScreen(classId: widget.classId),
            ),
          );
          if (result == true) {
            _loadStudents();
          }
        },
        child: Icon(Icons.add, size: isMobile ? 24 : 28),
        tooltip: languageProvider.isUrdu ? 'نیا طالب علم شامل کریں' : 'Add New Student',
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, size: isMobile ? 20 : 24),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student, int index, bool isMobile) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Directionality(
          textDirection: languageProvider.isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Image and Basic Info Row
            Row(
              children: [
                // Student Image
                StudentImageWidget(
                  imageUrl: student.imageUrl,
                  size: isMobile ? 60 : 80,
                ),
                SizedBox(width: isMobile ? 12 : 16),
                
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${languageProvider.isUrdu ? 'والد' : 'Father'}: ${student.fatherName}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${languageProvider.isUrdu ? 'موبائل' : 'Mobile'}: ${student.mobile}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.status),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  ),
                  child: Text(
                    student.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Additional Info Row
            Row(
                textDirection: languageProvider.isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
                children: languageProvider.isUrdu
                  ? [
                      Expanded(child: _buildInfoItem(context, 'Roll No', student.rollNo?.toString() ?? '-', Icons.confirmation_number, isMobile)),
                SizedBox(width: isMobile ? 8 : 16),
                      Expanded(child: _buildInfoItem(context, 'Fee', student.fee, Icons.attach_money, isMobile)),
                    ]
                  : [
                      Expanded(child: _buildInfoItem(context, 'Fee', student.fee, Icons.attach_money, isMobile)),
                      SizedBox(width: isMobile ? 8 : 16),
                      Expanded(child: _buildInfoItem(context, 'Roll No', student.rollNo?.toString() ?? '-', Icons.confirmation_number, isMobile)),
              ],
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    languageProvider.isUrdu ? 'ترمیم' : 'Edit',
                    Icons.edit,
                    Colors.blue,
                    () => _editStudent(student),
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    languageProvider.isUrdu ? 'حذف' : 'Delete',
                    Icons.delete,
                    Colors.red,
                    () => _deleteStudent(student),
                    isMobile,
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isMobile ? 16 : 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isMobile,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isMobile ? 16 : 20),
      label: Text(
        label,
        style: TextStyle(fontSize: isMobile ? 12 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 8 : 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.transparent; // Neutral - no color
      case 'stackup':
        return Colors.red;
      case 'graduate':
        return Colors.green;
      default:
        // Unknown status treated as active (neutral)
        return Colors.transparent;
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('confirm_delete')),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${student.name} کو حذف کرنا چاہتے ہیں؟'
          : 'Are you sure you want to delete ${student.name}?'),
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
        await _dbHelper.deleteStudent(student.id!);
        await _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طالب علم کامیابی سے حذف ہو گیا'
              : 'Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طالب علم حذف کرنے میں خرابی'
              : 'Error deleting student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editStudent(Student student) async {
    // Navigate to student enter data screen for editing
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEnterDataScreen(studentToEdit: student),
      ),
    );
    
    if (result == true) {
      await _loadStudents();
    }
  }

  Future<void> _updateStatus(Student student, String newStatus) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('confirm_status_change')),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${student.name} کو حیثیت بدلنا چاہتے ہیں؟'
          : 'Are you sure you want to change the status of ${student.name}?'),
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
        await _dbHelper.updateStudentStatus(student.id!, newStatus);
        await _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طالب علم کامیابی سے حیثیت بدل ہو گیا'
              : 'Student status changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طالب علم حیثیت بدل کرنے میں خرابی'
              : 'Error changing student status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Returns the sum of all fee values for the currently filtered students (of the class)
  int getTotalCollectableFee() {
    return _filteredStudents.fold(0, (sum, student) {
      final fee = int.tryParse(student.fee) ?? 0;
      return sum + fee;
    });
  }

  void _customSearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() { _filteredStudents = List<Student>.from(_students); });
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
    // Check for month name in query
    String? foundMonth;
    for (String month in months) {
      if (query.contains(month)) {
        foundMonth = month;
        break;
      }
    }
    // Check for year in query
    final yearRegex = RegExp(r'(20\d{2})');
    final yearMatch = yearRegex.firstMatch(query);
    String? foundYear = yearMatch != null ? yearMatch.group(0) : null;

    if (isInt && foundMonth == null && foundYear == null) {
      // Integer only: ID or year
      final idMatch = _students.where((student) => (student.id?.toString() ?? '') == query).toList();
      if (idMatch.isNotEmpty) {
        setState(() { _filteredStudents = idMatch; });
        return;
      }
      // Year only
      final yearMatchList = _students.where((student) => student.admissionDate.year.toString() == query).toList();
      if (yearMatchList.isNotEmpty) {
        setState(() { _filteredStudents = yearMatchList; });
        return;
      }
      // Fallback
      _filterStudents();
      return;
    }

    // Month, year, or month-year search
    setState(() {
      _filteredStudents = _students.where((student) {
        final studentMonth = student.admissionDate.month;
        final studentYear = student.admissionDate.year.toString();
        bool monthMatch = false;
        bool yearMatch = false;
        if (foundMonth != null) {
          monthMatch = studentMonth == monthMap[foundMonth];
        }
        if (foundYear != null) {
          yearMatch = studentYear == foundYear;
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
        final name = student.name.toLowerCase();
        final fatherName = student.fatherName.toLowerCase();
        final idStr = (student.id?.toString() ?? '');
        return name.contains(query) || fatherName.contains(query) || idStr == query;
      }).toList();
    });
  }
} 