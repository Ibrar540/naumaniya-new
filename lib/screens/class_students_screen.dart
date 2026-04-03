import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/database_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import '../utils/file_utils.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../models/class_model.dart';
import 'student_enter_data_screen.dart';
import 'students_screen.dart';
import 'home_screen.dart';

class ClassStudentsScreen extends StatefulWidget {
  final ClassModel classModel;
  
  const ClassStudentsScreen({Key? key, required this.classModel}) : super(key: key);
  
  @override
  _ClassStudentsScreenState createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.classModel.name,
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
            onSelected: (value) async {
              if (value == 'pdf') {
                await _downloadPdf();
              } else if (value == 'excel') {
                await _downloadExcel();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('PDF')]),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(children: [Icon(Icons.grid_on, color: Colors.green), SizedBox(width: 8), Text('Excel')]),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class name header
                Text(
                  widget.classModel.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  languageProvider.isUrdu ? 'طلباء کا انتظام' : 'Student Management',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 28),

                // Enter Data card
                _buildOptionCard(
                  context,
                  icon: Icons.add_circle_outline,
                  iconColor: Colors.green,
                  title: languageProvider.getText('enter_data'),
                  subtitle: languageProvider.isUrdu ? 'نیا طالب علم شامل کریں' : 'Add a new student record',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentEnterDataScreen(classId: widget.classModel.id!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // View Data card
                _buildOptionCard(
                  context,
                  icon: Icons.table_chart_outlined,
                  iconColor: Color(0xFF1976D2),
                  title: languageProvider.getText('view_data'),
                  subtitle: languageProvider.isUrdu ? 'موجودہ طلباء کی فہرست دیکھیں' : 'View existing student records',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentsScreen(
                        classId: widget.classModel.id,
                        className: widget.classModel.name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    try {
      final allStudents = await DatabaseService.getAllStudents();
      final students = allStudents.where((data) {
        final studentClass = data['class']?.toString().trim() ?? '';
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final notExcluded = status != 'struck off' && status != 'graduate';
        return studentClass == widget.classModel.name && notExcluded;
      }).toList();

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${widget.classModel.name} - Students', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Table(border: pw.TableBorder.all(), children: [
                  pw.TableRow(children: [pw.Text('ID'), pw.Text('Name'), pw.Text('Father'), pw.Text('Mobile'), pw.Text('Fee')]),
                  ...students.map((s) => pw.TableRow(children: [
                    pw.Text(s['id']?.toString() ?? ''),
                    pw.Text(s['name'] ?? ''),
                    pw.Text(s['father_name'] ?? ''),
                    pw.Text(s['mobile'] ?? ''),
                    pw.Text(s['fee']?.toString() ?? ''),
                  ])),
                ])
              ],
            );
          },
        ),
      );
      final bytes = await pdf.save();
      await FileUtils.downloadPdf(bytes, '${widget.classModel.name}_students.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }

  Future<void> _downloadExcel() async {
    try {
      final allStudents = await DatabaseService.getAllStudents();
      final students = allStudents.where((data) {
        final studentClass = data['class']?.toString().trim() ?? '';
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final notExcluded = status != 'struck off' && status != 'graduate';
        return studentClass == widget.classModel.name && notExcluded;
      }).toList();

      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Students'];
      sheet.appendRow([
        excel_lib.TextCellValue('ID'),
        excel_lib.TextCellValue('Name'),
        excel_lib.TextCellValue('Father'),
        excel_lib.TextCellValue('Mobile'),
        excel_lib.TextCellValue('Fee'),
      ]);
      for (final s in students) {
        sheet.appendRow([
          excel_lib.TextCellValue(s['id']?.toString() ?? ''),
          excel_lib.TextCellValue(s['name'] ?? ''),
          excel_lib.TextCellValue(s['father_name'] ?? ''),
          excel_lib.TextCellValue(s['mobile'] ?? ''),
          excel_lib.TextCellValue(s['fee']?.toString() ?? ''),
        ]);
      }
      final bytes = excel.encode()!;
      await FileUtils.downloadExcel(bytes, '${widget.classModel.name}_students.xlsx');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting Excel: $e')));
    }
  }
} 