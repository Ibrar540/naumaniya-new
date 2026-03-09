import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'request_access_screen.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  bool _isAdmin = false;
  bool _loading = true;

  // Profile fields
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _savingProfile = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _auth.initialize();
    setState(() {
      _isAdmin = _auth.isAdmin;
      _nameController.text = _auth.currentUser?.name ?? '';
      _loading = false;
    });
    if (_isAdmin) await _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final users = await _auth.getAllUsers();
    final reqs = await _auth.getPendingRequests();
    final history = await _auth.getHistory();
    setState(() {
      _users = users.map((u) => u.toJson()).toList();
      _requests = reqs;
      _history = history;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final ok = await _auth.updateProfile(_nameController.text.trim(), _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim());
    setState(() => _savingProfile = false);
    final snack = ok ? 'Profile updated' : 'Failed to update profile';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }

  Widget _buildProfileTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: isUrdu ? 'نام' : 'Name'),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: isUrdu ? 'نیا پاس ورڈ' : 'New Password'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _savingProfile ? null : _saveProfile,
            child: _savingProfile ? CircularProgressIndicator() : Text(isUrdu ? 'محفوظ کریں' : 'Save Profile'),
          ),
          SizedBox(height: 12),
          if (!_isAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final reason = await showDialog<String?>(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: Text(isUrdu ? 'ایڈمن کی درخواست بھیجیں' : 'Request Admin Access'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(hintText: isUrdu ? 'وجہ لکھیں' : 'Enter reason'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isUrdu ? 'منسوخ' : 'Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(isUrdu ? 'بھیجیں' : 'Send')),
                        ],
                      );
                    },
                  );
                  if (reason != null && reason.isNotEmpty) {
                    final ok = await _auth.requestAdminAccess(reason);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? (isUrdu ? 'درخواست جمع ہو گئی' : 'Request submitted') : (isUrdu ? 'درخواست ناکام' : 'Request failed'))));
                  }
                },
                child: Text(isUrdu ? 'ایڈمن کی درخواست بھیجیں' : 'Request Admin Access'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    if (!_isAdmin) return Center(child: Text(isUrdu ? 'صرف ایڈمن کو اجازت ہے' : 'Admin only'));

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(isUrdu ? 'صارفین' : 'Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._users.map((u) {
            return ListTile(
              title: Text(u['name'] ?? ''),
              subtitle: Text('${u['role'] ?? ''} • ${u['is_active'] == true ? 'Active' : 'Inactive'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'deactivate') {
                    final ok = await _auth.updateUserStatus(u['id'], false);
                    if (ok) _loadAdminData();
                  } else if (v == 'activate') {
                    final ok = await _auth.updateUserStatus(u['id'], true);
                    if (ok) _loadAdminData();
                  } else if (v == 'delete') {
                    final ok = await _auth.deleteUser(u['id']);
                    if (ok) _loadAdminData();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: u['is_active'] == true ? 'deactivate' : 'activate', child: Text(u['is_active'] == true ? (isUrdu ? 'غیر فعال کریں' : 'Deactivate') : (isUrdu ? 'فعال کریں' : 'Activate'))),
                  PopupMenuItem(value: 'delete', child: Text(isUrdu ? 'حذف کریں' : 'Delete')),
                ],
              ),
            );
          }).toList(),
          Divider(),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(isUrdu ? 'ایڈمن درخواستیں' : 'Admin Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._requests.map((r) {
            return ListTile(
              title: Text(r['user_name'] ?? ''),
              subtitle: Text(r['reason'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () async { await _auth.reviewAdminRequest(r['id'], true); _loadAdminData(); }, child: Text(isUrdu ? 'منظور' : 'Approve')),
                  TextButton(onPressed: () async { await _auth.reviewAdminRequest(r['id'], false); _loadAdminData(); }, child: Text(isUrdu ? 'رد' : 'Reject')),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    if (!_isAdmin) return Center(child: Text(isUrdu ? 'صرف ایڈمن کو اجازت ہے' : 'Admin only'));

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, idx) {
          final h = _history[idx];
          final when = h['created_at'] ?? '';
          final actor = h['actor_name'] ?? h['actor_id']?.toString() ?? '';
          final action = h['action'] ?? '';
          final details = h['details'] ?? '';

          return ListTile(
            title: Text('$action — $actor'),
            subtitle: Text('$details\n$when'),
            isThreeLine: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isUrdu ? 'ترتیبات' : 'Settings'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: isUrdu ? 'پروفائل' : 'Profile'),
              Tab(text: isUrdu ? 'صارفین' : 'Users'),
              Tab(text: isUrdu ? 'درخواستیں' : 'Requests'),
              Tab(text: isUrdu ? 'تاریخ' : 'History'),
            ],
          ),
        ),
        body: _loading ? Center(child: CircularProgressIndicator()) : TabBarView(
          children: [
            _buildProfileTab(),
            _buildUsersTab(),
            _buildRequestsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    if (_isAdmin) {
      // Admin: show pending access requests
      return RefreshIndicator(
        onRefresh: _loadAdminData,
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(isUrdu ? 'رسائی کی درخواستیں' : 'Access Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ..._requests.map((r) {
              return ListTile(
                title: Text(r['user_name'] ?? ''),
                subtitle: Text('${r['type'] ?? ''} • ${r['reason'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () async { await _auth.reviewAccessRequest(r['id'], true); _loadAdminData(); }, child: Text(isUrdu ? 'منظور' : 'Approve')),
                    TextButton(onPressed: () async { await _auth.reviewAccessRequest(r['id'], false); _loadAdminData(); }, child: Text(isUrdu ? 'رد' : 'Reject')),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    // Non-admin: show current user's requests and allow creating new one
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _auth.getUserAccessRequests(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
        final items = snap.data ?? [];
        return ListView(
          padding: EdgeInsets.all(12),
          children: [
            ElevatedButton(
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestAccessScreen()));
              },
              child: Text(isUrdu ? 'درخواست بنائیں' : 'Create Request'),
            ),
            SizedBox(height: 12),
            ...items.map((r) => ListTile(
              title: Text('${r['type'] ?? ''} • ${r['status'] ?? ''}'),
              subtitle: Text(r['reason'] ?? ''),
            )).toList(),
          ],
        );
      },
    );
  }
}
