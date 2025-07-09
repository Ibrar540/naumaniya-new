import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import '../utils/file_utils.dart';
import 'admission_form_screen.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/voice_input_button.dart';
import 'home_screen.dart';
import 'package:excel/excel.dart' hide Border;

class AdmissionViewScreen extends StatefulWidget {
  const AdmissionViewScreen({Key? key}) : super(key: key);

  @override
  _AdmissionViewScreenState createState() => _AdmissionViewScreenState();
}

class _AdmissionViewScreenState extends State<AdmissionViewScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _admissions = [];
  List<Map<String, dynamic>> _filteredAdmissions = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    try {
      final admissionsData = await _dbHelper.getAdmissions();
      // Sort by ID in descending order to show newest entries first
      admissionsData.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      setState(() {
        _admissions = admissionsData;
        _filteredAdmissions = admissionsData;
      });
    } catch (e) {
      // print('Error loading admissions: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _showSuggestions = false;
      if (_searchQuery.isEmpty) {
        _filteredAdmissions = List<Map<String, dynamic>>.from(_admissions);
        return;
      }
      final lowerQuery = _searchQuery.toLowerCase();

      // --- Robust month/year parsing ---
      int? foundMonthNum;
      int? foundYear;
      final months = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december',
        'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
        'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
        'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
        '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12',
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
      ];
      final monthMap = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
        'جنوری': 1, 'فروری': 2, 'مارچ': 3, 'اپریل': 4, 'مئی': 5, 'جون': 6,
        'جولائی': 7, 'اگست': 8, 'ستمبر': 9, 'اکتوبر': 10, 'نومبر': 11, 'دسمبر': 12,
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        '01': 1, '02': 2, '03': 3, '04': 4, '05': 5, '06': 6, '07': 7, '08': 8, '09': 9, '10': 10, '11': 11, '12': 12,
        '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, '11': 11, '12': 12
      };
      // Find month (anywhere in query)
      for (String month in months) {
        if (lowerQuery.contains(month.toLowerCase())) {
          foundMonthNum = monthMap[month.toLowerCase()];
          break;
        }
      }
      // Find year (4-digit or 2-digit)
      final yearRegex = RegExp(r'(20\d{2}|\b\d{2}\b)');
      final yearMatch = yearRegex.firstMatch(lowerQuery);
      if (yearMatch != null) {
        final yearStr = yearMatch.group(0)!;
        if (yearStr.length == 4) {
          foundYear = int.tryParse(yearStr);
        } else if (yearStr.length == 2) {
          foundYear = 2000 + int.tryParse(yearStr)!;
        }
      }

      _filteredAdmissions = _admissions.where((adm) {
        final studentName = (adm['student_name']?.toString() ?? '').toLowerCase();
        final fatherName = (adm['father_name']?.toString() ?? '').toLowerCase();
        final fatherMobile = (adm['father_mobile']?.toString() ?? '').toLowerCase();
        final address = (adm['address']?.toString() ?? '').toLowerCase();
        final fee = (adm['fee']?.toString() ?? '').toLowerCase();
        final className = (adm['class']?.toString() ?? '').toLowerCase();
        final status = (adm['status']?.toString() ?? '').toLowerCase();
        final admissionDateStr = (adm['admission_date']?.toString() ?? '').toLowerCase();
        final stackupDateStr = (adm['stackup_date']?.toString() ?? '').toLowerCase();
        final graduationDateStr = (adm['graduation_date']?.toString() ?? '').toLowerCase();
        final idString = adm['id']?.toString() ?? '';

        bool matches = false;

        // Always match if the query matches the ID exactly
        if (_searchQuery.isNotEmpty && idString == _searchQuery) {
          return true;
        }

        // Direct text matching
        if (studentName.contains(lowerQuery) || 
            fatherName.contains(lowerQuery) || 
            fatherMobile.contains(lowerQuery) ||
            address.contains(lowerQuery) ||
            fee.contains(lowerQuery) ||
            className.contains(lowerQuery) ||
            status.contains(lowerQuery) ||
            admissionDateStr.contains(lowerQuery) ||
            stackupDateStr.contains(lowerQuery) ||
            graduationDateStr.contains(lowerQuery)) {
          matches = true;
        }
        // Partial name matching (first name, last name)
        final nameParts = studentName.split(' ');
        for (String part in nameParts) {
          if (part.contains(lowerQuery)) {
            matches = true;
            break;
          }
        }
        // --- Robust month/year matching ---
        if (foundMonthNum != null || foundYear != null) {
          // Try to match month/year/month-year in admission_date
          final dateStr = admissionDateStr;
          bool dateMatch = true;
          if (foundMonthNum != null) {
            final monthStr = '-${foundMonthNum.toString().padLeft(2, '0')}-';
            if (!dateStr.contains(monthStr)) dateMatch = false;
          }
          if (foundYear != null) {
            if (!dateStr.contains(foundYear.toString())) dateMatch = false;
          }
          if (dateMatch) matches = true;
        }
        return matches;
      }).toList();
    });
  }

  Future<void> _deleteAdmission(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Admission'),
        content: Text('Are you sure you want to delete this admission record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // Get student_id before deleting admission
        String? studentId;
        final admissions = await _dbHelper.getAdmissions();
        final admission = admissions.where((a) => a['id'] == id).firstOrNull;
        if (admission != null) {
          studentId = admission['student_id'] as String?;
        }
        
        // Delete admission record
        await _dbHelper.deleteAdmission(id);
        
        // Delete corresponding student record
        if (studentId != null) {
          await _dbHelper.deleteStudentByStudentId(studentId);
        }
        
        await _loadAdmissions();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Admission and student record deleted.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Admission Records', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Student Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Father Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Class', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Fee', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Admission Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ..._filteredAdmissions.map((adm) => pw.TableRow(
                    children: [
                      pw.Text(adm['id']?.toString() ?? ''),
                      pw.Text(adm['student_name']?.toString() ?? ''),
                      pw.Text(adm['father_name']?.toString() ?? ''),
                      pw.Text(adm['class']?.toString() ?? ''),
                      pw.Text(adm['fee']?.toString() ?? ''),
                      pw.Text(adm['status']?.toString() ?? ''),
                      pw.Text(adm['admission_date']?.toString() ?? ''),
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
    FileUtils.downloadPdf(bytes, 'admissions.pdf');
  }

  void _downloadExcel() async {
    // Use the excel package (add to pubspec.yaml if not present)
    final excel = Excel.createExcel();
    final sheet = excel['Admissions'];
    // Header
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Student Name'),
      TextCellValue('Father Name'),
      TextCellValue('Class'),
      TextCellValue('Fee'),
      TextCellValue('Status'),
      TextCellValue('Admission Date'),
    ]);
    // Data
    for (final adm in _filteredAdmissions) {
      sheet.appendRow([
        TextCellValue(adm['id']?.toString() ?? ''),
        TextCellValue(adm['student_name']?.toString() ?? ''),
        TextCellValue(adm['father_name']?.toString() ?? ''),
        TextCellValue(adm['class']?.toString() ?? ''),
        TextCellValue(adm['fee']?.toString() ?? ''),
        TextCellValue(adm['status']?.toString() ?? ''),
        TextCellValue(adm['admission_date']?.toString() ?? ''),
      ]);
    }
    final bytes = excel.encode()!;
    FileUtils.downloadExcel(bytes, 'admissions.xlsx');
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.transparent; // Neutral - no color
      case 'stackup':
        return Colors.red;
      case 'graduated':
        return Colors.green;
      default:
        // Unknown status treated as active (neutral)
        return Colors.transparent;
    }
  }

  Color _getRowBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'stuckup':
        // Medium red: blend of Colors.red and Colors.red.withOpacity(0.1)
        return Color.lerp(Colors.red.withOpacity(0.1), Colors.red, 0.5)!;
      case 'graduated':
        // Medium green: blend of Colors.green and Colors.green.withOpacity(0.1)
        return Color.lerp(Colors.green.withOpacity(0.1), Colors.green, 0.5)!;
      case 'active':
      default:
        return Colors.transparent; // Neutral - no background color
    }
  }

  void _customSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() { _filteredAdmissions = List<Map<String, dynamic>>.from(_admissions); });
      return;
    }
    final isInt = int.tryParse(query) != null;
    if (isInt) {
      // First, look for exact ID match
      final idMatch = _admissions.where((adm) => (adm['id']?.toString() ?? '') == query).toList();
      if (idMatch.isNotEmpty) {
        setState(() { _filteredAdmissions = idMatch; });
        return;
      }
      // If not found, look for year match in admission_date
      final yearMatch = _admissions.where((adm) {
        final date = adm['admission_date']?.toString() ?? '';
        if (date.length >= 4) {
          final year = date.substring(0, 4);
          return year == query;
        }
        return false;
      }).toList();
      if (yearMatch.isNotEmpty) {
        setState(() { _filteredAdmissions = yearMatch; });
        return;
      }
      // If still not found, fall back to normal logic
    }
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
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
        title: Text(languageProvider.isUrdu ? 'داخلہ ریکارڈز' : 'Admission Records'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
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
          // Single search bar for manual search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: languageProvider.isUrdu
                          ? 'تلاش کریں: نام، والد کا نام، ماہ، سال، اسٹیٹس، یا آئی ڈی'
                          : 'Search by: Name, Father Name, Month, Year, Status, or ID',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: VoiceInputButton(
                        isUrdu: languageProvider.isUrdu,
                        onResult: (text) {
                          _searchController.text = text;
                          _applyFilters();
                        },
                      ),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        setState(() { _filteredAdmissions = List<Map<String, dynamic>>.from(_admissions); });
                        return;
                      }
                      // Only run live search for non-integer input
                      if (int.tryParse(value.trim()) == null) {
                        _applyFilters();
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
              ],
            ),
          ),
          // Admissions List
          Expanded(
            child: _filteredAdmissions.isEmpty
                ? Center(
                    child: Text(
                    'No admissions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      // DataTable columns with RTL/LTR support for Urdu/English
                      columns: [
                            DataColumn(label: Container(alignment: Alignment.center, width: 60, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 80, child: Text(languageProvider.isUrdu ? 'تصویر' : 'Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 150, child: Text(languageProvider.isUrdu ? 'نام' : 'Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 150, child: Text(languageProvider.isUrdu ? 'والد کا نام' : "Father's Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 120, child: Text(languageProvider.isUrdu ? 'موبائل' : 'Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 150, child: Text(languageProvider.isUrdu ? 'پتہ' : 'Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 80, child: Text(languageProvider.isUrdu ? 'فیس' : 'Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text(languageProvider.isUrdu ? 'کلاس' : 'Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text(languageProvider.isUrdu ? 'حیثیت' : 'Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text(languageProvider.isUrdu ? 'تاریخِ داخلہ' : 'Admission Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text(languageProvider.isUrdu ? 'تاریخِ اسٹک اپ' : 'Stackup Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 140, child: Text(languageProvider.isUrdu ? 'تاریخِ فراغت' : 'Graduation Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                        DataColumn(label: Container(alignment: Alignment.center, width: 100, child: Text(languageProvider.isUrdu ? 'عمل' : 'Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
                            ],
                            rows: _filteredAdmissions.map((adm) {
                        // Define cells in LTR order (left to right)
                        final cells = [
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['id']?.toString() ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(
                              alignment: Alignment.center,
                              child: adm['imageUrl'] != null && adm['imageUrl'].isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      adm['imageUrl'],
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 36, color: Colors.grey[400]),
                                    ),
                                  )
                                : Icon(Icons.person, size: 36, color: Colors.grey[400]),
                            )),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['student_name'] ?? '-', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500)))),
                          DataCell(Container(alignment: Alignment.center, child: Text(adm['father_name'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['father_mobile'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['address'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['fee']?.toString() ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['class'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['status'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['admission_date'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['stackup_date'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(Container(alignment: Alignment.center, child: Text(adm['graduation_date'] ?? '-', textAlign: TextAlign.center))),
                            DataCell(
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdmissionFormScreen(
                                          admission: adm,
                                          isEdit: true,
                                        ),
                                      ),
                                    ).then((_) => _loadAdmissions());
                                  }
                                  if (value == 'delete') {
                                    _deleteAdmission(adm['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                      Text(languageProvider.isUrdu ? 'ترمیم' : 'Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                      Text(languageProvider.isUrdu ? 'حذف کریں' : 'Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ];
                        
                        return DataRow(cells: languageProvider.isUrdu ? cells.reversed.toList() : cells);
                    }).toList(),
                    dataRowHeight: 80,
                    headingRowHeight: 60,
                    columnSpacing: 0,
                    horizontalMargin: 0,
                    border: TableBorder.all(
                      color: Colors.grey.shade700,
                      width: 2,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
} 