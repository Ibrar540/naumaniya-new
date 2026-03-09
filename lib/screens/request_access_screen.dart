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
  final _modulesController = TextEditingController();
  final _reasonController = TextEditingController();

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    final modules = _modulesController.text.trim().isEmpty
        ? null
        : _modulesController.text.split(',').map((s) => s.trim()).toList();

    final ok = await _auth.createAccessRequest(_type, modules, _reasonController.text.trim());
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
    _modulesController.dispose();
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
            ListTile(
              title: Text(isUrdu ? 'صرف پڑھنے کی رسائی' : 'Read-only access'),
              leading: Radio<String>(value: 'readonly', groupValue: _type, onChanged: (v) => setState(() => _type = v!)),
            ),
            ListTile(
              title: Text(isUrdu ? 'مکمل رسائی' : 'Full access'),
              leading: Radio<String>(value: 'full', groupValue: _type, onChanged: (v) => setState(() => _type = v!)),
            ),
            TextField(
              controller: _modulesController,
              decoration: InputDecoration(labelText: isUrdu ? 'ماڈیولز (کوما سے جدا کریں)' : 'Modules (comma-separated)', hintText: isUrdu ? 'مثال: madrasa, masjid' : 'e.g. madrasa, masjid'),
            ),
            SizedBox(height: 8),
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
