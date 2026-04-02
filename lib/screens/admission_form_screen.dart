import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as dart_ui;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../services/database_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/language_provider.dart';
import '../widgets/voice_input_button.dart';
import '../utils/access_control.dart';
import '../screens/home_screen.dart';

class AdmissionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? admission;
  final bool isEdit;

  const AdmissionFormScreen({super.key, this.admission, this.isEdit = false});

  @override
  AdmissionFormScreenState createState() => AdmissionFormScreenState();
}

class AdmissionFormScreenState extends State<AdmissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  String? _imageUrl;

  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  String? _selectedClass;
  List<Map<String, dynamic>> _classList = [];
  String? _selectedStatus;
  final List<String> _statusOptions = ['Active', 'Struck Off', 'Graduate'];
  String? _selectedResidencyStatus;
  DateTime? _admissionDate;
  DateTime? _struckOffDate;
  DateTime? _graduationDate;
  bool _isLoading = false;

  // DatabaseService is static, no instance needed
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _loadClasses();
    if (widget.isEdit && widget.admission != null) {
      final adm = widget.admission!;
      _studentNameController.text = adm['student_name'] ?? '';
      _fatherNameController.text = adm['father_name'] ?? '';
      _fatherMobileController.text = adm['father_mobile'] ?? '';
      _addressController.text = adm['address'] ?? '';
      _feeController.text = adm['fee']?.toString() ?? '';
      _selectedClass = adm['class'] ?? '';
      _selectedStatus = adm['status'];
      _selectedResidencyStatus = adm['residency_status'] ?? 'Resident';
      _imageUrl = adm['image'];

      if (adm['admission_date'] != null && adm['admission_date'] != 'none') {
        _admissionDate = DateTime.tryParse(adm['admission_date']);
      }
      if (adm['struck_off_date'] != null && adm['struck_off_date'] != 'none') {
        _struckOffDate = DateTime.tryParse(adm['struck_off_date']);
      }
      if (adm['graduation_date'] != null && adm['graduation_date'] != 'none') {
        _graduationDate = DateTime.tryParse(adm['graduation_date']);
      }
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await DatabaseService.getAllClasses();
      if (kDebugMode) {
        print('Loaded ${classes.length} classes');
      }
      if (mounted) {
        setState(() {
          _classList = classes.map((c) => {'id': c.id, 'name': c.name}).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading classes: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerMenu() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Directionality(
          textDirection:
              isUrdu ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(isUrdu ? 'تصویر لیں' : 'Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                    isUrdu ? 'گیلری سے اپ لوڈ کریں' : 'Upload from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(Function(DateTime) onPicked,
      {DateTime? initialDate}) async {
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showClassSelectionDialog(BuildContext context, bool isUrdu) async {
    if (_classList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'پہلے کلاسیں بنائیں' : 'Create classes first'),
        ),
      );
      return;
    }

    String? tempSelectedClass = _selectedClass;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isUrdu ? 'کلاس منتخب کریں' : 'Select Class'),
              content: DropdownButtonFormField<String>(
                value: tempSelectedClass,
                items: _classList.map((classItem) {
                  return DropdownMenuItem<String>(
                    value: classItem['name'],
                    child: Text(classItem['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    tempSelectedClass = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: isUrdu ? 'کلاس' : 'Class',
                  border: OutlineInputBorder(),
                ),
                hint: Text(isUrdu ? 'کلاس منتخب کریں' : 'Select a class'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedClass = tempSelectedClass;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(isUrdu ? 'منتخب کریں' : 'Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAdmission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final className = _selectedClass ?? '';

    // --- Start of Diagnostic Logging ---
    if (kDebugMode) {
      print('--- Saving Admission Data ---');
      print('Class Name: $className');
    }
    // --- End of Diagnostic Logging ---

    try {
      // Note: Class management is handled in the database
      // For now, we'll just save the student with the class name

      if (kDebugMode) {
        print('Saving student with class: $className');
      }

      final studentName = _studentNameController.text.trim();
      final fatherName = _fatherNameController.text.trim();
      final mobile = _fatherMobileController.text.trim();

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
      } else {
        imageUrl = _imageUrl;
      }

      final studentData = {
        'student_name': studentName,
        'father_name': fatherName,
        'mobile': mobile,
        'class': className,
        'fee': _feeController.text.trim(),
        'status': _selectedStatus,
        'residency_status': _selectedResidencyStatus ?? 'Resident',
        'admission_date': _admissionDate?.toIso8601String().split('T')[0],
        'struck_off_date': _struckOffDate?.toIso8601String().split('T')[0],
        'graduation_date': _graduationDate?.toIso8601String().split('T')[0],
        'picture_url': imageUrl,
      };

      if (widget.admission != null) {
        // Update existing admission
        await DatabaseService.updateAdmission(
          widget.admission!['id'].toString(),
          studentData,
        );
      } else {
        // Add new admission
        await DatabaseService.addAdmission(studentData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admission saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving admission: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save admission: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isUrdu = languageProvider.isUrdu;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isEdit 
                ? (isUrdu ? 'داخلہ میں ترمیم' : 'Edit Admission')
                : (isUrdu ? 'نیا داخلہ' : 'New Admission')),
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (route) => false,
                    );
                  },
                  tooltip: isUrdu ? 'ہوم' : 'Home',
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: isUrdu ? 'واپس' : 'Back',
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            leadingWidth: 100,
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade100, Colors.green.shade200],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.person_add,
                                  size: 60, color: Color(0xFF1976D2)),
                              const SizedBox(height: 16),
                              Text(
                                widget.isEdit
                                    ? (isUrdu ? 'داخلہ ریکارڈ میں ترمیم' : 'Edit Admission Record')
                                    : (isUrdu ? 'نیا داخلہ ریکارڈ' : 'New Admission Record'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isUrdu 
                                    ? 'براہ کرم تمام ضروری فیلڈز پُر کریں'
                                    : 'Please fill in all required fields',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                _studentNameController,
                                isUrdu ? 'طالب علم کا نام' : 'Student Name',
                                isUrdu ? 'طالب علم کا نام درج کریں' : 'Enter student name',
                                Icons.person,
                                isUrdu: isUrdu,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? (isUrdu ? 'براہ کرم طالب علم کا نام درج کریں' : 'Please enter student name')
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                _fatherNameController,
                                isUrdu ? 'والد کا نام' : "Father's Name",
                                isUrdu ? 'والد کا نام درج کریں' : "Enter father's name",
                                Icons.person_outline,
                                isUrdu: isUrdu,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? (isUrdu ? 'براہ کرم والد کا نام درج کریں' : "Please enter father's name")
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                _fatherMobileController,
                                isUrdu ? 'والد کا موبائل' : "Father's Mobile",
                                isUrdu ? 'والد کا موبائل نمبر درج کریں' : "Enter father's mobile number",
                                Icons.phone,
                                isUrdu: isUrdu,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                _addressController,
                                isUrdu ? 'پتہ' : 'Address',
                                isUrdu ? 'پتہ درج کریں' : 'Enter address',
                                Icons.location_on,
                                isUrdu: isUrdu,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                _feeController,
                                isUrdu ? 'فیس' : 'Fee',
                                isUrdu ? 'فیس کی رقم درج کریں' : 'Enter fee amount',
                                Icons.attach_money,
                                isUrdu: isUrdu,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: () => _showClassSelectionDialog(context, isUrdu),
                                child: InputDecorator(
                                  decoration: _buildInputDecoration(
                                    isUrdu ? 'کلاس' : 'Class',
                                    Icons.school,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedClass ?? (isUrdu ? 'کلاس منتخب کریں' : 'Select a class'),
                                        style: TextStyle(
                                          color: _selectedClass == null ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                items: _statusOptions
                                    .map((status) => DropdownMenuItem<String>(
                                        value: status, 
                                        child: Text(isUrdu 
                                            ? (status == 'Active' ? 'فعال' : status == 'Struck Off' ? 'خارج شدہ' : 'فارغ التحصیل')
                                            : status)))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedStatus = value),
                                decoration:
                                    _buildInputDecoration(isUrdu ? 'حیثیت' : 'Status', Icons.info),
                              ),
                              const SizedBox(height: 20),
                              Consumer<LanguageProvider>(
                                builder: (context, languageProvider, child) {
                                  final isUrdu = languageProvider.isUrdu;
                                  final residencyOptions = isUrdu
                                      ? {'Resident': 'مقیم', 'Non_Resident': 'غیر مقیم'}
                                      : {'Resident': 'Resident', 'Non_Resident': 'Non Resident'};
                                  
                                  return DropdownButtonFormField<String>(
                                    initialValue: _selectedResidencyStatus ?? 'Resident',
                                    items: residencyOptions.entries
                                        .map((entry) => DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(entry.value)))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedResidencyStatus = value),
                                    decoration: _buildInputDecoration(
                                        isUrdu ? 'رہائشی حیثیت' : 'Residency Status',
                                        Icons.home_work),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildDateField(
                                  isUrdu ? 'داخلہ کی تاریخ' : 'Admission Date',
                                  _admissionDate,
                                  (picked) =>
                                      setState(() => _admissionDate = picked)),
                              const SizedBox(height: 20),
                              _buildDateField(
                                  isUrdu ? 'خارج ہونے کی تاریخ' : 'Struck Off Date',
                                  _struckOffDate,
                                  (picked) =>
                                      setState(() => _struckOffDate = picked)),
                              const SizedBox(height: 20),
                              _buildDateField(
                                  isUrdu ? 'فراغت کی تاریخ' : 'Graduation Date',
                                  _graduationDate,
                                  (picked) =>
                                      setState(() => _graduationDate = picked)),
                              const SizedBox(height: 20),
                              _buildImageField(isUrdu),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          runIfAdmin(context, () async {
                                            await _saveAdmission();
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 8,
                                  ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(widget.isEdit
                                                    ? Icons.save
                                                    : Icons.add),
                                                const SizedBox(width: 8),
                                                Text(
                                                  widget.isEdit
                                                      ? (isUrdu ? 'داخلہ اپ ڈیٹ کریں' : 'Update Admission')
                                                      : (isUrdu ? 'داخلہ محفوظ کریں' : 'Save Admission'),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold),
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
        ],
      ),
    );
          },
        );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    bool isUrdu = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: _buildInputDecoration(label, icon).copyWith(
        hintText: hint,
        suffixIcon: VoiceInputButton(
          isUrdu: isUrdu,
          onResult: (text) => controller.text = text,
        ),
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? value, Function(DateTime) onPicked) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;
    
    return InkWell(
      onTap: () => _pickDate(onPicked, initialDate: value),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _buildInputDecoration(label, Icons.calendar_today),
        child: Text(
          value != null
              ? DateFormat('yyyy-MM-dd').format(value)
              : (isUrdu ? 'تاریخ منتخب کریں' : 'Select Date'),
          style: TextStyle(
              fontSize: 16,
              color: value != null ? Colors.black : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildImageField(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isUrdu ? 'طالب علم کی تصویر' : 'Student Image',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (_imageUrl != null && _imageUrl!.isNotEmpty
                        ? Image.network(_imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[400]))
                        : Icon(Icons.person,
                            size: 40, color: Colors.grey[400])),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showImagePickerMenu,
              icon: const Icon(Icons.camera_alt),
              label: Text(_imageFile == null && _imageUrl == null
                  ? (isUrdu ? 'تصویر شامل کریں' : 'Add Image')
                  : (isUrdu ? 'تصویر تبدیل کریں' : 'Change Image')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
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
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

}
