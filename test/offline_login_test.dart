import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/screens/login_screen.dart';
import '../lib/services/offline_auth_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Login Flow', () {
    late MockConnectivity mockConnectivity;

    setUp(() async {
      mockConnectivity = MockConnectivity();
      SharedPreferences.setMockInitialValues({});
      await OfflineAuthService.clearCredentials();
    });

    testWidgets('Online login caches credentials, offline login succeeds and fails', (tester) async {
      // Simulate online login
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Simulate offline login (correct credentials)
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Logged in offline'), findsOneWidget);

      // Simulate offline login (wrong credentials)
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline login failed'), findsOneWidget);
    });
  });
} 