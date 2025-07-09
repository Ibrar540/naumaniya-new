import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  bool _isUrdu = true;

  bool get isUrdu => _isUrdu;
  bool get isEnglish => !_isUrdu;

  // English translations
  static const Map<String, String> englishTranslations = {
    // Common
    'add': 'Add',
    'update': 'Update',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'download': 'Download',
    'ok': 'OK',
    'clear': 'Clear',
    'save': 'Save',
    'back': 'Back',
    
    // Navigation
    'students': 'Students',
    'teachers': 'Teachers',
    'budget_management': 'Madrasa\'s Budget',
    'ai_reporting': 'AI Reporting',
    'home': 'Home',
    'dashboard': 'Dashboard',
    
    // Students
    'student_name': 'Student Name',
    'father_name': 'Father\'s Name',
    'father_mobile': 'Father\'s Mobile',
    'admission_date': 'Admission Date',
    'fee': 'Fee',
    'status': 'Status',
    'stuckup_date': 'Stuckup Date',
    'select_date': 'Select Date',
    'enter_name': 'Enter name',
    'total_amount': 'Total Amount',
    'present_income': 'Present Income',
    'total_amount_all_students': 'Total amount of all students',
    'total_fee_present_students': 'Total fee of all present students',
    'download_whole_data': 'Download Whole Data',
    'search_total_amount': 'Search Total Amount',
    'search_students': 'Search by name, father name, or mobile',
    
    // Teachers
    'teacher_name': 'Teacher Name',
    'mobile': 'Mobile',
    'starting_year': 'Starting Year',
    'joining_date': 'Joining Date',
    'date_of_leaving': 'Date of Leaving',
    'salary': 'Salary',
    'present_total_salary': 'Present Total Salary',
    'total_salary': 'Total Salary',
    'total_salary_present_teachers': 'Total salary of all present teachers',
    'total_salary_all_teachers': 'Total salary of all teachers',
    'search_total_salary': 'Search Total Salary',
    'search_teachers': 'Search by name or mobile',
    
    // Budget Management
    'income': 'Income',
    'expenditure': 'Expenditure',
    'description': 'Description',
    'amount': 'Amount',
    'date': 'Date',
    'total_income_current_month': 'Total Income (Current Month)',
    'total_expenditure_current_month': 'Total Expenditure (Current Month)',
    'search_budget': 'Search by description, amount, or date',
    'search_by_month_year': 'Search by month or year',
    'search_result': 'Search Result',
    'download_docs': 'Download Docs',
    'download_pdf': 'Download PDF',
    'download_excel': 'Download Excel',
    'download_options': 'Download Options',
    'choose_download_format': 'Choose download format',
    'enter_data': 'Enter Data',
    'view_data': 'View Data',
    'income_description': 'Income Description',
    'expenditure_description': 'Expenditure Description',
    'income_amount': 'Income Amount',
    'expenditure_amount': 'Expenditure Amount',
    'add_income': 'Add Income',
    'add_expenditure': 'Add Expenditure',
    'please_enter_description': 'Please enter description',
    'please_enter_amount': 'Please enter amount',
    'please_select_date': 'Please select date',
    'income_added_successfully': 'Income added successfully!',
    'expenditure_added_successfully': 'Expenditure added successfully!',
    'error_adding_record': 'Error adding record',
    'add_financial_record': 'Add Financial Record',
    'financial_record_added': 'Financial record added successfully!',
    'switch_language': 'Switch Language',
    'urdu': 'اردو',
    'english': 'English',
    
    // AI Reporting
    'ai_search': 'AI Search',
    'search_examples': 'Search Examples',
    'search_results': 'Search Results',
    'download_results': 'Download Results',
    'ai_reporting_system': 'AI Reporting System',
    'search_across_modules': 'Search across all modules to generate comprehensive reports',
    'start_search': 'Start Search',
    'no_results_found': 'No results found for',
    'search_query': 'Search Query',
    'ai_report': 'AI Report',
    
    // Status values (always in English)
    'active': 'active',
    'left': 'left',
    'stuckup': 'stuckup',
    'none': 'none',
    
    // Class Management
    'create_class': 'Create Class',
    'go_to_classes': 'Go to Classes',
    'class_name': 'Class Name',
    'enter_class_name': 'Enter class name',
    'please_enter_class_name': 'Please enter class name',
    'class_created_successfully': 'Class created successfully!',
    'class_updated_successfully': 'Class updated successfully!',
    'class_deleted_successfully': 'Class deleted successfully!',
    'error_creating_class': 'Error creating class',
    'error_updating_class': 'Error updating class',
    'error_deleting_class': 'Error deleting class',
    'student_portfolio': 'Student Portfolio',
    'class_management': 'Class Management',
    'no_classes_found': 'No classes found',
    'create_new_class': 'Create New Class',
    'edit_class': 'Edit Class',
    'delete_class': 'Delete Class',
    'are_you_sure_delete_class': 'Are you sure you want to delete this class?',
    'this_will_delete_all_students': 'This will delete all students in this class.',
    
    // Status Validation Messages
    'please_enter_active_or_stuckup': 'Please enter active or stuckup',
    'please_enter_active_or_left': 'Please enter active or left',
    'urdu_please_enter_active_or_stuckup': 'براہ کرم active یا stuckup درج کریں',
    'urdu_please_enter_active_or_left': 'براہ کرم active یا left درج کریں',
    
    // Search Examples
    'search_examples_students': 'Search Examples: Ahmed, 2024, January, 5000',
    'search_examples_teachers': 'Search Examples: Ali, 2024, January, 15000',
    'search_examples_budget': 'Search Examples: Rent, 5000, 2024, January',
    'search_by_name': 'Search by name',
    'search_by_month': 'Search by month',
    'search_by_year': 'Search by year',
    'search_by_amount': 'Search by amount',
    'search_by_description': 'Search by description',
    'search_results_found': 'Search results found',
    'no_search_results': 'No search results',
    'search_summary': 'Search summary',
    'confirm_status_change': 'Confirm Status Change',
    'change': 'Change',
  };

  // Urdu translations
  static const Map<String, String> urduTranslations = {
    // Common
    'add': 'شامل کریں',
    'update': 'اپڈیٹ کریں',
    'cancel': 'منسوخ کریں',
    'delete': 'حذف کریں',
    'edit': 'ترمیم کریں',
    'search': 'تلاش کریں',
    'download': 'ڈاؤن لوڈ کریں',
    'ok': 'ٹھیک ہے',
    'clear': 'صاف کریں',
    'save': 'محفوظ کریں',
    'back': 'واپس',
    
    // Navigation
    'students': 'طلباء',
    'teachers': 'اساتذہ',
    'budget_management': 'مدرسہ بجٹ',
    'ai_reporting': 'اے آئی رپورٹنگ',
    'home': 'ہوم',
    'dashboard': 'ڈیش بورڈ',
    
    // Students
    'student_name': 'طالب علم کا نام',
    'father_name': 'والد کا نام',
    'father_mobile': 'والد کا موبائل',
    'admission_date': 'داخلے کی تاریخ',
    'fee': 'فیس',
    'status': 'حیثیت',
    'stuckup_date': 'رکاوٹ کی تاریخ',
    'select_date': 'تاریخ منتخب کریں',
    'enter_name': 'نام درج کریں',
    'total_amount': 'کل رقم',
    'present_income': 'موجودہ آمدنی',
    'total_amount_all_students': 'تمام طلباء کی کل رقم',
    'total_fee_present_students': 'تمام موجودہ طلباء کی کل فیس',
    'download_whole_data': 'پورا ڈیٹا ڈاؤن لوڈ کریں',
    'search_total_amount': 'کل رقم تلاش کریں',
    'search_students': 'نام، والد کا نام یا موبائل کے مطابق تلاش کریں',
    
    // Teachers
    'teacher_name': 'استاد کا نام',
    'mobile': 'موبائل',
    'starting_year': 'شروع کرنے کا سال',
    'joining_date': 'جوننگ کی تاریخ',
    'date_of_leaving': 'چھوڑنے کی تاریخ',
    'salary': 'تنخواہ',
    'present_total_salary': 'موجودہ کل تنخواہ',
    'total_salary': 'کل تنخواہ',
    'total_salary_present_teachers': 'تمام موجودہ اساتذہ کی کل تنخواہ',
    'total_salary_all_teachers': 'تمام اساتذہ کی کل تنخواہ',
    'search_total_salary': 'کل تنخواہ تلاش کریں',
    'search_teachers': 'نام یا موبائل کے مطابق تلاش کریں',
    
    // Budget Management
    'income': 'آمدنی',
    'expenditure': 'خرچ',
    'description': 'تفصیل',
    'amount': 'رقم',
    'date': 'تاریخ',
    'total_income_current_month': 'کل آمدنی (موجودہ مہینہ)',
    'total_expenditure_current_month': 'کل خرچ (موجودہ مہینہ)',
    'search_budget': 'تفصیل، رقم یا تاریخ کے مطابق تلاش کریں',
    'search_by_month_year': 'مہینہ یا سال کے مطابق تلاش کریں',
    'search_result': 'تلاش کا نتیجہ',
    'download_docs': 'ڈاکس ڈاؤن لوڈ کریں',
    'download_pdf': 'پی ڈی ایف ڈاؤن لوڈ کریں',
    'download_excel': 'ای ایسی ایکسل ڈاؤن لوڈ کریں',
    'download_options': 'ڈاؤن لوڈ کے اختیارات',
    'choose_download_format': 'ڈاؤن لوڈ کی شکل منتخب کریں',
    'enter_data': 'ڈیٹا درج کریں',
    'view_data': 'ڈیٹا دیکھیں',
    'income_description': 'آمدنی کی تفصیل',
    'expenditure_description': 'خرچ کی تفصیل',
    'income_amount': 'آمدنی کی رقم',
    'expenditure_amount': 'خرچ کی رقم',
    'add_income': 'آمدنی شامل کریں',
    'add_expenditure': 'خرچ شامل کریں',
    'please_enter_description': 'تفصیل درج کریں',
    'please_enter_amount': 'رقم درج کریں',
    'please_select_date': 'تاریخ منتخب کریں',
    'income_added_successfully': 'آمدنی شامل ہوگئی',
    'expenditure_added_successfully': 'خرچ شامل ہوگئی',
    'error_adding_record': 'رکورڈ شامل کرنے میں خطا',
    'add_financial_record': 'مالی رکورڈ شامل کریں',
    'financial_record_added': 'مالی رکورڈ شامل ہوگئی',
    'switch_language': 'لغت بدلیں',
    'urdu': 'اردو',
    'english': 'انگریزی',
    
    // AI Reporting
    'ai_search': 'اے آئی تلاش',
    'search_examples': 'تلاش کی مثالیں',
    'search_results': 'تلاش کے نتائج',
    'download_results': 'نتائج ڈاؤن لوڈ کریں',
    'ai_reporting_system': 'اے آئی رپورٹنگ سسٹم',
    'search_across_modules': 'جامع رپورٹس تیار کرنے کے لیے تمام ماڈیولز میں تلاش کریں',
    'start_search': 'تلاش شروع کریں',
    'no_results_found': 'کوئی نتیجہ نہیں ملا',
    'search_query': 'تلاش کا سوال',
    'ai_report': 'اے آئی رپورٹ',
    
    // Status values (always in English)
    'active': 'active',
    'left': 'left',
    'stuckup': 'stuckup',
    'none': 'none',
    
    // Class Management
    'create_class': 'کلاس بنائیں',
    'go_to_classes': 'کلاسز کو دیکھیں',
    'class_name': 'کلاس کا نام',
    'enter_class_name': 'کلاس کا نام درج کریں',
    'please_enter_class_name': 'کلاس کا نام درج کریں',
    'class_created_successfully': 'کلاس بنائی ہے',
    'class_updated_successfully': 'کلاس اپڈیٹ کردی ہے',
    'class_deleted_successfully': 'کلاس حذف کردی ہے',
    'error_creating_class': 'کلاس بنانے میں خطا',
    'error_updating_class': 'کلاس اپڈیٹ کرنے میں خطا',
    'error_deleting_class': 'کلاس حذف کرنے میں خطا',
    'student_portfolio': 'طالب علم کا پورٹفولیو',
    'class_management': 'کلاس مینجمنٹ',
    'no_classes_found': 'کوئی کلاس نہیں ملا',
    'create_new_class': 'نیا کلاس بنائیں',
    'edit_class': 'کلاس اپڈیٹ کریں',
    'delete_class': 'کلاس حذف کریں',
    'are_you_sure_delete_class': 'آیا آپ واقعا اس کلاس کو حذف کرنا چاہتے ہیں؟',
    'this_will_delete_all_students': 'یہ تمام طلباء حذف کرے گی اس کلاس میں',
    
    // Status Validation Messages
    'please_enter_active_or_stuckup': 'Please enter active or stuckup',
    'please_enter_active_or_left': 'Please enter active or left',
    'urdu_please_enter_active_or_stuckup': 'براہ کرم active یا stuckup درج کریں',
    'urdu_please_enter_active_or_left': 'براہ کرم active یا left درج کریں',
    
    // Search Examples
    'search_examples_students': 'تلاش مثالیں: احمد، 2024، جنوری، 5000',
    'search_examples_teachers': 'تلاش مثالیں: علی، 2024، جنوری، 15000',
    'search_examples_budget': 'تلاش مثالیں: رنٹ، 5000، 2024، جنوری',
    'search_by_name': 'نام کے مطابق تلاش کریں',
    'search_by_month': 'مہینہ کے مطابق تلاش کریں',
    'search_by_year': 'سال کے مطابق تلاش کریں',
    'search_by_amount': 'رقم کے مطابق تلاش کریں',
    'search_by_description': 'تفصیل کے مطابق تلاش کریں',
    'search_results_found': 'تلاش نتائج ملہ',
    'no_search_results': 'تلاش نتائج نہیں ملہ',
    'search_summary': 'تلاش خلاصہ',
    'confirm_status_change': 'تصدیق حیثیت تبدیلی',
    'change': 'تبدیلی',
  };

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isUrdu = prefs.getBool(_languageKey) ?? true;
      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isUrdu = !_isUrdu;
      await prefs.setBool(_languageKey, _isUrdu);
      notifyListeners();
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  String getText(String key) {
    if (_isUrdu) {
      return urduTranslations[key] ?? englishTranslations[key] ?? key;
    } else {
      return englishTranslations[key] ?? key;
    }
  }

  // Helper method to get status text (always in English)
  String getStatusText(String status) {
    // Status values are always kept in English
    return status.toLowerCase();
  }
} 