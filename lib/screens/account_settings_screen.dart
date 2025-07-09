import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../services/firebase_service.dart';
// import '../providers/firestore_data_provider.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
// import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  // final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false; // Changed to false for web testing
  String? _error;
  Map<String, String?> userInfo = {};
  bool _showAccountInfo = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // _loadData(); // Enable Firebase by default
    AuthService().loadUserInfo().then((info) {
      setState(() {
        userInfo = info;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.getText('account_settings')),
          backgroundColor: Color(0xFF1976D2),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Home',
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      // Remove Firebase disabled error UI
      // Only show real errors if any
      return Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.getText('account_settings')),
          backgroundColor: Color(0xFF1976D2),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Home',
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('account_settings')),
        backgroundColor: Color(0xFF1976D2),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
          tooltip: 'Home',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            tooltip: languageProvider.getText('switch_language'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Info (hidden by default)
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(languageProvider.getText('account_information'), style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Icon(_showAccountInfo ? Icons.expand_less : Icons.expand_more),
                    onTap: () {
                      setState(() { _showAccountInfo = !_showAccountInfo; });
                    },
                  ),
                  if (_showAccountInfo)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(title: Text('Full Name'), subtitle: Text(userInfo['fullName'] ?? '')),
                          ListTile(title: Text('Email'), subtitle: Text(userInfo['email'] ?? '')),
                          ListTile(title: Text('Institution'), subtitle: Text(userInfo['institutionName'] ?? '')),
                          ListTile(
                            title: Text('Password'),
                            subtitle: Text(_obscurePassword ? '******' : (userInfo['password'] ?? '')),
                            trailing: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() { _obscurePassword = !_obscurePassword; });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Other Options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.manage_accounts),
                    title: Text('Manage Others Account'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ManageOthersAccountScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notifications'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.devices),
                    title: Text('Device Management'),
                    onTap: () {
                      // Implement or navigate to device management screen
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device management coming soon.')));
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Sign Out
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Temporarily just go back to login
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: Icon(Icons.logout),
                label: Text(languageProvider.getText('sign_out')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageOthersAccountScreen extends StatefulWidget {
  @override
  _ManageOthersAccountScreenState createState() => _ManageOthersAccountScreenState();
}

class _ManageOthersAccountScreenState extends State<ManageOthersAccountScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    users = snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
    setState(() {
      filteredUsers = users;
      loading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = users
          .where((user) => (user['fullName'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _promptForPassword(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter password for ${user['fullName']}'),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, passwordController.text), child: Text('Submit')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _sendAccessRequest(user, result);
    }
  }

  void _sendAccessRequest(Map<String, dynamic> user, String password) async {
    // Check password
    if (user['password'] != password) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect password for ${user['fullName']}')));
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Request'),
        content: Text('Send request to manage ${user['fullName']}\'s account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Send')),
        ],
      ),
    );
    if (confirm != true) return;
    // Save request in Firestore
    await FirebaseFirestore.instance.collection('users').doc(user['uid']).collection('requests').add({
      'fromUserId': currentUser.uid,
      'toUserId': user['uid'],
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request sent to manage ${user['fullName']}\'s account.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Others' Account")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterUsers,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        title: Text(user['fullName'] ?? ''),
                        onTap: () => _promptForPassword(user),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  String? currentUid;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    currentUid = user.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .get();
    requests = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    setState(() {
      loading = false;
    });
  }

  Future<String?> _getUserName(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['fullName'] ?? 'Unknown';
  }

  void _handleRequest(Map<String, dynamic> request, bool accept) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('requests')
        .doc(request['id']);
    if (accept) {
      // Set status to accepted
      await docRef.update({'status': 'accepted'});
      // Add requester to allowedUsers
      final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUid);
      await userDoc.update({
        'allowedUsers': FieldValue.arrayUnion([request['fromUserId']])
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Access granted.')));
    } else {
      // Set status to rejected
      await docRef.update({'status': 'rejected'});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request rejected.')));
    }
    _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? Center(child: Text('No pending requests.'))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return FutureBuilder<String?>(
                      future: _getUserName(req['fromUserId']),
                      builder: (context, snapshot) {
                        final requesterName = snapshot.data ?? 'User';
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text('$requesterName wants to manage your account'),
                            subtitle: Text('Status: ${req['status']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _handleRequest(req, true),
                                  child: Text('Accept'),
                                ),
                                TextButton(
                                  onPressed: () => _handleRequest(req, false),
                                  child: Text('Reject'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class ManageYourAccountScreen extends StatefulWidget {
  @override
  _ManageYourAccountScreenState createState() => _ManageYourAccountScreenState();
}

class _ManageYourAccountScreenState extends State<ManageYourAccountScreen> {
  String? fullName, email, institutionName, password, uid;
  List<Map<String, dynamic>> allowedUsers = [];
  bool loading = true;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    uid = user.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    fullName = data['fullName'];
    email = data['email'];
    institutionName = data['institutionName'];
    password = data['password'];
    _fullNameController.text = fullName ?? '';
    _institutionController.text = institutionName ?? '';
    _passwordController.text = password ?? '';
    // Load allowed users
    final allowed = (data['allowedUsers'] as List?) ?? [];
    allowedUsers = [];
    for (final userId in allowed) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        allowedUsers.add({'uid': userId, 'fullName': userDoc.data()?['fullName'] ?? 'Unknown'});
      }
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _removeAllowedUser(String userId) async {
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'allowedUsers': FieldValue.arrayRemove([userId])
    });
    setState(() {
      allowedUsers.removeWhere((u) => u['uid'] == userId);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User removed from allowed list.')));
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (uid == null) return;
    final newFullName = _fullNameController.text.trim();
    final newInstitution = _institutionController.text.trim();
    final newPassword = _passwordController.text.trim();
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName': newFullName,
      'institutionName': newInstitution,
      'password': newPassword,
    });
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', newFullName);
    await prefs.setString('institutionName', newInstitution);
    await prefs.setString('password', newPassword);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account updated.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Your Account')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Allowed Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  ...allowedUsers.map((u) => ListTile(
                        title: Text(u['fullName'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeAllowedUser(u['uid']),
                        ),
                      )),
                  if (allowedUsers.isEmpty)
                    Text('No users allowed to manage your account.'),
                  Divider(height: 32),
                  Text('Edit Account Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(labelText: 'Full Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _institutionController,
                          decoration: InputDecoration(labelText: 'Institution Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          initialValue: email,
                          decoration: InputDecoration(labelText: 'Email (not editable)'),
                          enabled: false,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveChanges,
                          child: Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 