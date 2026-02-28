import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auto_sync_provider.dart';
import '../models/teacher.dart';
import '../widgets/voice_input_button.dart';
import 'home_screen.dart';
import '../providers/teacher_provider.dart';

class TeacherEnterDataScreen extends StatefulWidget {
  final Teacher? teacher;
  const TeacherEnterDataScreen({super.key, this.teacher});

  @override
  _TeacherEnterDataScreenState createState() => _TeacherEnterDataScreenState();
}

class _TeacherEnterDataScreenState extends State<TeacherEnterDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _salaryController = TextEditingController();
  final _statusController = TextEditingController();
  DateTime? _startingDate;
  DateTime? _leavingDate;
  bool _isLoading = false;
  // Use the provided TeacherProvider from the widget tree
  final _statusOptions = ['Active', 'Left'];
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'Active'; // Default status
    // _startingDate = DateTime.now();
    // If editing an existing teacher, populate the form
    if (widget.teacher != null) {
      final t = widget.teacher!;
      _nameController.text = t.name;
      _mobileController.text = t.mobile;
      _salaryController.text = t.salary.toString();
      _selectedStatus = t.status.isNotEmpty ? t.status : 'Active';
      if (t.startingDate != null) _startingDate = t.startingDate;
      _leavingDate =
          t.leavingDate.isNotEmpty ? DateTime.tryParse(t.leavingDate) : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _salaryController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startingDate = picked;
      });
    }
  }

  void _pickLeavingDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leavingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _leavingDate = picked;
      });
    }
  }

  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    String status = (_selectedStatus == null || _selectedStatus!.isEmpty)
        ? 'Active'
        : _selectedStatus!;
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final salaryText = _salaryController.text.trim();
    int salary = int.tryParse(salaryText) ?? 0;
    DateTime? startingDate = _startingDate;

    final statusToSave = status;
    final startingDateToSave = startingDate ?? DateTime.now();

    setState(() {
      _isLoading = true;
    });

    try {
      final teacher = Teacher(
        id: widget.teacher?.id,
        name: name,
        mobile: mobile,
        startingDate: startingDateToSave,
        salary: salary,
        status: statusToSave,
        leavingDate: _leavingDate != null
            ? DateFormat('yyyy-MM-dd').format(_leavingDate!)
            : '',
      );

      final teacherProvider =
          Provider.of<TeacherProvider>(context, listen: false);
      if (widget.teacher != null) {
        await teacherProvider.updateTeacher(teacher);
      } else {
        await teacherProvider.addTeacher(teacher);
      }
      // Return a success result so the caller can refresh if needed
      if (mounted) Navigator.pop(context, true);

      // Add to auto-sync pending operations if offline (if AutoSyncProvider is available)
      try {
        final autoSyncProvider =
            Provider.of<AutoSyncProvider>(context, listen: false);
        if (!autoSyncProvider.isOnline) {
          await autoSyncProvider.addPendingOperation(
              'teacher', teacher.toMap());
        }
      } catch (e) {
        // AutoSyncProvider not available, skip sync
        if (kDebugMode) {
          print('AutoSyncProvider not available: $e');
        }
      }

      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(languageProvider.getText('teacher_added_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
      _clearForm();
    } catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${languageProvider.getText('error_adding_teacher')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _mobileController.clear();
    _salaryController.clear();
    _statusController.clear();
    setState(() {
      _startingDate = null;
      _leavingDate = null;
      _selectedStatus = 'Active'; // Reset to default
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isUrdu
            ? 'اساتذہ - ڈیٹا داخل کریں'
            : 'Teachers - Enter Data'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
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
        leadingWidth: 100,
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey[50]!],
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school,
                                size: 60,
                                color: Color(0xFF1976D2),
                              ),
                              SizedBox(height: 16),
                              Text(
                                languageProvider.isUrdu
                                    ? 'نیا استاد شامل کریں'
                                    : 'Add New Teacher',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                languageProvider.isUrdu
                                    ? 'استاد کی معلومات درج کریں'
                                    : 'Enter teacher information',
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
                      SizedBox(height: 30),
                      // Form Fields Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              // Name Field
                              _buildTextField(
                                controller: _nameController,
                                label: languageProvider.getText('teacher_name'),
                                hint: languageProvider
                                    .getText('enter_teacher_name'),
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return languageProvider
                                        .getText('please_enter_teacher_name');
                                  }
                                  return null;
                                },
                                isUrdu: languageProvider.isUrdu,
                              ),
                              SizedBox(height: 20),
                              // Mobile Field
                              _buildTextField(
                                controller: _mobileController,
                                label:
                                    languageProvider.getText('mobile_number'),
                                hint: languageProvider
                                    .getText('enter_mobile_number'),
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                isUrdu: languageProvider.isUrdu,
                              ),
                              SizedBox(height: 20),
                              // Salary Field
                              _buildTextField(
                                controller: _salaryController,
                                label: languageProvider.getText('salary'),
                                hint: languageProvider.getText('enter_salary'),
                                icon: Icons.money,
                                keyboardType: TextInputType.number,
                                isUrdu: languageProvider.isUrdu,
                              ),
                              SizedBox(height: 20),
                              // Status Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                items: _statusOptions
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                    if (_selectedStatus != 'Left') {
                                      _leavingDate = null;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: languageProvider.getText('status'),
                                  prefixIcon: Icon(Icons.info,
                                      color: Color(0xFF1976D2)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Color(0xFF1976D2), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                              if (_selectedStatus == 'Left')
                                Row(
                                  children: [
                                    Text(languageProvider
                                        .getText('leaving_date')),
                                    TextButton(
                                      onPressed: _pickLeavingDate,
                                      child: Text(_leavingDate != null
                                          ? DateFormat('yyyy-MM-dd')
                                              .format(_leavingDate!)
                                          : languageProvider
                                              .getText('select_date')),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 20),
                              // Starting Date Field
                              _buildDateField(
                                label: languageProvider.getText('joining_date'),
                                value: _startingDate,
                                onTap: _pickDate,
                              ),
                              SizedBox(height: 40),
                              // Add Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _addTeacher,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(
                                          color: Colors.white)
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add),
                                            SizedBox(width: 8),
                                            Text(
                                              languageProvider
                                                  .getText('add_teacher'),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isUrdu,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Color(0xFF1976D2)),
            suffixIcon: VoiceInputButton(
              isUrdu: isUrdu,
              onResult: (text) {
                controller.text = text;
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                SizedBox(width: 12),
                Text(
                  value != null
                      ? DateFormat('yyyy-MM-dd').format(value)
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    color: value != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
