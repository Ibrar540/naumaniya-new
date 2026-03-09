import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

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
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request submitted')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed')));
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
      appBar: AppBar(title: Text(isUrdu ? 'رسائی کی درخواست' : 'Request Access')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [_type == 'readonly', _type == 'full'],
              onPressed: (idx) => setState(() => _type = idx == 0 ? 'readonly' : 'full'),
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(isUrdu ? 'صرف پڑھنے کی رسائی' : 'Read-only')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(isUrdu ? 'مکمل رسائی' : 'Full access')),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: isUrdu ? 'وجہ (اختیاری)' : 'Reason (optional)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading ? CircularProgressIndicator() : Text(isUrdu ? 'درخواست بھیجیں' : 'Send Request'),
            ),
          ],
        ),
      ),
    );
  }
}
