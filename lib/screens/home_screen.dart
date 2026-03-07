import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'ai_chat_screen.dart';
import 'madrasa_budget_screen.dart';
import 'students_screen.dart';
import 'settings_screen.dart';
import 'teachers_screen.dart';
import 'budget_enter_data_screen.dart';
import 'class_management_screen.dart';
import 'student_enter_data_screen.dart';
import 'teacher_enter_data_screen.dart';
import 'teacher_options_screen.dart';
import 'admission_office_screen.dart';
import 'masjid_budget_screen.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _institutionName;
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInstitutionName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInstitutionName(); // Refresh institution name when app resumes
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh institution name when dependencies change (e.g., when returning from other screens)
    _loadInstitutionName();
  }

  Future<void> _loadInstitutionName() async {
    final prefs = await SharedPreferences.getInstance();
    final institutionName = prefs.getString('institutionName');
    setState(() {
      _institutionName = institutionName;
    });
  }

  // Function to detect if text contains Urdu script
  bool _isUrduScript(String text) {
    final urduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return urduRegex.hasMatch(text);
  }

  // Function to build welcome message
  String _buildWelcomeMessage(String? institutionName, bool isUrdu) {
    if (institutionName == null || institutionName.isEmpty) {
      return isUrdu ? 'دارالعلوم نعمانیہ میں خوش آمدید' : 'Welcome to Darul Uloom Naumaniya';
    }
    
    // Check if institution name contains Urdu script
    bool hasUrduScript = _isUrduScript(institutionName);
    
    if (hasUrduScript) {
      return 'خوش آمدید $institutionName میں';
    } else {
      return 'Welcome to $institutionName';
    }
  }

  // Function to get appropriate font family
  String _getFontFamily(String? institutionName, bool isUrdu) {
    if (institutionName == null || institutionName.isEmpty) {
      return isUrdu ? 'Arial' : 'Roboto';
    }
    
    bool hasUrduScript = _isUrduScript(institutionName);
    return hasUrduScript ? 'Arial' : 'Roboto';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final bannerHeight = screenSize.height * 0.22; // 22% of screen height

    // List of modules (cards)
    final modules = [
      {
        'icon': Icons.how_to_reg,
        'title': languageProvider.isUrdu ? 'ایڈمیشن آفس' : 'Admission Office',
        'subtitle': languageProvider.isUrdu ? 'داخلہ فارم اور ریکارڈ' : 'Admission Form & Records',
        'color': Colors.teal,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdmissionOfficeScreen())),
      },
      {
        'icon': Icons.class_,
        'title': languageProvider.isUrdu ? 'کلاسز' : 'Classes',
        'subtitle': languageProvider.isUrdu ? 'کلاس مینجمنٹ' : 'Class Management',
        'color': Colors.green,
        'onTap': () => _showStudentPortfolioOptions(context, languageProvider),
      },
      {
        'icon': Icons.school,
        'title': languageProvider.isUrdu ? 'اساتذہ' : 'Teachers',
        'subtitle': languageProvider.isUrdu ? 'اساتذہ کا انتظام' : 'Manage Teachers',
        'color': Colors.orange,
        'onTap': () => _showCategoryOptions(context, 'teachers'),
      },
      {
        'icon': Icons.mosque,
        'title': languageProvider.isUrdu ? 'مسجد بجٹ' : 'Masjid Budget',
        'subtitle': languageProvider.isUrdu ? 'مالی انتظام (مسجد)' : 'Financial Management (Masjid)',
        'color': Colors.blue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => MasjidBudgetScreen())),
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': languageProvider.getText('budget_management'),
        'subtitle': languageProvider.isUrdu ? 'مالی انتظام' : 'Financial Management',
        'color': Colors.purple,
        'onTap': () => _showCategoryOptions(context, 'budget'),
      },
      {
        'icon': Icons.psychology,
        'title': languageProvider.isUrdu ? 'اے آئی اسسٹنٹ' : 'AI Assistant',
        'subtitle': languageProvider.isUrdu ? 'ذہانت سے تلاش' : 'Smart Search',
        'color': Colors.red,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => AIChatScreen())),
      },
    ];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
          children: [
          // Banner
            Container(
              width: double.infinity,
            height: bannerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                colors: [Color(0xFF0D2240), Color(0xFF1976D2)],
                ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                    padding: EdgeInsets.only(top: bannerHeight * 0.18, left: 24, right: 24),
                      child: Text(
                        _buildWelcomeMessage(_institutionName, languageProvider.isUrdu),
                        style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.18),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Positioned(
                  top: isMobile ? 18 : 28,
                  right: isMobile ? 18 : 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                      // Settings button removed - AccountSettingsScreen doesn't exist
                      SizedBox(height: 4),
                        IconButton(
                          icon: Text(
                            languageProvider.isUrdu ? 'EN' : 'اردو',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: isMobile ? 14 : 16, 
                            color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            languageProvider.toggleLanguage();
                          },
                          tooltip: languageProvider.getText('switch_language'),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                        // Settings icon below language switch
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                          },
                          tooltip: languageProvider.getText('settings'),
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Modules (Scrollable, 4 at a time)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16, left: 12, right: 12, bottom: 8),
                      child: _buildScrollableModules(context, modules, isMobile),
                    ),
                  ),
                                                        // Page indicator
                   Container(
                     height: 20,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: List.generate(
                         (modules.length / 4).ceil(),
                         (index) => AnimatedContainer(
                           duration: Duration(milliseconds: 300),
                           width: index == _currentPage ? 12 : 8,
                           height: 8,
                           margin: EdgeInsets.symmetric(horizontal: 4),
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: index == _currentPage ? Color(0xFF1976D2) : Colors.grey[300],
                           ),
                         ),
                       ),
                     ),
                   ),
                   // Scroll hint
                   if ((modules.length / 4).ceil() > 1)
                     Container(
                       padding: EdgeInsets.symmetric(vertical: 4),
                       child: Text(
                         languageProvider.isUrdu ? 'سکرول کریں مزید دیکھنے کے لیے' : 'Scroll to see more',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey[600],
                           fontStyle: FontStyle.italic,
                         ),
                       ),
                     ),
                   SizedBox(height: 8),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildScrollableModules(BuildContext context, List<Map<String, dynamic>> modules, bool isMobile) {
    // Show 4 modules at a time, scrollable vertically
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView.builder(
          controller: _pageController,
          physics: BouncingScrollPhysics(),
          itemCount: (modules.length / 4).ceil(),
          onPageChanged: (pageIndex) {
            setState(() {
              _currentPage = pageIndex;
            });
          },
          pageSnapping: true,
          padEnds: false,
          itemBuilder: (context, pageIndex) {
            final start = pageIndex * 4;
            final end = (start + 4 < modules.length) ? start + 4 : modules.length;
            final pageModules = modules.sublist(start, end);
            
            return Container(
              height: constraints.maxHeight * 0.85, // Fixed height for each page
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // First row - 2 modules
                  Expanded(
                    child: Row(
                      children: [
                        if (pageModules.length > 0)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: _buildPrettyModuleCard(
                                context,
                                icon: pageModules[0]['icon'],
                                title: pageModules[0]['title'],
                                subtitle: pageModules[0]['subtitle'],
                                color: pageModules[0]['color'],
                                onTap: pageModules[0]['onTap'],
                                isMobile: isMobile,
                              ),
                            ),
                          ),
                        if (pageModules.length > 1)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: _buildPrettyModuleCard(
                                context,
                                icon: pageModules[1]['icon'],
                                title: pageModules[1]['title'],
                                subtitle: pageModules[1]['subtitle'],
                                color: pageModules[1]['color'],
                                onTap: pageModules[1]['onTap'],
                                isMobile: isMobile,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Second row - 2 modules
                  if (pageModules.length > 2)
                    Expanded(
                      child: Row(
                        children: [
                          if (pageModules.length > 2)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                child: _buildPrettyModuleCard(
                                  context,
                                  icon: pageModules[2]['icon'],
                                  title: pageModules[2]['title'],
                                  subtitle: pageModules[2]['subtitle'],
                                  color: pageModules[2]['color'],
                                  onTap: pageModules[2]['onTap'],
                                  isMobile: isMobile,
                                ),
                              ),
                            ),
                          if (pageModules.length > 3)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                child: _buildPrettyModuleCard(
                                  context,
                                  icon: pageModules[3]['icon'],
                                  title: pageModules[3]['title'],
                                  subtitle: pageModules[3]['subtitle'],
                                  color: pageModules[3]['color'],
                                  onTap: pageModules[3]['onTap'],
                                  isMobile: isMobile,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrettyModuleCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap, required bool isMobile}) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.18), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
              blurRadius: 14,
              offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                    colors: [color.withOpacity(0.32), color.withOpacity(0.14)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.18),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                      ),
                    ],
                  border: Border.all(color: color.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(
                    icon,
                  size: isMobile ? 32 : 40,
                    color: color,
                  ),
                ),
              SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 6),
                Container(
                width: 36,
                  height: 3,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.5), color.withOpacity(0.1)],
                    ),
                  ),
                ),
              SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[800],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
          ),
        ),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, String category) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    if (category == 'budget') {
      _showBudgetOptions(context, languageProvider);
      return;
    }
    
    if (category == 'teachers') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherOptionsScreen(),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMobile ? 16 : 20),
            topRight: Radius.circular(isMobile ? 16 : 20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: isMobile ? 6 : 8),
              width: isMobile ? 32 : 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              _getCategoryTitle(category, languageProvider),
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
              child: Column(
                children: [
                  _buildOptionButton(
                    context,
                    icon: Icons.add,
                    title: languageProvider.isUrdu ? 'ڈیٹا داخل کریں' : 'Enter Data',
                    subtitle: languageProvider.isUrdu ? 'نیا ریکارڈ شامل کریں' : 'Add New Record',
                    isMobile: isMobile,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEnterData(context, category);
                    },
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
                  _buildOptionButton(
                    context,
                    icon: Icons.list,
                    title: languageProvider.isUrdu ? 'ڈیٹا دیکھیں' : 'View Data',
                    subtitle: languageProvider.isUrdu ? 'موجودہ ریکارڈز دیکھیں' : 'View Existing Records',
                    isMobile: isMobile,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToViewData(context, category);
                    },
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetOptions(BuildContext context, LanguageProvider languageProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MadrasaBudgetScreen(),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF1976D2),
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isMobile ? 14 : 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle(String category, LanguageProvider languageProvider) {
    switch (category) {
      case 'students':
        return languageProvider.isUrdu ? 'طلباء کا انتظام' : 'Student Management';
      case 'teachers':
        return languageProvider.isUrdu ? 'اساتذہ کا انتظام' : 'Teacher Management';
      case 'budget':
        return languageProvider.getText('budget_management');
      default:
        return '';
    }
  }

  void _navigateToEnterData(BuildContext context, String category) {
    switch (category) {
      case 'students':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentEnterDataScreen()),
        );
        break;
      case 'teachers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeacherEnterDataScreen()),
        );
        break;
      case 'budget':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MadrasaBudgetScreen()),
        );
        break;
    }
  }

  void _navigateToViewData(BuildContext context, String category) {
    switch (category) {
      case 'students':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentsScreen()),
        );
        break;
      case 'teachers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeachersScreen()),
        );
        break;
      case 'budget':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MadrasaBudgetScreen()),
        );
        break;
    }
  }

  void _showStudentPortfolioOptions(BuildContext context, LanguageProvider languageProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassManagementScreen(),
      ),
    );
  }
} 