import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestService {
  static final FirebaseTestService _instance = FirebaseTestService._internal();
  factory FirebaseTestService() => _instance;
  FirebaseTestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test Firebase connection and basic operations
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Check if Firebase is initialized
      results['firebase_initialized'] = true;
      print('✓ Firebase is initialized');

      // Test 2: Check Firestore connection
      try {
        await _firestore.collection('test').limit(1).get();
        results['firestore_connection'] = true;
        print('✓ Firestore connection successful');
      } catch (e) {
        results['firestore_connection'] = false;
        results['firestore_error'] = e.toString();
        print('✗ Firestore connection failed: $e');
      }

      // Test 3: Check Auth connection
      try {
        _auth.authStateChanges();
        results['auth_connection'] = true;
        print('✓ Firebase Auth connection successful');
      } catch (e) {
        results['auth_connection'] = false;
        results['auth_error'] = e.toString();
        print('✗ Firebase Auth connection failed: $e');
      }

      // Test 4: Test write operation (if permissions allow)
      try {
        final testDoc = _firestore.collection('test').doc('connection_test');
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
          'message': 'Firebase connection test successful'
        });
        results['write_operation'] = true;
        print('✓ Write operation successful');
        
        // Clean up test document
        await testDoc.delete();
        print('✓ Test document cleaned up');
      } catch (e) {
        results['write_operation'] = false;
        results['write_error'] = e.toString();
        print('✗ Write operation failed: $e');
      }

    } catch (e) {
      results['overall_error'] = e.toString();
      print('✗ Firebase test failed: $e');
    }

    return results;
  }

  /// Test specific collections used in the app
  Future<Map<String, dynamic>> testAppCollections() async {
    final results = <String, dynamic>{};
    final collections = ['students', 'teachers', 'income', 'expenditure', 'users'];

    for (final collection in collections) {
      try {
        await _firestore.collection(collection).limit(1).get();
        results[collection] = true;
        print('✓ Collection "$collection" accessible');
      } catch (e) {
        results[collection] = false;
        results['${collection}_error'] = e.toString();
        print('✗ Collection "$collection" not accessible: $e');
      }
    }

    return results;
  }

  /// Get Firebase configuration info
  Map<String, dynamic> getFirebaseConfig() {
    return {
      'project_id': _firestore.app.options.projectId,
      'auth_domain': _firestore.app.options.authDomain,
      'storage_bucket': _firestore.app.options.storageBucket,
      'messaging_sender_id': _firestore.app.options.messagingSenderId,
    };
  }

  /// Test authentication flow
  Future<Map<String, dynamic>> testAuthentication() async {
    final results = <String, dynamic>{};
    
    try {
      // Test anonymous sign in
      final userCredential = await _auth.signInAnonymously();
      results['anonymous_signin'] = true;
      results['user_id'] = userCredential.user?.uid;
      print('✓ Anonymous sign in successful');
      
      // Test sign out
      await _auth.signOut();
      results['signout'] = true;
      print('✓ Sign out successful');
      
    } catch (e) {
      results['authentication_error'] = e.toString();
      print('✗ Authentication test failed: $e');
    }

    return results;
  }
} 