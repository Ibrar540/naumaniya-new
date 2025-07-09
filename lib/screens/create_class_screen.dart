import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../db/database_helper.dart';
import '../models/class_model.dart';
import 'home_screen.dart';

class CreateClassScreen extends StatefulWidget {
  final ClassModel? classToEdit;
  
  const CreateClassScreen({Key? key, this.classToEdit}) : super(key: key);
  
  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classToEdit != null) {
      _classNameController.text = widget.classToEdit!.name;
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> classData = {
        'name': _classNameController.text.trim(),
        'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      };

      if (widget.classToEdit != null) {
        // Update existing class
        await _dbHelper.updateClass(classData, widget.classToEdit!.id!);
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getText('class_updated_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new class
        await _dbHelper.insertClass(classData);
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getText('class_created_successfully')),
            backgroundColor: Colors.green,
          ),
        );
        _classNameController.clear();
      }
      
      if (widget.classToEdit != null) {
        Navigator.pop(context, true); // Return true to indicate success on update
      }
    } catch (e) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.classToEdit != null 
            ? languageProvider.getText('error_updating_class')
            : languageProvider.getText('error_creating_class') + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEditing = widget.classToEdit != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing 
            ? (languageProvider.isUrdu ? 'کلاس اپڈیٹ کریں' : 'Edit Class')
            : (languageProvider.isUrdu ? 'نیا کلاس بنائیں' : 'Create Class'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1976D2),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school,
                        size: 50,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        isEditing 
                          ? (languageProvider.isUrdu ? 'کلاس اپڈیٹ کریں' : 'Update Class')
                          : (languageProvider.isUrdu ? 'نیا کلاس بنائیں' : 'Create New Class'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Fields
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Class Name Field
                          _buildTextField(
                            controller: _classNameController,
                            label: languageProvider.getText('class_name'),
                            hint: languageProvider.getText('enter_class_name'),
                            icon: Icons.school,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return languageProvider.getText('please_enter_class_name');
                              }
                              return null;
                            },
                            isUrdu: languageProvider.isUrdu,
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveClass,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditing ? Colors.orange : Colors.green,
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
                                      Icon(isEditing ? Icons.update : Icons.add),
                                      SizedBox(width: 8),
                                      Text(
                                        isEditing 
                                          ? languageProvider.getText('update')
                                          : languageProvider.getText('add'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
          validator: validator,
          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
        ),
      ],
    );
  }
} 