import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/section.dart';
import 'section_data_screen.dart';
import 'budget_enter_data_screen.dart';
import 'home_screen.dart';

class SectionOptionsDetailScreen extends StatelessWidget {
  final Section section;
  final String type;
  final String institution;

  const SectionOptionsDetailScreen({
    super.key,
    required this.section,
    required this.type,
    required this.institution,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(
        title: Text(section.name),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
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
      body: Center(
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetEnterDataScreen(
                        type: type,
                        section: section,
                        institution: institution,
                      ),
                    ),
                  );
                },
                child: Text(
                  isUrdu ? 'ڈیٹا شامل کریں' : 'Enter Data',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionDataScreen(
                        section: section,
                        type: type,
                        institution: institution,
                      ),
                    ),
                  );
                },
                child: Text(
                  isUrdu ? 'ڈیٹا دیکھیں' : 'View Data',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
