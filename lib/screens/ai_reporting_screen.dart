import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../services/ai_reporting_service.dart';
import '../services/export_service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../widgets/voice_input_button.dart';
import '../screens/home_screen.dart';
import '../screens/students_screen.dart';
import '../screens/teachers_screen.dart';
import '../screens/budget_management_screen.dart';
import '../models/ai_query_result.dart';
import 'dart:ui' as dart_ui;

class AIReportingScreen extends StatefulWidget {
  const AIReportingScreen({Key? key}) : super(key: key);

  @override
  _AIReportingScreenState createState() => _AIReportingScreenState();
}

class _AIReportingScreenState extends State<AIReportingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AIReportingService _aiService = AIReportingService();
  final ExportService _exportService = ExportService();
  
  bool _isLoading = false;
  AIQueryResult? _queryResult;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSuggestions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Updates search suggestions based on current input
  void _updateSuggestions() {
    final input = _searchController.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() { _showSuggestions = false; });
      return;
    }
    
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final year = now.year;
    
    final baseSuggestions = [
      // Student queries
      'Show all active students',
      'Show students admitted in ${months[now.month-1]} $year',
      'Show students admitted in $year',
      'Show students with status stuckup',
      'Show students with status graduated',
      'Show students in class A',
      'Show students in class B',
      'Show students with fee more than 100',
      'Show students by name John',
      'Show total number of students',
      'Show active students count',
      
      // Teacher queries
      'Show all active teachers',
      'Show teachers with status left',
      'Show teachers joined in $year',
      'Show teachers with salary more than 5000',
      'Show total number of teachers',
      'Show active teachers count',
      
      // Budget queries
      'Show budget records in $year',
      'Show income in ${months[now.month-1]} $year',
      'Show expenditure in $year',
      'Show total income',
      'Show total expenditure',
      'Show income more than 1000',
      'Show expenditure less than 500',
      
      // Complex queries
      'Show students and teachers',
      'Show all data',
      'Show complete information',
    ];
    
    _suggestions = baseSuggestions.where((s) => s.toLowerCase().contains(input)).toList();
    setState(() { _showSuggestions = _suggestions.isNotEmpty; });
  }

  /// Handles suggestion selection
  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    setState(() { _showSuggestions = false; });
    _processUserQuery(suggestion);
  }

  /// Enhanced query processing function that uses the AI service
  Future<void> _processUserQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _queryResult = null;
    });

    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isUrdu = languageProvider.isUrdu;

      // Use the AI service to process the query
      final result = await _aiService.processQuery(query, isUrdu: isUrdu);

      // Add actions based on the result
      final actions = _buildActions(result, isUrdu);

      setState(() {
        _isLoading = false;
        _queryResult = AIQueryResult(
          module: result.module,
          data: result.data,
          summary: result.summary,
          actions: actions,
          filters: result.filters,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('I apologize, but I encountered an error. Please try rephrasing your question.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build actions based on query result
  List<AIAction> _buildActions(AIQueryResult result, bool isUrdu) {
    List<AIAction> actions = [];

    switch (result.module) {
      case 'students':
        actions.add(AIAction(
        title: isUrdu ? 'تمام طلباء دیکھیں' : 'View All Students',
        description: isUrdu ? 'تمام طلباء کی فہرست دیکھیں' : 'View complete student list',
        icon: Icons.people,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsScreen())),
        ));
        if (result.data.isNotEmpty) {
          actions.add(AIAction(
          title: isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ' : 'Download PDF',
          description: isUrdu ? 'نتائج کو پی ڈی ایف میں ڈاؤن لوڈ کریں' : 'Download results as PDF',
            icon: Icons.picture_as_pdf,
            onTap: () => _downloadResults(result.data, 'students', 'pdf', isUrdu),
          ));
          actions.add(AIAction(
            title: isUrdu ? 'ایکسل ڈاؤن لوڈ' : 'Download Excel',
            description: isUrdu ? 'نتائج کو ایکسل میں ڈاؤن لوڈ کریں' : 'Download results as Excel',
            icon: Icons.table_chart,
            onTap: () => _downloadResults(result.data, 'students', 'excel', isUrdu),
          ));
        }
        break;

      case 'teachers':
        actions.add(AIAction(
        title: isUrdu ? 'تمام اساتذہ دیکھیں' : 'View All Teachers',
        description: isUrdu ? 'تمام اساتذہ کی فہرست دیکھیں' : 'View complete teacher list',
        icon: Icons.school,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeachersScreen())),
        ));
        if (result.data.isNotEmpty) {
          actions.add(AIAction(
            title: isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ' : 'Download PDF',
            description: isUrdu ? 'نتائج کو پی ڈی ایف میں ڈاؤن لوڈ کریں' : 'Download results as PDF',
            icon: Icons.picture_as_pdf,
            onTap: () => _downloadResults(result.data, 'teachers', 'pdf', isUrdu),
          ));
          actions.add(AIAction(
            title: isUrdu ? 'ایکسل ڈاؤن لوڈ' : 'Download Excel',
            description: isUrdu ? 'نتائج کو ایکسل میں ڈاؤن لوڈ کریں' : 'Download results as Excel',
            icon: Icons.table_chart,
            onTap: () => _downloadResults(result.data, 'teachers', 'excel', isUrdu),
          ));
        }
        break;

      case 'budget':
        actions.add(AIAction(
        title: isUrdu ? 'بجٹ مینجمنٹ' : 'Budget Management',
        description: isUrdu ? 'بجٹ مینجمنٹ اسکرین کھولیں' : 'Open budget management screen',
        icon: Icons.account_balance_wallet,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BudgetManagementScreen())),
        ));
        if (result.data.isNotEmpty) {
          actions.add(AIAction(
            title: isUrdu ? 'پی ڈی ایف ڈاؤن لوڈ' : 'Download PDF',
            description: isUrdu ? 'نتائج کو پی ڈی ایف میں ڈاؤن لوڈ کریں' : 'Download results as PDF',
            icon: Icons.picture_as_pdf,
            onTap: () => _downloadResults(result.data, 'budget', 'pdf', isUrdu),
          ));
          actions.add(AIAction(
            title: isUrdu ? 'ایکسل ڈاؤن لوڈ' : 'Download Excel',
            description: isUrdu ? 'نتائج کو ایکسل میں ڈاؤن لوڈ کریں' : 'Download results as Excel',
            icon: Icons.table_chart,
            onTap: () => _downloadResults(result.data, 'budget', 'excel', isUrdu),
          ));
        }
        break;

      case 'mixed':
        actions.add(AIAction(
        title: isUrdu ? 'ہوم اسکرین' : 'Home Screen',
        description: isUrdu ? 'ہوم اسکرین پر جائیں' : 'Go to home screen',
        icon: Icons.home,
        onTap: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        ),
        ));
        break;
    }

    return actions;
  }

  /// Download results using the export service
  Future<void> _downloadResults(List<dynamic> data, String module, String format, bool isUrdu) async {
    try {
      // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text(isUrdu ? 'فائل تیار ہو رہی ہے...' : 'Preparing file...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Export the data
      final file = await _exportService.exportAIResults(
        data: data,
        module: module,
        isUrdu: isUrdu,
        format: format,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu 
              ? 'فائل کامیابی سے ڈاؤن لوڈ ہو گئی: ${file.path}'
              : 'File downloaded successfully: ${file.path}',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: isUrdu ? 'کھولیں' : 'Open',
            textColor: Colors.white,
            onPressed: () {
              // Open file logic here
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu 
              ? 'فائل ڈاؤن لوڈ کرنے میں خرابی: $e'
              : 'Failed to download file: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(languageProvider.getText('ai_reporting')),
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
            colors: [
              Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: languageProvider.getText('ask_anything_about_your_data'),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF1976D2)),
                            suffixIcon: VoiceInputButton(
                              isUrdu: isUrdu,
                              onResult: (text) {
                                _searchController.text = text;
                                _processUserQuery(text);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: _processUserQuery,
                        ),
                      ),
                      if (_showSuggestions)
                        Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_suggestions[index]),
                                onTap: () => _onSuggestionTap(_suggestions[index]),
                                leading: Icon(Icons.lightbulb_outline, color: Colors.orange),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Results Section
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1976D2)),
                          SizedBox(height: 16),
                          Text(
                            languageProvider.getText('analyzing_your_data'),
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_queryResult != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Header
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _queryResult!.summary,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Actions Section
                        if (_queryResult!.actions.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          Text(
                            isUrdu ? 'اقدامات' : 'Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                                SizedBox(height: 12),
                                ...(_queryResult!.actions.map((action) => Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: action.onTap,
                                        borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(action.icon, color: Color(0xFF1976D2)),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  action.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  action.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                )).toList()),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Data Table
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _buildDataTable(),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 80,
                            color: Color(0xFF1976D2).withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            languageProvider.getText('ask_anything_about_your_data'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            languageProvider.getText('ai_will_analyze_and_answer'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  /// Build data table based on module type
  Widget _buildDataTable() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    if (_queryResult == null) return Container();

    switch (_queryResult!.module) {
      case 'students':
      return _buildStudentTable(_queryResult!.data.cast<Student>(), isUrdu);
      case 'teachers':
      return _buildTeacherTable(_queryResult!.data.cast<Teacher>(), isUrdu);
      case 'budget':
      return _buildBudgetTable(_queryResult!.data, isUrdu);
      case 'mixed':
      return _buildMixedTable(_queryResult!.data, isUrdu);
      default:
        return Container();
    }
  }

  /// Build student data table
  Widget _buildStudentTable(List<Student> students, bool isUrdu) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 2.5,
        child: Directionality(
          textDirection: isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
      child: DataTable(
            columns: (isUrdu
              ? [
                  DataColumn(label: Text('فیس')),
                  DataColumn(label: Text('حیثیت')),
                  DataColumn(label: Text('کلاس')),
                  DataColumn(label: Text('داخلے کی تاریخ')),
                  DataColumn(label: Text('نام')),
                ]
              : [
                  DataColumn(label: Text('Fee')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Admission Date')),
                  DataColumn(label: Text('Name')),
                ]),
            rows: students.map((student) {
              final cells = [
            DataCell(Text(student.fee)),
            DataCell(Text(student.status)),
                DataCell(Text('Class ${String.fromCharCode(64 + (student.classId ?? 1))}')),
            DataCell(Text(DateFormat('yyyy-MM-dd').format(student.admissionDate))),
                DataCell(Text(student.name)),
              ];
              return DataRow(cells: isUrdu ? cells.reversed.toList() : cells);
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Build teacher data table
  Widget _buildTeacherTable(List<Teacher> teachers, bool isUrdu) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 2.5,
        child: Directionality(
          textDirection: isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
      child: DataTable(
            columns: (isUrdu
              ? [
                  DataColumn(label: Text('تنخواہ')),
                  DataColumn(label: Text('حیثیت')),
                  DataColumn(label: Text('موبائل')),
                  DataColumn(label: Text('شروع کی تاریخ')),
                  DataColumn(label: Text('نام')),
                ]
              : [
                  DataColumn(label: Text('Salary')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Starting Date')),
                  DataColumn(label: Text('Name')),
                ]),
            rows: teachers.map((teacher) {
              final cells = [
                DataCell(Text(teacher.salary.toString())),
            DataCell(Text(teacher.status)),
                DataCell(Text(teacher.mobile)),
                DataCell(Text(teacher.startingDate != null 
                  ? DateFormat('yyyy-MM-dd').format(teacher.startingDate!)
                  : '-')),
                DataCell(Text(teacher.name)),
              ];
              return DataRow(cells: isUrdu ? cells.reversed.toList() : cells);
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Build budget data table
  Widget _buildBudgetTable(List<dynamic> budgetData, bool isUrdu) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 2.5,
        child: Directionality(
          textDirection: isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
      child: DataTable(
            columns: (isUrdu
              ? [
                  DataColumn(label: Text('رقم')),
                  DataColumn(label: Text('تاریخ')),
                  DataColumn(label: Text('تفصیل')),
                  DataColumn(label: Text('نوع')),
                ]
              : [
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Type')),
                ]),
        rows: budgetData.map((item) {
              String type = '';
              String description = '';
              String amount = '';
              String date = '';

              if (item is Income) {
                type = isUrdu ? 'آمدنی' : 'Income';
                description = item.description;
                amount = item.amount.toString();
                date = item.date;
              } else if (item is Expenditure) {
                type = isUrdu ? 'خرچ' : 'Expenditure';
                description = item.description;
                amount = item.amount.toString();
                date = item.date;
              }

              final cells = [
              DataCell(Text(amount)),
                DataCell(Text(date)),
                DataCell(Text(description)),
                DataCell(Text(type)),
              ];
              return DataRow(cells: isUrdu ? cells.reversed.toList() : cells);
        }).toList(),
          ),
        ),
      ),
    );
  }

  /// Build mixed data table
  Widget _buildMixedTable(List<dynamic> mixedData, bool isUrdu) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 2.5,
        child: Directionality(
          textDirection: isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
      child: DataTable(
            columns: (isUrdu
              ? [
                  DataColumn(label: Text('تفصیلات')),
                  DataColumn(label: Text('نوع')),
                ]
              : [
                  DataColumn(label: Text('Details')),
                  DataColumn(label: Text('Type')),
                ]),
        rows: mixedData.map((item) {
              String type = '';
          String details = '';
          
              if (item['type'] == 'student') {
            final student = item['data'] as Student;
                type = isUrdu ? 'طالب علم' : 'Student';
                details = '${student.name} - ${student.status}';
              } else if (item['type'] == 'teacher') {
            final teacher = item['data'] as Teacher;
                type = isUrdu ? 'استاد' : 'Teacher';
                details = '${teacher.name} - ${teacher.status}';
              } else if (item['type'] == 'income') {
            final income = item['data'] as Income;
                type = isUrdu ? 'آمدنی' : 'Income';
                details = '${income.description} - ${income.amount}';
              } else if (item['type'] == 'expenditure') {
            final expenditure = item['data'] as Expenditure;
                type = isUrdu ? 'خرچ' : 'Expenditure';
                details = '${expenditure.description} - ${expenditure.amount}';
          }
          
              final cells = [
              DataCell(Text(details)),
                DataCell(Text(type)),
              ];
              return DataRow(cells: isUrdu ? cells.reversed.toList() : cells);
        }).toList(),
          ),
        ),
      ),
    );
  }
} 