import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _auth.initialize();
    final items = await _auth.getNotifications();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markRead(int id) async {
    final ok = await _auth.markNotificationRead(id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(title: Text(isUrdu ? 'نوٹیفیکیشنز' : 'Notifications')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [Center(child: Padding(padding: EdgeInsets.all(24), child: Text(isUrdu ? 'کوئی نوٹیفیکیشن نہیں' : 'No notifications')))])
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, idx) {
                        final n = _items[idx];
                        final isRead = n['is_read'] == true;
                        final created = n['created_at'] ?? '';
                        return ListTile(
                          title: Text(n['message'] ?? ''),
                          subtitle: Text(created.toString()),
                          trailing: isRead ? null : TextButton(onPressed: () => _markRead(n['id']), child: Text(isUrdu ? 'پڑھا' : 'Mark read')),
                        );
                      },
                    ),
            ),
    );
  }
}
