import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'request_access_screen.dart';
import 'login_screen.dart';
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
    final pendingRegs = await _auth.getPendingRegistrations();  // pending_users table
    final adminReqs = await _auth.getPendingRequests();          // admin_requests table
    final accessReqs = await _auth.getAccessRequests();          // access_requests table
    final history = await _auth.getHistory();

    // Merge all request types with a tag
    final merged = [
      ...pendingRegs.map((r) => {...r, 'request_type': 'registration'}),
      ...adminReqs.map((r) => {...r, 'request_type': 'admin'}),
      ...accessReqs.map((r) => {...r, 'request_type': 'access'}),
    ];

    setState(() {
      _users = users.map((u) => u.toJson()).toList();
      _requests = merged;
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
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text(isUrdu ? 'لاگ آؤٹ' : 'Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isUrdu ? 'لاگ آؤٹ' : 'Logout'),
                    content: Text(isUrdu ? 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟' : 'Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isUrdu ? 'منسوخ' : 'Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isUrdu ? 'لاگ آؤٹ' : 'Logout', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
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

    if (_history.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAdminData,
        child: ListView(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  isUrdu ? 'کوئی تاریخ نہیں' : 'No history available',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView.separated(
        padding: EdgeInsets.all(12),
        itemCount: _history.length,
        separatorBuilder: (_, __) => Divider(height: 1),
        itemBuilder: (context, idx) {
          final h = _history[idx];
          final when = h['created_at'] ?? '';
          final actor = h['actor_name'] ?? h['actor_id']?.toString() ?? '';
          final action = h['action'] ?? '';
          final details = h['details'] ?? '';
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1976D2).withOpacity(0.12),
              child: Icon(Icons.history, size: 18, color: Color(0xFF1976D2)),
            ),
            title: Text('$action — $actor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('$details\n$when', style: TextStyle(fontSize: 11)),
            isThreeLine: details.isNotEmpty,
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

    if (!_isAdmin) {
      // Non-admin: show current user's requests and allow creating new one
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _auth.getUserAccessRequests(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
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

    // Admin: show pending admin requests from _requests list
    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAdminData,
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                isUrdu ? 'رسائی کی درخواستیں' : 'Access Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  isUrdu ? 'کوئی درخواست نہیں' : 'No pending requests',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              isUrdu ? 'رسائی کی درخواستیں (${_requests.length})' : 'Access Requests (${_requests.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._requests.map((r) {
            final reqType = r['request_type'] as String;
            final isRegistration = reqType == 'registration';
            final isAdminReq = reqType == 'admin';

            final title = r['user_name'] ?? r['name'] ?? '';
            final subtitle = isRegistration
                ? '${isUrdu ? 'نئی رجسٹریشن' : 'New registration'} • ${r['access_type'] ?? 'readonly'}${r['reason'] != null && r['reason'].toString().isNotEmpty ? ' — ${r['reason']}' : ''}'
                : isAdminReq
                    ? (r['reason'] ?? '')
                    : '${r['type'] ?? ''} access${r['reason'] != null && r['reason'].toString().isNotEmpty ? ' — ${r['reason']}' : ''}';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRegistration
                      ? Colors.green.withOpacity(0.12)
                      : isAdminReq
                          ? Colors.red.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.15),
                  child: Icon(
                    isRegistration ? Icons.person_add : isAdminReq ? Icons.admin_panel_settings : Icons.lock_open,
                    color: isRegistration ? Colors.green : isAdminReq ? Colors.red : Colors.orange,
                  ),
                ),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (isRegistration) {
                          await _auth.approvePendingUser(r['id']);
                        } else if (isAdminReq) {
                          await _auth.reviewAdminRequest(r['id'], true);
                        } else {
                          await _auth.reviewAccessRequest(r['id'], true);
                        }
                        _loadAdminData();
                      },
                      child: Text(isUrdu ? 'منظور' : 'Approve', style: TextStyle(color: Colors.green)),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (isRegistration) {
                          await _auth.rejectPendingUser(r['id']);
                        } else if (isAdminReq) {
                          await _auth.reviewAdminRequest(r['id'], false);
                        } else {
                          await _auth.reviewAccessRequest(r['id'], false);
                        }
                        _loadAdminData();
                      },
                      child: Text(isUrdu ? 'رد' : 'Reject', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
