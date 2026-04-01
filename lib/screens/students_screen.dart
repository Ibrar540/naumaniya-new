import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/language_provider.dart';
import '../models/student.dart';
import 'home_screen.dart';

class StudentsScreen extends StatefulWidget {
  final int? classId;
  final String? className;
  const StudentsScreen({Key? key, this.classId, this.className}) : super(key: key);
  
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() { _isLoading = true; });
    try {
      List<Map<String, dynamic>> studentsData;
      if (widget.className != null) {
        // Filter students by class name
        print('🔍 Loading students for class: ${widget.className}');
        final allStudents = await DatabaseService.getAllStudents();
        studentsData = allStudents.where((data) {
          final studentClass = data['class']?.toString().trim() ?? '';
          final classMatch = studentClass == widget.className;
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          // Only exclude if status is explicitly "struck off" or "graduate"
          final notExcluded = status != 'struck off' && status != 'graduate';
          print('Student: ${data['name']}, Class: "$studentClass", Expected: "${widget.className}", Match: $classMatch, Status: "$status", NotExcluded: $notExcluded');
          return classMatch && notExcluded;
        }).toList();
        print('✅ Found ${studentsData.length} students in class ${widget.className}');
        
        // Sort by ID in ascending order (oldest first for roll number assignment)
        studentsData.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
        
        // Assign roll numbers: oldest (index 0) gets 1, next gets 2, etc.
        for (int i = 0; i < studentsData.length; i++) {
          studentsData[i]['roll_no'] = i + 1;
        }
        
        // Now sort by roll_no in descending order for display (highest at top)
        studentsData.sort((a, b) => (b['roll_no'] ?? 0).compareTo(a['roll_no'] ?? 0));
      } else {
        // Get all students
        studentsData = await DatabaseService.getAllStudents();
      }
      setState(() {
        _students = studentsData.map((data) => Student.fromMap(data)).toList();
        _filteredStudents = _students;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading students: $e');
      setState(() { _isLoading = false; });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = List<Student>.from(_students);
      });
      return;
    }
    
    setState(() {
      _filteredStudents = _students.where((student) {
        final rollNo = (student.rollNo?.toString() ?? '').toLowerCase();
        final id = (student.id?.toString() ?? '').toLowerCase();
        final name = student.name.toLowerCase();
        final fatherName = student.fatherName.toLowerCase();
        final mobile = student.mobile.toLowerCase();
        final fee = student.fee.toLowerCase();
        
        return rollNo.contains(query) ||
               id.contains(query) ||
               name.contains(query) ||
               fatherName.contains(query) ||
               mobile.contains(query) ||
               fee.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className != null 
            ? '${widget.className} - ${languageProvider.isUrdu ? 'طلباء' : 'Students'}'
            : (languageProvider.isUrdu ? 'طلباء' : 'Students'),
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
                              ? 'تلاش کریں...'
                              : 'Search by name, ID, mobile, fee...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
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
              
              // Results Count
              if (_searchController.text.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        languageProvider.isUrdu 
                            ? '${_filteredStudents.length} طلباء ملے'
                            : '${_filteredStudents.length} students found',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              // Table
              Expanded(
                child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            SizedBox(height: 24),
                            Text(
                              languageProvider.isUrdu ? 'کوئی طلباء نہیں ملے' : 'No students found',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
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
                            minScale: 0.5,
                            maxScale: 2.5,
                            child: _buildDataTable(languageProvider),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(LanguageProvider languageProvider) {
    final isUrdu = languageProvider.isUrdu;
    
    return DataTable(
      border: TableBorder.all(color: Colors.grey[400]!, width: 1),
      columnSpacing: 8,
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 40,
      columns: isUrdu
          ? [
              DataColumn(label: Container(width: 70, alignment: Alignment.center, child: Text('اعمال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 65, alignment: Alignment.center, child: Text('فیس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 85, alignment: Alignment.center, child: Text('موبائل نمبر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 100, alignment: Alignment.center, child: Text('والد کا نام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 100, alignment: Alignment.center, child: Text('نام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 40, alignment: Alignment.center, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 50, alignment: Alignment.center, child: Text('رول نمبر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
            ]
          : [
              DataColumn(label: Container(width: 50, alignment: Alignment.center, child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 40, alignment: Alignment.center, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 100, alignment: Alignment.center, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 100, alignment: Alignment.center, child: Text('Father Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 85, alignment: Alignment.center, child: Text('Mobile No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 65, alignment: Alignment.center, child: Text('Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
              DataColumn(label: Container(width: 70, alignment: Alignment.center, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center))),
            ],
      rows: _filteredStudents.map((student) {
        final cells = [
          DataCell(Container(width: 50, alignment: Alignment.center, child: Text(student.rollNo?.toString() ?? '-', style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(width: 40, alignment: Alignment.center, child: Text(student.id?.toString() ?? '-', style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(width: 100, alignment: Alignment.center, child: Text(student.name, style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(width: 100, alignment: Alignment.center, child: Text(student.fatherName, style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(width: 85, alignment: Alignment.center, child: Text(student.mobile, style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(width: 65, alignment: Alignment.center, child: Text(student.fee, style: TextStyle(fontSize: 11), textAlign: TextAlign.center))),
          DataCell(Container(
            width: 70,
            alignment: Alignment.center,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await _editStudent(student);
                    break;
                  case 'delete':
                    await _deleteStudent(student);
                    break;
                  case 'graduate':
                    await _updateStatus(student, 'Graduate');
                    break;
                  case 'struck_off':
                    await _updateStatus(student, 'Struck Off');
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 16), SizedBox(width: 8), Text(languageProvider.isUrdu ? 'ترمیم' : 'Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text(languageProvider.isUrdu ? 'حذف' : 'Delete')])),
                PopupMenuItem(value: 'graduate', child: Row(children: [Icon(Icons.school, color: Colors.green, size: 16), SizedBox(width: 8), Text(languageProvider.isUrdu ? 'گریجویٹ' : 'Graduate')])),
                PopupMenuItem(value: 'struck_off', child: Row(children: [Icon(Icons.cancel, color: Colors.orange, size: 16), SizedBox(width: 8), Text(languageProvider.isUrdu ? 'خارج شدہ' : 'Struck Off')])),
              ],
            ),
          )),
        ];
        return DataRow(cells: isUrdu ? cells.reversed.toList() : cells);
      }).toList(),
    );
  }

  Future<void> _editStudent(Student student) async {
    // Navigate to edit screen (you'll need to implement this)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality - to be implemented')),
    );
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
        await DatabaseService.deleteAdmission(student.id!.toString());
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

  Future<void> _updateStatus(Student student, String newStatus) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isUrdu ? 'حیثیت تبدیل کریں' : 'Change Status'),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${student.name} کی حیثیت "$newStatus" میں تبدیل کرنا چاہتے ہیں؟'
          : 'Are you sure you want to change ${student.name}\'s status to "$newStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.isUrdu ? 'تبدیل کریں' : 'Change'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.updateAdmission(student.id!.toString(), {'status': newStatus});
        await _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'حیثیت کامیابی سے تبدیل ہو گئی'
              : 'Status changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'حیثیت تبدیل کرنے میں خرابی'
              : 'Error changing status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'struck off':
        return Colors.red;
      case 'graduate':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
