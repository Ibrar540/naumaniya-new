import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/section.dart';
import '../services/database_service.dart';
import 'section_data_screen.dart';
import 'budget_enter_data_screen.dart';
import 'section_options_detail_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class SectionActionScreen extends StatefulWidget {
  final String type; // 'income' or 'expenditure'
  final String institution; // 'masjid' or 'madrasa'

  const SectionActionScreen({
    super.key,
    required this.type,
    required this.institution,
  });

  @override
  State<SectionActionScreen> createState() => _SectionActionScreenState();
}

class _SectionActionScreenState extends State<SectionActionScreen> {
  String? _selectedAction; // 'create' or 'view'
  Section? _selectedSection;
  List<Section> _sections = [];
  List<Section> _filteredSections = [];
  bool _loadingSections = false;
  final _sectionNameController = TextEditingController();
  final _searchController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isAdmin = false;

  @override
  void dispose() {
    _sectionNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _auth.initialize();
    if (mounted) setState(() => _isAdmin = _auth.isAdmin);
  }

  void _filterSections(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSections = _sections;
      } else {
        _filteredSections = _sections.where((section) {
          return section.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _loadSections() async {
    setState(() {
      _loadingSections = true;
    });
    try {
      final sections = await DatabaseService.getSectionsByType(
        widget.institution,
        widget.type,
      );
      setState(() {
        _sections = sections;
        _filteredSections = sections;
        _loadingSections = false;
      });
    } catch (e) {
      setState(() {
        _loadingSections = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sections: $e')),
        );
      }
    }
  }

  Future<void> _createSection() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (_sectionNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'براہ کرم سیکشن کا نام درج کریں'
              : 'Please enter section name'),
        ),
      );
      return;
    }

    try {
      final section = Section(
        name: _sectionNameController.text.trim(),
        type: widget.type,
        institution: widget.institution,
      );
      await DatabaseService.addSection(section);
      _sectionNameController.clear();
      setState(() {
        _selectedAction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.isUrdu
              ? 'سیکشن بن گیا'
              : 'Section created successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'income'
              ? (isUrdu ? 'آمدنی' : 'Income')
              : (isUrdu ? 'اخراجات' : 'Expenditure'),
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
              onPressed: () {
                // Navigate back to the budget screen (masjid or madrasa)
                Navigator.of(context).pop();
              },
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
          child: _selectedAction == null
              ? _buildActionSelection(isUrdu)
              : _selectedAction == 'create'
                  ? _buildCreateSection(isUrdu)
                  : _buildViewSections(isUrdu),
        ),
      ),
    );
  }

  Widget _buildActionSelection(bool isUrdu) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isAdmin ? () {
                  setState(() {
                    _selectedAction = 'create';
                  });
                } : null,
                child: Text(
                  isUrdu ? 'سیکشن بنائیں' : 'Create Section',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _selectedAction = 'view';
                  });
                  _loadSections();
                },
                child: Text(
                  isUrdu ? 'سیکشن دیکھیں' : 'View Sections',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection(bool isUrdu) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _sectionNameController,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'سیکشن کا نام' : 'Section Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createSection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          isUrdu ? 'بنائیں' : 'Create',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedAction = null;
                            _sectionNameController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          isUrdu ? 'منسوخ' : 'Cancel',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSections(bool isUrdu) {
    if (_loadingSections) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              isUrdu ? 'کوئی سیکشن نہیں ملا' : 'No sections found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedAction = null;
                });
              },
              child: Text(isUrdu ? 'واپس' : 'Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _filterSections,
            decoration: InputDecoration(
              hintText: isUrdu ? 'سیکشن تلاش کریں...' : 'Search sections...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredSections.length,
            itemBuilder: (context, index) {
              final section = _filteredSections[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SectionOptionsDetailScreen(
                          section: section,
                          type: widget.type,
                          institution: widget.institution,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        if (!isUrdu) ...[
                          Icon(Icons.folder, color: Color(0xFF1976D2)),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              section.name,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                                if (_isAdmin)
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert),
                                    onSelected: (value) => _handleMenuAction(value, section),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text(isUrdu ? 'سیکشن میں ترمیم کریں' : 'Edit Section'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text(isUrdu ? 'سیکشن حذف کریں' : 'Delete Section'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                        ] else ...[
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert),
                            onSelected: (value) => _handleMenuAction(value, section),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(isUrdu ? 'سیکشن میں ترمیم کریں' : 'Edit Section'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(isUrdu ? 'سیکشن حذف کریں' : 'Delete Section'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Text(
                              section.name,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.folder, color: Color(0xFF1976D2)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Section section) async {
    switch (action) {
      case 'edit':
        _showEditSectionDialog(section);
        break;
      case 'delete':
        _showDeleteConfirmation(section);
        break;
    }
  }

  void _showEditSectionDialog(Section section) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;
    final controller = TextEditingController(text: section.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUrdu ? 'سیکشن میں ترمیم کریں' : 'Edit Section'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isUrdu ? 'سیکشن کا نام' : 'Section Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isUrdu
                        ? 'براہ کرم سیکشن کا نام درج کریں'
                        : 'Please enter section name'),
                  ),
                );
                return;
              }
              try {
                final updatedSection = Section(
                  id: section.id,
                  name: controller.text.trim(),
                  type: section.type,
                  institution: section.institution,
                );
                await DatabaseService.updateSection(updatedSection);
                Navigator.pop(context);
                _loadSections();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isUrdu
                        ? 'سیکشن اپ ڈیٹ ہو گیا'
                        : 'Section updated successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isUrdu ? 'محفوظ کریں' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Section section) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isUrdu = languageProvider.isUrdu;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUrdu ? 'تصدیق کریں' : 'Confirm'),
        content: Text(
          isUrdu
              ? 'کیا آپ واقعی اس سیکشن کو حذف کرنا چاہتے ہیں؟'
              : 'Are you sure you want to delete this section?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseService.deleteSection(section.id!);
                Navigator.pop(context);
                _loadSections();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isUrdu
                        ? 'سیکشن حذف ہو گیا'
                        : 'Section deleted successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isUrdu ? 'حذف کریں' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
