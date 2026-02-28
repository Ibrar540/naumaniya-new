import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/auto_sync_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/teacher_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Neon Database for background tasks
      await DatabaseService.initialize();
      
      // Then initialize auto sync service
      return Future.value(true);
    } catch (e) {
      // Log error but don't crash
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Neon Database
  try {
    await DatabaseService.initialize();
    debugPrint('✅ Neon database initialized successfully');
  } catch (e) {
    debugPrint('❌ Neon database initialization error: $e');
  }
  
  // Only initialize Workmanager on mobile platforms
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    // Register periodic sync task
    await Workmanager().registerPeriodicTask(
      'budgetSyncTask',
      'budgetSyncTask',
      frequency: Duration(hours: 1),
      initialDelay: Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  if (kIsWeb) {
    await _fixStudentStatusWeb();
  }
  // FirebaseService().initialize() is not needed since Firebase is already initialized above
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // ChangeNotifierProvider(create: (_) => FirestoreDataProvider()), // Removed - uses Firebase
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AutoSyncProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()), // <-- Added
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _fixStudentStatusWeb() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'students_data';
    final data = prefs.getString(key);
    if (data != null) {
      final List students = jsonDecode(data);
      bool updated = false;
      for (final student in students) {
        final status = (student['status'] ?? '').toString().trim();
        if (status.isEmpty) {
          student['status'] = 'Active';
          updated = true;
        }
      }
      if (updated) {
        await prefs.setString(key, jsonEncode(students));
        // print('Updated web students with empty status to "Active".'); // Removed print
      }
    }
  } catch (e) {
    // print('Error in _fixStudentStatusWeb: $e\n$st'); // Removed print
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return Directionality(
          textDirection:
              languageProvider.isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp(
            title: 'Naumaniya',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[50],
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.all(8),
              ),
              textTheme: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: Color(0xFF121212),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFF22223B),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.all(8),
                color: Color(0xFF1E1E1E),
              ),
              textTheme: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              // '/login': (context) => LoginScreen(), // Removed - uses Firebase Auth
              '/home': (context) => HomeScreen(),
              // '/device-approval': (context) => DeviceApprovalScreen(email: ''), // Removed - uses Firebase Auth
              // '/account-settings': (context) => AccountSettingsScreen(), // Removed - uses Firebase Auth
            },
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

// Remove duplicate HomeScreen class
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Home')),
//       body: Center(child: Text('Welcome! You are logged in and your device is approved.')),
//     );
//   }
// }
