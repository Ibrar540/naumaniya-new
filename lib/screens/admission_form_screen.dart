import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'package:flutter/foundation.dart';
import '../utils/file_utils.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/voice_input_button.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';

class AdmissionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? admission;
  final bool isEdit;
  const AdmissionFormScreen({Key? key, this.admission, this.isEdit = false}) : super(key: key);
  @override
  _AdmissionFormScreenState createState() => _AdmissionFormScreenState();
}

class _AdmissionFormScreenState extends State<AdmissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _studentImage;
  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  final _classController = TextEditingController();
  String? _selectedStatus;
  final List<String> _statusOptions = ['Active', 'StackUp', 'Graduated'];
  DateTime? _admissionDate;
  DateTime? _stackupDate;
  DateTime? _graduationDate;
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int? _editId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.admission != null) {
      final adm = widget.admission!;
      _editId = adm['id'];
      _studentNameController.text = adm['student_name'] ?? '';
      _fatherNameController.text = adm['father_name'] ?? '';
      _fatherMobileController.text = adm['father_mobile'] ?? '';
      _addressController.text = adm['address'] ?? '';
      _feeController.text = adm['fee']?.toString() ?? '';
      _classController.text = adm['class'] ?? '';
      _selectedStatus = adm['status'];
      if (adm['admission_date'] != null && adm['admission_date'] != 'none') _admissionDate = DateTime.tryParse(adm['admission_date']);
      if (adm['stackup_date'] != null && adm['stackup_date'] != 'none') _stackupDate = DateTime.tryParse(adm['stackup_date']);
      if (adm['graduation_date'] != null && adm['graduation_date'] != 'none') _graduationDate = DateTime.tryParse(adm['graduation_date']);
      if (adm['image'] != null) {
        try {
          _studentImage = Uint8List.fromList(List<int>.from(adm['image']));
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _fatherMobileController.dispose();
    _addressController.dispose();
    _feeController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) {
      // On web, camera access is limited - show message and offer gallery
      final useGallery = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Camera Not Available'),
          content: Text('Camera access is limited in web browsers. Would you like to select an image from your gallery instead?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Use Gallery'),
            ),
          ],
        ),
      );
      
      if (useGallery == true) {
        _pickImageFromGallery();
      }
    } else {
      // Use standard ImagePicker for mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _studentImage = bytes;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (kIsWeb) {
      var uploadInput = FileUtils.createFileUploadInput();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((event) {
        final file = uploadInput.files?.first;
        if (file != null) {
          final reader = FileUtils.createFileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((event) {
            setState(() {
              _studentImage = reader.result as Uint8List;
            });
          });
        }
      });
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _studentImage = bytes;
        });
      }
    }
  }

  Future<void> _pasteImage() async {
    // Web clipboard paste (if supported)
    if (kIsWeb) {
      // Not all browsers support clipboard image paste
      // This is a placeholder for future implementation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paste from clipboard is not supported in this browser.')),
      );
    }
  }

  void _showImagePickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!kIsWeb) ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            if (kIsWeb) ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo (Limited on Web)'),
              subtitle: Text('Will redirect to gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.paste),
              title: Text('Paste Image'),
              subtitle: Text(kIsWeb ? 'Not supported in this browser' : 'Paste from clipboard'),
              onTap: () {
                Navigator.pop(context);
                _pasteImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(Function(DateTime) onPicked, {DateTime? initialDate}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _saveAdmission() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields correctly.');
      return;
    }
    if (_classController.text.trim().isEmpty) {
      _showError('Class is required.');
      return;
    }
    // Check if class exists
    final className = _classController.text.trim();
    final classData = await _dbHelper.getClassByName(className);
    if (classData == null) {
      _showError('The class ($className) does not exist. Please create it first.');
      return;
    }
    final classId = classData['id'];
    // Generate or reuse student_id
    String studentId = widget.isEdit && widget.admission != null && widget.admission!['student_id'] != null
      ? widget.admission!['student_id']
      : DateTime.now().millisecondsSinceEpoch.toString();
    // Get next roll_no if new, else reuse
    int rollNo = widget.isEdit && widget.admission != null && widget.admission!['roll_no'] != null
      ? widget.admission!['roll_no']
      : await _dbHelper.getNextRollNo(classId);
    // Graduation date after admission date validation
    if (_graduationDate != null && _admissionDate != null && _graduationDate!.isBefore(_admissionDate!)) {
      _showError('Graduation date must be after admission date.');
      return;
    }
    setState(() { _isLoading = true; });
    final name = _studentNameController.text.trim();
    final fatherName = _fatherNameController.text.trim().isEmpty ? 'none' : _fatherNameController.text.trim();
    final fatherMobile = _fatherMobileController.text.trim().isEmpty ? 'none' : _fatherMobileController.text.trim();
    final address = _addressController.text.trim().isEmpty ? 'none' : _addressController.text.trim();
    final fee = _feeController.text.trim().isEmpty ? 0 : int.tryParse(_feeController.text.trim()) ?? 0;
    final status = (_selectedStatus == null || _selectedStatus!.isEmpty) ? 'Active' : _selectedStatus;
    final admissionDate = _admissionDate != null ? DateFormat('yyyy-MM-dd').format(_admissionDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stackupDate = _stackupDate != null ? DateFormat('yyyy-MM-dd').format(_stackupDate!) : 'none';
    final graduationDate = _graduationDate != null ? DateFormat('yyyy-MM-dd').format(_graduationDate!) : 'none';
    // Admission record
    final Map<String, dynamic> admission = {
      'student_id': studentId,
      'roll_no': rollNo,
      'image': _studentImage,
      'student_name': name,
      'father_name': fatherName,
      'father_mobile': fatherMobile,
      'address': address,
      'fee': fee,
      'class': className,
      'status': status,
      'admission_date': admissionDate,
      'stackup_date': stackupDate == 'none' ? null : stackupDate,
      'graduation_date': graduationDate == 'none' ? null : graduationDate,
    };
    // Student record
    final Map<String, dynamic> student = {
      'student_id': studentId,
      'roll_no': rollNo,
      'name': name,
      'fatherName': fatherName,
      'mobile': fatherMobile,
      'admissionDate': admissionDate,
      'fee': fee,
      'status': status,
      'stuckupDate': stackupDate == 'none' ? null : stackupDate,
      'classId': classId,
    };
    try {
      if (widget.isEdit && widget.admission != null) {
        // Update both tables
        if (kIsWeb) {
          // Admission
          final admissions = await _dbHelper.getFromPrefs('admission_table');
          final idx = admissions.indexWhere((a) => a['student_id'] == studentId);
          if (idx != -1) {
            admission['id'] = admissions[idx]['id'];
            admissions[idx] = admission;
            await _dbHelper.saveToPrefs('admission_table', admissions);
          }
          // Student (update for both Active and Graduated status)
          if (status.toString().toLowerCase() == 'active' || status.toString().toLowerCase() == 'graduated') {
            final students = await _dbHelper.getFromPrefs('students');
            final sidx = students.indexWhere((s) => s['student_id'] == studentId);
            if (sidx != -1) {
              student['id'] = students[sidx]['id'];
              students[sidx] = student;
              await _dbHelper.saveToPrefs('students', students);
            }
          }
        } else {
          final dbClient = await _dbHelper.db;
          await dbClient.update('admission_table', admission, where: 'student_id = ?', whereArgs: [studentId]);
          // Student (update for both Active and Graduated status)
          if (status.toString().toLowerCase() == 'active' || status.toString().toLowerCase() == 'graduated') {
            await dbClient.update('students', student, where: 'student_id = ?', whereArgs: [studentId]);
          }
        }
        _showSuccess('Admission and student record updated!');
      } else {
        // Insert admission always
        await _dbHelper.insertAdmission(admission);
        // Insert student only if status is Active
        if (status.toString().toLowerCase() == 'active') {
          if (kIsWeb) {
            final students = await _dbHelper.getFromPrefs('students');
            student['id'] = await _dbHelper.getNextId('students');
            students.add(student);
            await _dbHelper.saveToPrefs('students', students);
          } else {
            final dbClient = await _dbHelper.db;
            await dbClient.insert('students', student);
          }
        }
        _showSuccess('Admission record saved!');
      }
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Error saving admission/student: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Admission' : 'New Admission'),
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
            colors: [Colors.green.shade100, Colors.green.shade200],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person_add, size: 60, color: Color(0xFF1976D2)),
                          SizedBox(height: 16),
                          Text(
                            widget.isEdit ? 'Edit Admission Record' : 'New Admission Record',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please fill in all required fields',
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
                  SizedBox(height: 24),
                  // Form Fields Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          // 1. Student Name
                          _buildTextField(
                            _studentNameController,
                            'Student Name',
                            'Enter student name',
                            Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter student name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // 2. Father's Name
                          _buildTextField(
                            _fatherNameController,
                            "Father's Name",
                            "Enter father's name",
                            Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter father\'s name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // 3. Father's Mobile
                          _buildTextField(
                            _fatherMobileController,
                            "Father's Mobile",
                            "Enter father's mobile number",
                            Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 20),
                          // 4. Address
                          _buildTextField(
                            _addressController,
                            'Address',
                            'Enter address',
                            Icons.location_on,
                          ),
                          SizedBox(height: 20),
                          // 5. Fee
                          _buildTextField(
                            _feeController,
                            'Fee',
                            'Enter fee amount',
                            Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 20),
                          // 6. Class
                          _buildTextField(
                            _classController,
                            'Class',
                            'Enter class name',
                            Icons.school,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter class name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // 7. Status
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() { _selectedStatus = value; });
                            },
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.info, color: Color(0xFF1976D2)),
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
                            // Optional, default to Actio if not selected
                          ),
                          SizedBox(height: 20),
                          // 8. Admission Date
                          _buildDateField('Admission Date', _admissionDate, (picked) => setState(() => _admissionDate = picked)),
                          SizedBox(height: 20),
                          // 9. Stackup Date
                          _buildDateField('Stackup Date', _stackupDate, (picked) => setState(() => _stackupDate = picked)),
                          SizedBox(height: 20),
                          // 10. Graduation Date
                          _buildDateField('Graduation Date', _graduationDate, (picked) => setState(() => _graduationDate = picked)),
                          SizedBox(height: 20),
                          // 11. Student Image
                          _buildImageField(),
                          SizedBox(height: 32),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveAdmission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 8,
                              ),
                              child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(widget.isEdit ? Icons.save : Icons.add),
                                      SizedBox(width: 8),
                                      Text(
                                        widget.isEdit ? 'Update Admission' : 'Save Admission',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
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
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF1976D2)),
        suffixIcon: VoiceInputButton(
          isUrdu: Provider.of<LanguageProvider>(context, listen: false).isUrdu,
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
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () => _pickDate(onPicked, initialDate: value),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
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
        child: Text(
          value != null ? DateFormat('yyyy-MM-dd').format(value) : 'Select Date',
          style: TextStyle(fontSize: 16, color: value != null ? Colors.black : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Student Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        Row(
          children: [
            _studentImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _studentImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Icon(Icons.person, size: 40, color: Colors.grey[400]),
                  ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showImagePickerMenu,
              icon: Icon(Icons.camera_alt),
              label: Text(_studentImage == null ? 'Add Image' : 'Change Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 