import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../models/section.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../services/database_service.dart';
import 'budget_enter_data_screen.dart';
import 'home_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf_lib;
import '../utils/file_utils.dart';
import 'package:excel/excel.dart' as excel_lib;

class SectionDataScreen extends StatefulWidget {
  final Section section;
  final String type;
  final String institution;

  const SectionDataScreen({
    super.key,
    required this.section,
    required this.type,
    required this.institution,
  });

  @override
  State<SectionDataScreen> createState() => _SectionDataScreenState();
}

class _SectionDataScreenState extends State<SectionDataScreen> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = _data;
      } else {
        _filteredData = _data.where((row) {
          final description = row['description']?.toString().toLowerCase() ?? '';
          final amount = row['amount']?.toString().toLowerCase() ?? '';
          final date = _formatDateOnly(row['date']).toLowerCase();
          final searchLower = query.toLowerCase();
          
          return description.contains(searchLower) ||
                 amount.contains(searchLower) ||
                 date.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<Map<String, dynamic>> data;
      if (widget.type == 'income') {
        data = await DatabaseService.getIncomeBySection(
          widget.section.id!,
          institution: widget.institution,
        );
      } else {
        data = await DatabaseService.getExpenditureBySection(
          widget.section.id!,
          institution: widget.institution,
        );
      }
      setState(() {
        _data = data;
        _filteredData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  String _formatDateOnly(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is DateTime) {
        return DateFormat('yyyy-MM-dd').format(date);
      } else if (date is String) {
        if (date.isEmpty || date == 'none') return '-';
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate != null) {
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        }
        return date;
      }
      return date.toString();
    } catch (e) {
      return '-';
    }
  }

  Future<void> _editRow(BuildContext context, Map<String, dynamic> row) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final descController = TextEditingController(text: row['description'] ?? '');
    final amountController = TextEditingController(text: row['amount']?.toString() ?? '');
    DateTime? selectedDate;
    
    try {
      if (row['date'] != null) {
        if (row['date'] is DateTime) {
          selectedDate = row['date'];
        } else if (row['date'] is String) {
          selectedDate = DateTime.tryParse(row['date']);
        }
      }
    } catch (e) {
      selectedDate = null;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(languageProvider.isUrdu ? 'ترمیم کریں' : 'Edit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: languageProvider.isUrdu ? 'تفصیل' : 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: languageProvider.isUrdu ? 'رقم' : 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text(
                    selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                        : (languageProvider.isUrdu ? 'تاریخ منتخب کریں' : 'Select Date'),
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageProvider.isUrdu ? 'منسوخ' : 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final updatedData = {
                    'description': descController.text,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'date': selectedDate?.toIso8601String(),
                  };

                  if (widget.type == 'income') {
                    final income = Income(
                      id: row['id'],
                      description: descController.text,
                      amount: double.tryParse(amountController.text) ?? 0,
                      date: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '',
                      sectionId: widget.section.id,
                      institution: widget.institution,
                    );
                    await DatabaseService.updateIncome(income);
                  } else {
                    final expenditure = Expenditure(
                      id: row['id'],
                      description: descController.text,
                      amount: double.tryParse(amountController.text) ?? 0,
                      date: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '',
                      sectionId: widget.section.id,
                      institution: widget.institution,
                    );
                    await DatabaseService.updateExpenditure(expenditure);
                  }

                  Navigator.pop(context);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(languageProvider.isUrdu
                          ? 'کامیابی سے اپ ڈیٹ ہو گیا'
                          : 'Updated successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(languageProvider.isUrdu ? 'محفوظ کریں' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRow(BuildContext context, Map<String, dynamic> row) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isUrdu ? 'تصدیق کریں' : 'Confirm'),
        content: Text(
          languageProvider.isUrdu
              ? 'کیا آپ واقعی اسے حذف کرنا چاہتے ہیں؟'
              : 'Are you sure you want to delete this?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              languageProvider.isUrdu ? 'حذف کریں' : 'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (widget.type == 'income') {
          await DatabaseService.deleteIncome(
            row['id'],
            institution: widget.institution,
          );
        } else {
          await DatabaseService.deleteExpenditure(
            row['id'],
            institution: widget.institution,
          );
        }
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isUrdu
                ? 'کامیابی سے حذف ہو گیا'
                : 'Deleted successfully'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.section.name} - ${isUrdu ? 'ڈیٹا دیکھیں' : 'View Data'}'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
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
            tooltip: isUrdu ? 'زبان تبدیل کریں' : 'Switch Language',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterData,
                    decoration: InputDecoration(
                      hintText: isUrdu ? 'تلاش کریں...' : 'Search...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                isUrdu ? 'کوئی ڈیٹا نہیں ملا' : 'No data found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 50,
                            ),
                            child: DataTable(
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                              columnSpacing: 20.0,
                              columns: isUrdu
                                  ? [
                                      DataColumn(
                                        label: Expanded(child: Text('اعمال')),
                                      ),
                                      DataColumn(
                                        label: Expanded(child: Text('تاریخ')),
                                      ),
                                      DataColumn(
                                        label: Expanded(child: Text('رقم')),
                                      ),
                                      DataColumn(
                                        label: Expanded(child: Text('تفصیل')),
                                      ),
                                    ]
                                  : [
                                      DataColumn(
                                        label: Expanded(child: Text('Description')),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Text('Amount'),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 120,
                                          child: Text('Date'),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 80,
                                          child: Text('Actions'),
                                        ),
                                      ),
                                    ],
                              rows: _filteredData.map((row) {
                                final cells = [
                                  DataCell(
                                    Container(
                                      width: 200,
                                      child: Text(
                                        row['description'] ?? '',
                                        softWrap: true,
                                        maxLines: null,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 100,
                                      child: Text(row['amount'].toString()),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 120,
                                      child: Text(_formatDateOnly(row['date'] ?? '')),
                                    ),
                                  ),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          _editRow(context, row);
                                        } else if (value == 'delete') {
                                          _deleteRow(context, row);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text(isUrdu ? 'ترمیم' : 'Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 18),
                                              SizedBox(width: 8),
                                              Text(isUrdu ? 'حذف' : 'Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ];

                                return DataRow(
                                  cells: isUrdu ? cells.reversed.toList() : cells,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetEnterDataScreen(
                type: widget.type,
                section: widget.section,
                institution: widget.institution,
              ),
            ),
          );
        },
        tooltip: isUrdu ? 'ڈیٹا شامل کریں' : 'Add Data',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${widget.section.name} - ${widget.type == 'income' ? (languageProvider.isUrdu ? 'آمدن' : 'Income') : (languageProvider.isUrdu ? 'اخراجات' : 'Expenditure')}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(languageProvider.isUrdu ? 'تفصیل' : 'Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(languageProvider.isUrdu ? 'رقم' : 'Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(languageProvider.isUrdu ? 'تاریخ' : 'Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ..._filteredData.map((row) => pw.TableRow(
                    children: [
                      pw.Text(row['description'] ?? ''),
                      pw.Text(row['amount']?.toString() ?? row['rs']?.toString() ?? ''),
                      pw.Text(_formatDateOnly(row['date'])),
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
    await FileUtils.downloadPdf(bytes, '${widget.section.name}_${widget.type}.pdf');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'پی ڈی ایف ڈاؤن لوڈ ہو گیا'
              : 'PDF downloaded successfully'),
        ),
      );
    }
  }

  Future<void> _downloadExcel() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Data'];
    
    // Header
    sheet.appendRow([
      excel_lib.TextCellValue(languageProvider.isUrdu ? 'تفصیل' : 'Description'),
      excel_lib.TextCellValue(languageProvider.isUrdu ? 'رقم' : 'Amount'),
      excel_lib.TextCellValue(languageProvider.isUrdu ? 'تاریخ' : 'Date'),
    ]);
    
    // Data
    for (final row in _filteredData) {
      sheet.appendRow([
        excel_lib.TextCellValue(row['description'] ?? ''),
        excel_lib.TextCellValue(row['amount']?.toString() ?? row['rs']?.toString() ?? ''),
        excel_lib.TextCellValue(_formatDateOnly(row['date'])),
      ]);
    }
    
    final bytes = excel.encode()!;
    await FileUtils.downloadExcel(bytes, '${widget.section.name}_${widget.type}.xlsx');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'ایکسل ڈاؤن لوڈ ہو گیا'
              : 'Excel downloaded successfully'),
        ),
      );
    }
  }
}
