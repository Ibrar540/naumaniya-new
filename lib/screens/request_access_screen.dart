import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';

class RequestAccessScreen extends StatefulWidget {
  final bool fromSignup;
  const RequestAccessScreen({super.key, this.fromSignup = false});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  String _type = 'readonly';
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _auth.initialize();
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    final ok = await _auth.createAccessRequest(_type, null, _reasonController.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;

    if (ok) {
      // Clear the temp session — user must wait for approval
      await _auth.logout();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.hourglass_top, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isUrdu ? 'درخواست جمع ہو گئی' : 'Request Submitted'),
          ]),
          content: Text(
            isUrdu
                ? 'آپ کی درخواست جمع ہو گئی ہے۔ ایڈمن کی منظوری کے بعد آپ لاگ ان کر سکیں گے۔'
                : 'Your request has been submitted. You can log in after an admin approves it.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(isUrdu ? 'ٹھیک ہے' : 'OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUrdu ? 'درخواست ناکام ہوئی' : 'Request failed. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'رسائی کی درخواست' : 'Request Access'),
        automaticallyImplyLeading: !widget.fromSignup,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fromSignup) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'آپ کا اکاؤنٹ بن گیا ہے۔ براہ کرم رسائی کی قسم منتخب کریں اور درخواست بھیجیں۔'
                            : 'Account created! Choose your access type and submit a request.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              isUrdu ? 'رسائی کی قسم منتخب کریں' : 'Select Access Type',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [_type == 'readonly', _type == 'full'],
              onPressed: (idx) => setState(() => _type = idx == 0 ? 'readonly' : 'full'),
              borderRadius: BorderRadius.circular(8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(isUrdu ? 'صرف پڑھنے کی رسائی' : 'Read-only'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(isUrdu ? 'مکمل رسائی' : 'Full access'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isUrdu ? 'وجہ (اختیاری)' : 'Reason (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isUrdu ? 'درخواست بھیجیں' : 'Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
