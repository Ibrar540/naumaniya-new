import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/section.dart';
import '../providers/language_provider.dart';
import '../models/income.dart';
import '../models/expenditure.dart';
import '../models/loan.dart';
import '../widgets/voice_input_button.dart';
import 'home_screen.dart';
import '../providers/budget_provider.dart';

class BudgetEnterDataScreen extends StatefulWidget {
  final String type; // 'income' or 'expenditure'
  final Section section;
  final String institution;

  const BudgetEnterDataScreen({
    super.key,
    required this.type,
    required this.section,
    required this.institution,
  });

  @override
  _BudgetEnterDataScreenState createState() => _BudgetEnterDataScreenState();
}

class _BudgetEnterDataScreenState extends State<BudgetEnterDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  late String _selectedType;
  String _loanTxnType = 'loan'; // for loan entries: 'loan' or 'payment'
  bool _isLoading = false;
  final BudgetProvider _budgetProvider = BudgetProvider();
  final AuthService _auth = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type;
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _auth.initialize();
    setState(() {
      _isAdmin = _auth.isAdmin;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final desc = _descriptionController.text.trim();
        final amountText = _amountController.text.trim();
        // Use current date if not selected
        final date = _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (desc.isEmpty || amountText.isEmpty) return;
        final amount = double.tryParse(amountText) ?? 0.0;
        if (_selectedType == 'income') {
          await _budgetProvider.addIncome(Income(
            description: desc,
            amount: amount,
            date: date,
            sectionId: widget.section.id,
            sectionDocId: widget.section.docId,
            institution: widget.institution,
          ));
        } else if (_selectedType == 'expenditure') {
          await _budgetProvider.addExpenditure(Expenditure(
            description: desc,
            amount: amount,
            date: date,
            sectionId: widget.section.id,
            sectionDocId: widget.section.docId,
            institution: widget.institution,
          ));
        } else if (_selectedType == 'loan') {
          // Add loan/payment record
          final loan = Loan(
            description: desc,
            transactionType: _loanTxnType,
            amount: amount,
            date: date,
            sectionId: widget.section.id,
            sectionDocId: widget.section.docId,
            institution: widget.institution,
          );
          await _budgetProvider.addLoan(loan);
        } else {
          // fallback
        }
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Record added successfully'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error adding record: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _selectedType == 'income'
              ? languageProvider.getText('add_income')
              : languageProvider.getText('add_expenditure'),
        ),
        backgroundColor: Colors.transparent,
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
      ),
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5), Colors.white],
              ),
            ),
          ),
          SafeArea(
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
                              _selectedType == 'income'
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 60,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _selectedType == 'income'
                                  ? (isUrdu ? 'نئی آمدنی شامل کریں' : 'Add New Income')
                                  : (_selectedType == 'expenditure'
                                      ? (isUrdu ? 'نیا خرچ شامل کریں' : 'Add New Expenditure')
                                      : (isUrdu ? 'نیا قرض/ادائیگی شامل کریں' : 'Add New Loan/Payment')),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              _selectedType == 'income'
                                  ? (isUrdu
                                      ? 'آمدنی کی معلومات درج کریں'
                                      : 'Enter income information')
                                  : (isUrdu
                                      ? 'خرچ کی معلومات درج کریں'
                                      : 'Enter expenditure information'),
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
                            _buildTextField(
                              controller: _descriptionController,
                              label: languageProvider.getText('description'),
                              hint:
                                  languageProvider.getText('enter_description'),
                              icon: Icons.description,
                              isMultiline: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider
                                      .getText('please_enter_description');
                                }
                                return null;
                              },
                              isUrdu: isUrdu,
                            ),
                            SizedBox(height: 16),
                            if (_selectedType == 'loan') ...[
                              DropdownButtonFormField<String>(
                                value: _loanTxnType,
                                items: [
                                  DropdownMenuItem(value: 'loan', child: Text(isUrdu ? 'قرض' : 'Loan')),
                                  DropdownMenuItem(value: 'payment', child: Text(isUrdu ? 'ادائیگی' : 'Payment')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _loanTxnType = v);
                                },
                                decoration: InputDecoration(labelText: isUrdu ? 'اقسام' : 'Type', border: OutlineInputBorder()),
                              ),
                              SizedBox(height: 16),
                            ],
                            _buildTextField(
                              controller: _amountController,
                              label: languageProvider.getText('amount'),
                              hint: languageProvider.getText('enter_amount'),
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Amount is required';
                                if (double.tryParse(value) == null)
                                  return 'Amount must be a number';
                                return null;
                              },
                              isUrdu: isUrdu,
                            ),
                            SizedBox(height: 16),
                            _buildDateField(context, languageProvider),
                            SizedBox(height: 24),
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: !_isAdmin ? null : _submitData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 8,
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, size: 24),
                                          SizedBox(width: 8),
                                          Text(languageProvider.getText('submit')),
                                        ],
                                      ),
                                    ),
                                  ),
                            if (!_isAdmin) ...[
                              SizedBox(height: 12),
                              Text(
                                'You have read-only access. Request admin to add records.',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final reason = await showDialog<String?>(
                                      context: context,
                                      builder: (ctx) {
                                        final controller = TextEditingController();
                                        return AlertDialog(
                                          title: Text('Request Admin Access'),
                                          content: TextField(
                                            controller: controller,
                                            decoration: InputDecoration(hintText: 'Reason'),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('Send')),
                                          ],
                                        );
                                      },
                                    );
                                    if (reason != null && reason.isNotEmpty) {
                                      final ok = await _auth.requestAdminAccess(reason);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Request submitted' : 'Request failed')));
                                    }
                                  },
                                  child: Text('Request Admin Access'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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
    bool isMultiline = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
      maxLines: isMultiline ? null : 1,
      validator: validator,
      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: VoiceInputButton(
          isUrdu: isUrdu,
          onResult: (text) {
            controller.text = text;
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDateField(
      BuildContext context, LanguageProvider languageProvider) {
    final isUrdu = languageProvider.isUrdu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.getText('date'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          onTap: () => _pickDate(context),
          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            hintText: _selectedDate == null
                ? languageProvider.getText('select_date')
                : DateFormat('yyyy-MM-dd').format(_selectedDate!),
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (_selectedDate == null) {
              return languageProvider.getText('please_select_date');
            }
            return null;
          },
        ),
      ],
    );
  }
}
