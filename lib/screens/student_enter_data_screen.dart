import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auto_sync_provider.dart';
import '../models/student.dart';
import '../db/database_helper.dart';
import '../widgets/voice_input_button.dart';
import '../screens/home_screen.dart';

class StudentEnterDataScreen extends StatefulWidget {
  final int? classId;
  final Student? studentToEdit;

  const StudentEnterDataScreen({super.key, this.classId, this.studentToEdit});

  @override
  _StudentEnterDataScreenState createState() => _StudentEnterDataScreenState();
}

class _StudentEnterDataScreenState extends State<StudentEnterDataScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _feeController = TextEditingController();
  final _statusController = TextEditingController();
  DateTime? _admissionDate;
  DateTime? _struckOffDate;
  DateTime? _graduationDate;
  DateTime? _leftDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentToEdit != null) {
      final student = widget.studentToEdit!;
      _nameController.text = student.name;
      _fatherNameController.text = student.fatherName;
      _mobileController.text = student.mobile;
      _feeController.text = student.fee;
      _statusController.text = student.status;
      _admissionDate = student.admissionDate;
      if (student.struckOffDate.isNotEmpty && student.struckOffDate != 'none') {
        _struckOffDate = DateFormat('yyyy-MM-dd').parse(student.struckOffDate);
      }
      if (student.graduationDate.isNotEmpty &&
          student.graduationDate != 'none') {
        _graduationDate =
            DateFormat('yyyy-MM-dd').parse(student.graduationDate);
      }
      if (student.leftDate.isNotEmpty && student.leftDate != 'none') {
        _leftDate = DateFormat('yyyy-MM-dd').parse(student.leftDate);
      }
    } else {
      _admissionDate = DateTime.now();
      _statusController.text = 'Active'; // Default status
    }
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _admissionDate = picked;
      });
    }
  }

  void _pickStruckOffDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _struckOffDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _struckOffDate = picked;
      });
    }
  }

  void _pickGraduationDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _graduationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _graduationDate = picked;
      });
    }
  }

  void _pickLeftDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leftDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _leftDate = picked;
      });
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _statusController.text = status;

      // Auto-set dates based on status
      switch (status) {
        case 'Struck Off':
          if (_struckOffDate == null) {
            _struckOffDate = DateTime.now();
          }
          break;
        case 'Graduate':
          if (_graduationDate == null) {
            _graduationDate = DateTime.now();
          }
          break;
        case 'Active':
          // Clear status dates when status changes to Active
          // but preserve manually set dates
          break;
      }
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure status is always set to 'Active' if empty or whitespace
      if (_statusController.text.trim().isEmpty) {
        _statusController.text = 'Active';
      }
      final status = _statusController.text.trim();

      final fatherName = _fatherNameController.text.trim().isEmpty
          ? 'none'
          : _fatherNameController.text.trim();

      final mobile = _mobileController.text.trim().isEmpty
          ? 'none'
          : _mobileController.text.trim();

      final fee = _feeController.text.trim().isEmpty
          ? 'none'
          : _feeController.text.trim();

      // Auto-set admission date if not selected
      final admissionDate = _admissionDate ?? DateTime.now();

      // Auto-set status-specific dates
      DateTime? struckOffDate = _struckOffDate;
      DateTime? graduationDate = _graduationDate;
      DateTime? leftDate = _leftDate;

      if (status == 'Struck Off' && struckOffDate == null) {
        struckOffDate = DateTime.now();
      }
      if (status == 'Graduate' && graduationDate == null) {
        graduationDate = DateTime.now();
      }

      final student = Student(
        id: widget.studentToEdit?.id,
        name: _nameController.text.trim(),
        fatherName: fatherName,
        mobile: mobile,
        admissionDate: admissionDate,
        fee: fee,
        status: status,
        struckOffDate: struckOffDate != null
            ? DateFormat('yyyy-MM-dd').format(struckOffDate)
            : 'none',
        graduationDate: graduationDate != null
            ? DateFormat('yyyy-MM-dd').format(graduationDate)
            : 'none',
        leftDate: leftDate != null
            ? DateFormat('yyyy-MM-dd').format(leftDate)
            : 'none',
        classId: widget.studentToEdit?.classId ?? widget.classId,
      );
      // Debug print
      debugPrint('Saving student: ${student.toMap()}');
      debugPrint('classId: ${student.classId}');
      debugPrint('Status value: $status');

      if (widget.studentToEdit != null) {
        // Update student record
        await _dbHelper.updateStudent(student.toMap(), student.id!);

        // Also update admission record if student_id exists
        final studentId = widget.studentToEdit!.studentId;
        if (studentId != null) {
          final admissionData = await _dbHelper.getAdmissions();
          Map<String, dynamic>? admission;
          try {
            admission = admissionData.cast<Map<String, dynamic>>().firstWhere(
                  (a) => a['student_id'] == studentId,
                );
          } catch (e) {
            admission = null;
          }
          if (admission != null) {
            admission['status'] = status;
            // Set graduation date if status is graduate
            if (status.toLowerCase() == 'graduate') {
              admission['graduation_date'] =
                  DateTime.now().toIso8601String().split('T')[0];
            }
            await _dbHelper.updateAdmission(admission, admission['id']);
          }
        }

        // Add to auto-sync pending operations if offline
        final autoSyncProvider =
            Provider.of<AutoSyncProvider>(context, listen: false);
        if (!autoSyncProvider.isOnline) {
          await autoSyncProvider.addPendingOperation(
              'student', student.toMap());
        }
      } else {
        await _dbHelper.insertStudent(student.toMap());

        // Add to auto-sync pending operations if offline
        final autoSyncProvider =
            Provider.of<AutoSyncProvider>(context, listen: false);
        if (!autoSyncProvider.isOnline) {
          await autoSyncProvider.addPendingOperation(
              'student', student.toMap());
        }
      }

      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'طالب علم کامیابی سے محفوظ کر دیا گیا'
              : 'Student saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.studentToEdit != null) {
        Navigator.pop(context, true);
      } else {
        _clearForm();
      }
    } catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'طالب علم شامل کرنے میں خرابی: $e'
              : 'Error adding student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _fatherNameController.clear();
    _mobileController.clear();
    _feeController.clear();
    _statusController.clear();
    setState(() {
      _admissionDate = DateTime.now();
      _struckOffDate = null;
      _graduationDate = null;
      _leftDate = null;
      _statusController.text = 'Active'; // Reset to default
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isUrdu
            ? 'طلباء - ڈیٹا داخل کریں'
            : 'Students - Enter Data'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Colors.white,
            ],
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
                                ? 'نیا طالب علم شامل کریں'
                                : 'Add New Student',
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
                                ? 'طالب علم کی معلومات درج کریں'
                                : 'Enter student information',
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

                  // Student Image Card
                  // Remove _studentImageUrl variable, assignments, and StudentImagePicker widget

                  SizedBox(height: 20),

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
                            label: languageProvider.isUrdu ? 'نام' : 'Name',
                            hint: languageProvider.isUrdu
                                ? 'طالب علم کا نام'
                                : 'Student Name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return languageProvider.isUrdu
                                    ? 'نام درج کریں'
                                    : 'Please enter name';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20),

                          // Father's Name Field
                          _buildTextField(
                            controller: _fatherNameController,
                            label: languageProvider.isUrdu
                                ? 'والد کا نام'
                                : "Father's Name",
                            hint: languageProvider.isUrdu
                                ? 'والد کا نام'
                                : "Father's Name",
                            icon: Icons.person_outline,
                          ),

                          SizedBox(height: 20),

                          // Mobile Field
                          _buildTextField(
                            controller: _mobileController,
                            label: languageProvider.isUrdu
                                ? 'موبائل نمبر'
                                : 'Mobile Number',
                            hint: languageProvider.isUrdu
                                ? 'موبائل نمبر'
                                : 'Mobile Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),

                          SizedBox(height: 20),

                          // Fee Field
                          _buildTextField(
                            controller: _feeController,
                            label: languageProvider.isUrdu ? 'فیس' : 'Fee',
                            hint: languageProvider.isUrdu
                                ? 'فیس کی رقم'
                                : 'Fee Amount',
                            icon: Icons.money,
                            keyboardType: TextInputType.number,
                          ),

                          SizedBox(height: 20),

                          // Status Field with Dropdown
                          _buildStatusDropdown(),

                          SizedBox(height: 20),

                          // Admission Date Field
                          _buildDateField(
                            label: languageProvider.isUrdu
                                ? 'داخلہ کی تاریخ'
                                : 'Admission Date',
                            value: _admissionDate,
                            onTap: _pickDate,
                          ),

                          SizedBox(height: 20),

                          // Struck Off Date Field
                          _buildDateField(
                            label: languageProvider.isUrdu
                                ? 'خارج ہونے کی تاریخ'
                                : 'Struck Off Date',
                            value: _struckOffDate,
                            onTap: _pickStruckOffDate,
                          ),

                          SizedBox(height: 20),

                          // Graduation Date Field
                          _buildDateField(
                            label: languageProvider.isUrdu
                                ? 'گریجویشن کی تاریخ'
                                : 'Graduation Date',
                            value: _graduationDate,
                            onTap: _pickGraduationDate,
                          ),

                          SizedBox(height: 20),

                          // Left Date Field
                          _buildDateField(
                            label: languageProvider.isUrdu
                                ? 'چھوڑنے کی تاریخ'
                                : 'Left Date',
                            value: _leftDate,
                            onTap: _pickLeftDate,
                          ),

                          SizedBox(height: 40),

                          // Add Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveStudent,
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
                                        Icon(widget.studentToEdit != null
                                            ? Icons.save
                                            : Icons.add),
                                        SizedBox(width: 8),
                                        Text(
                                          widget.studentToEdit != null
                                              ? languageProvider.isUrdu
                                                  ? 'محفوظ کریں'
                                                  : 'Save'
                                              : languageProvider.isUrdu
                                                  ? 'شامل کریں'
                                                  : 'Add Student',
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
    );
  }

  Widget _buildStatusDropdown() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final statusOptions = [
      {'value': 'Active', 'label': languageProvider.isUrdu ? 'فعال' : 'Active'},
      {
        'value': 'Struck Off',
        'label': languageProvider.isUrdu ? 'خارج شدہ' : 'Struck Off'
      },
      {
        'value': 'Graduate',
        'label': languageProvider.isUrdu ? 'گریجویٹ' : 'Graduate'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.isUrdu ? 'وضعیت' : 'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _statusController.text.isEmpty
                ? 'Active'
                : _statusController.text,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.assignment, color: Color(0xFF1976D2)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: statusOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _onStatusChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
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
              isUrdu: languageProvider.isUrdu,
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

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _mobileController.dispose();
    _feeController.dispose();
    _statusController.dispose();
    super.dispose();
  }
}
