import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class DeviceApprovalScreen extends StatefulWidget {
  final String? email;
  const DeviceApprovalScreen({Key? key, this.email}) : super(key: key);

  @override
  State<DeviceApprovalScreen> createState() => _DeviceApprovalScreenState();
}

class _DeviceApprovalScreenState extends State<DeviceApprovalScreen> {
  bool _isCreator = false;
  bool _loading = true;
  List<Map<String, dynamic>> _pendingDevices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    setState(() { _loading = true; });
    try {
      final user = FirebaseService().currentUser;
      if (user == null) throw 'Not logged in';
      final userDoc = await FirebaseService().firestore.collection('users').doc(user.uid).get();
      _isCreator = userDoc.data()?['role'] == 'creator';
      if (_isCreator) {
        _pendingDevices = await FirebaseService().getPendingDevices();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _approve(String deviceId) async {
    setState(() { _loading = true; });
    try {
      await FirebaseService().approveDevice(deviceId);
      await _checkRoleAndLoad();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!, style: TextStyle(color: Colors.red))));
    if (!_isCreator) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Device Approval'),
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
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Your device access request has been sent. Please ask the account creator to approve this device.\n\nYou will be able to use the app once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Device Approvals'),
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
      body: _pendingDevices.isEmpty
          ? Center(child: Text('No pending device requests.'))
          : ListView.builder(
              itemCount: _pendingDevices.length,
              itemBuilder: (context, i) {
                final d = _pendingDevices[i];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(d['deviceName'] ?? d['deviceId'] ?? 'Unknown'),
                    subtitle: Text('Platform: ${d['platform'] ?? ''}\nID: ${d['deviceId']}'),
                    trailing: ElevatedButton(
                      onPressed: () => _approve(d['deviceId']),
                      child: Text('Approve'),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 