import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/access_control.dart';
import '../providers/language_provider.dart';
import '../services/database_service.dart';
import '../models/class_model.dart';
import 'create_class_screen.dart';
import 'class_students_screen.dart';
import '../widgets/voice_input_button.dart';
import '../services/enhanced_search_service.dart';
import 'home_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import '../utils/file_utils.dart';
import 'package:excel/excel.dart' as excel_lib;

class ClassesListScreen extends StatefulWidget {
  const ClassesListScreen({Key? key}) : super(key: key);

  @override
  _ClassesListScreenState createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  // DatabaseService is static, no instance needed
  final EnhancedSearchService _searchService = EnhancedSearchService();
  List<ClassModel> _classes = [];
  List<ClassModel> _filteredClasses = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(() {
      final value = _searchController.text.trim();
      if (value.isEmpty) {
        setState(() { _filteredClasses = List<ClassModel>.from(_classes); });
        return;
      }
      if (int.tryParse(value) == null) {
        _filterClasses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() { _isLoading = true; });
    try {
      print('🔍 Loading classes from database...');
      final data = await DatabaseService.getAllClasses();
      print('✅ Loaded ${data.length} classes from database');
      if (data.isNotEmpty) {
        print('📋 First class: ${data.first.name} (ID: ${data.first.id})');
      }
      setState(() {
        _classes = data;
        _filteredClasses = _classes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading classes: $e');
      setState(() { _isLoading = false; });
    }
  }

  void _filterClasses() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() { _filteredClasses = List<ClassModel>.from(_classes); });
      return;
    }
    int? foundMonthNum;
    int? foundYear;
    final months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
      'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
      '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
    ];
    final monthMap = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      '01': 1, '02': 2, '03': 3, '04': 4, '05': 5, '06': 6, '07': 7, '08': 8, '09': 9, '10': 10, '11': 11, '12': 12,
      '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, '11': 11, '12': 12
    };
    for (String month in months) {
      if (query.contains(month.toLowerCase())) {
        foundMonthNum = monthMap[month.toLowerCase()];
        break;
      }
    }
    final yearRegex = RegExp(r'(20\d{2}|\b\d{2}\b)');
    final yearMatch = yearRegex.firstMatch(query);
    if (yearMatch != null) {
      final yearStr = yearMatch.group(0)!;
      if (yearStr.length == 4) {
        foundYear = int.tryParse(yearStr);
      } else if (yearStr.length == 2) {
        foundYear = 2000 + int.tryParse(yearStr)!;
      }
    }
    setState(() {
      _filteredClasses = _classes.where((cls) {
        final name = cls.name.toLowerCase();
        final idString = cls.id?.toString() ?? '';
        final dateStr = cls.createdAt.toLowerCase();
        // Always match if the query matches the ID exactly
        if (query.isNotEmpty && idString == query) {
          return true;
        }
        // Direct text matching
        if (name.contains(query) || dateStr.contains(query)) {
          return true;
        }
        // --- Robust month/year matching ---
        if (foundMonthNum != null || foundYear != null) {
          bool dateMatch = true;
          if (foundMonthNum != null) {
            final monthStr = '-${foundMonthNum.toString().padLeft(2, '0')}-';
            if (!dateStr.contains(monthStr)) dateMatch = false;
          }
          if (foundYear != null) {
            if (!dateStr.contains(foundYear.toString())) dateMatch = false;
          }
          if (dateMatch) return true;
        }
        return false;
      }).toList();
    });
  }

  void _customSearch() {
    final query = _searchController.text.trim();
    print('Search query: $query');
    print('All class IDs: ' + _classes.map((cls) => cls.id?.toString() ?? 'null').join(', '));
    print('All createdAt: ' + _classes.map((cls) => cls.createdAt).join(', '));
    if (query.isEmpty) {
      setState(() { _filteredClasses = List<ClassModel>.from(_classes); });
      return;
    }
    final isInt = int.tryParse(query) != null;
    if (isInt) {
      // First, look for exact ID match
      final idMatch = _classes.where((cls) => (cls.id?.toString() ?? '') == query).toList();
      print('idMatch count: ${idMatch.length}');
      if (idMatch.isNotEmpty) {
        setState(() { _filteredClasses = idMatch; });
        return;
      }
      // If not found, look for year match in createdAt
      final yearMatch = _classes.where((cls) {
        if (cls.createdAt.length >= 4) {
          final year = cls.createdAt.substring(0, 4);
          return year == query;
        }
        return false;
      }).toList();
      print('yearMatch count: ${yearMatch.length}');
      if (yearMatch.isNotEmpty) {
        setState(() { _filteredClasses = yearMatch; });
        return;
      }
      // If still not found, fall back to normal logic
    }
    _filterClasses();
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('confirm_delete')),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${classModel.name} کلاس کو حذف کرنا چاہتے ہیں؟'
          : 'Are you sure you want to delete class ${classModel.name}?'),
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
        await DatabaseService.deleteClass(classModel.id!);
        await _loadClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'کلاس کامیابی سے حذف ہو گئی'
              : 'Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'کلاس حذف کرنے میں خرابی'
              : 'Error deleting class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markClassAsGraduate(ClassModel classModel) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isUrdu ? 'گریجویٹ کے طور پر نشان زد کریں' : 'Mark as Graduate'),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${classModel.name} کے تمام فعال طلباء کو گریجویٹ کے طور پر نشان زد کرنا چاہتے ہیں؟'
          : 'Are you sure you want to mark all active students of ${classModel.name} as Graduate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.isUrdu ? 'نشان زد کریں' : 'Mark'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get all students in this class
        final allStudents = await DatabaseService.getAllStudents();
        final classStudents = allStudents.where((data) {
          final studentClass = data['class']?.toString().trim() ?? '';
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          return studentClass == classModel.name && status == 'active';
        }).toList();

        // Update each student's status to Graduate
        for (var student in classStudents) {
          await DatabaseService.updateAdmission(
            student['id'].toString(),
            {'status': 'Graduate'}
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? '${classStudents.length} طلباء کو گریجویٹ کے طور پر نشان زد کیا گیا'
              : '${classStudents.length} students marked as Graduate'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طلباء کو نشان زد کرنے میں خرابی'
              : 'Error marking students'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markClassAsStruckOff(ClassModel classModel) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isUrdu ? 'خارج شدہ کے طور پر نشان زد کریں' : 'Mark as Struck Off'),
        content: Text(languageProvider.isUrdu 
          ? 'کیا آپ واقعی ${classModel.name} کے تمام فعال طلباء کو خارج شدہ کے طور پر نشان زد کرنا چاہتے ہیں؟'
          : 'Are you sure you want to mark all active students of ${classModel.name} as Struck Off?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.isUrdu ? 'نشان زد کریں' : 'Mark'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get all students in this class
        final allStudents = await DatabaseService.getAllStudents();
        final classStudents = allStudents.where((data) {
          final studentClass = data['class']?.toString().trim() ?? '';
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          return studentClass == classModel.name && status == 'active';
        }).toList();

        // Update each student's status to Struck Off
        for (var student in classStudents) {
          await DatabaseService.updateAdmission(
            student['id'].toString(),
            {'status': 'Struck Off'}
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? '${classStudents.length} طلباء کو خارج شدہ کے طور پر نشان زد کیا گیا'
              : '${classStudents.length} students marked as Struck Off'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu 
              ? 'طلباء کو نشان زد کرنے میں خرابی'
              : 'Error marking students'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isUrdu ? 'کلاسز کی فہرست' : 'Classes List',
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
                              ? 'کلاس کا نام، ID، یا تاریخ تلاش کریں... (مثال: Class A، 2024، June)'
                              : 'Search by class name, ID, or date... (e.g. Class A, 2024, June)',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            setState(() { _filteredClasses = List<ClassModel>.from(_classes); });
                            return;
                          }
                          if (int.tryParse(value.trim()) == null) {
                            _filterClasses();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.arrow_forward, color: Color(0xFF1976D2)),
                      tooltip: languageProvider.isUrdu ? 'تلاش کریں' : 'Search',
                      onPressed: () {
                        _customSearch();
                      },
                    ),
                    VoiceInputButton(
                      isUrdu: languageProvider.isUrdu,
                      onResult: (text) {
                        _searchController.text = text;
                        _filterClasses();
                      },
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
                            ? '${_filteredClasses.length} کلاسز ملیں'
                            : '${_filteredClasses.length} classes found',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              // Classes List
              Expanded(
                child: _filteredClasses.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              languageProvider.isUrdu 
                                  ? 'کوئی کلاس نہیں ملی'
                                  : 'No classes found',
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
                        itemCount: _filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classModel = _filteredClasses[index];
                          return _buildClassCard(classModel, languageProvider);
                        },
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
          await runIfAdmin(context, () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateClassScreen(),
              ),
            );
            await _loadClasses();
          });
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: languageProvider.getText('create_class'),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel, LanguageProvider languageProvider) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Directionality(
        textDirection: languageProvider.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Color(0xFF1976D2),
          child: Icon(Icons.school, color: Colors.white),
        ),
        title: Text(
          classModel.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: languageProvider.isUrdu
              ? [
                  Text(languageProvider.isUrdu ? 'تاریخ تخلیق: ${classModel.createdAt}' : 'Created: ${classModel.createdAt}', style: TextStyle(color: Colors.grey[600])),
                  Text('ID: ${classModel.id}', style: TextStyle(color: Colors.grey[600])),
                ]
              : [
                  Text('ID: ${classModel.id}', style: TextStyle(color: Colors.grey[600])),
                  Text(languageProvider.isUrdu ? 'تاریخ تخلیق: ${classModel.createdAt}' : 'Created: ${classModel.createdAt}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_ios, color: Color(0xFF1976D2), size: 20),
            SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await runIfAdmin(context, () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateClassScreen(classToEdit: classModel),
                        ),
                      );
                      await _loadClasses();
                    });
                    break;
                  case 'delete':
                    await runIfAdmin(context, () async { await _deleteClass(classModel); });
                    break;
                  case 'graduate':
                    await runIfAdmin(context, () async { await _markClassAsGraduate(classModel); });
                    break;
                  case 'struck_off':
                    await runIfAdmin(context, () async { await _markClassAsStruckOff(classModel); });
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(languageProvider.isUrdu ? 'ترمیم' : 'Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text(languageProvider.isUrdu ? 'حذف' : 'Delete'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'graduate',
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.green),
                      SizedBox(width: 8),
                      Text(languageProvider.isUrdu ? 'گریجویٹ کے طور پر نشان زد کریں' : 'Mark as Graduate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'struck_off',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(languageProvider.isUrdu ? 'خارج شدہ کے طور پر نشان زد کریں' : 'Mark as Struck Off'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassStudentsScreen(classModel: classModel),
            ),
          );
        },
        ),
      ),
    );
  }

  void _downloadPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Classes List', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Created At', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ..._filteredClasses.map((cls) => pw.TableRow(
                    children: [
                      pw.Text(cls.id?.toString() ?? ''),
                      pw.Text(cls.name),
                      pw.Text(cls.createdAt),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    FileUtils.downloadPdf(bytes, 'classes.pdf');
  }

  void _downloadExcel() async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Classes'];
    // Header
    sheet.appendRow([
      excel_lib.TextCellValue('ID'),
      excel_lib.TextCellValue('Name'),
      excel_lib.TextCellValue('Created At'),
    ]);
    // Data
    for (final cls in _filteredClasses) {
      sheet.appendRow([
        excel_lib.TextCellValue(cls.id?.toString() ?? ''),
        excel_lib.TextCellValue(cls.name),
        excel_lib.TextCellValue(cls.createdAt),
      ]);
    }
    final bytes = excel.encode()!;
    FileUtils.downloadExcel(bytes, 'classes.xlsx');
  }
} 