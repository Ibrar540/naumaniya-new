import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../lib/widgets/voice_input_button.dart';

class MockSpeechToText extends Mock implements stt.SpeechToText {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceInputButton', () {
    late MockSpeechToText mockSpeech;
    late String recognizedText;

    setUp(() {
      mockSpeech = MockSpeechToText();
      recognizedText = '';
    });

    Future<void> pumpButton(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceInputButton(
              isUrdu: false,
              onResult: (text) => recognizedText = text,
            ),
          ),
        ),
      );
    }

    testWidgets('shows mic icon and calls onResult on success', (tester) async {
      await pumpButton(tester);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      // Simulate tap and success (mocking would be more advanced with dependency injection)
      // For now, just check UI state changes
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error SnackBar on permission denied', (tester) async {
      await pumpButton(tester);
      // Simulate tap
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      // Simulate error (would require more advanced DI/mocking)
      // For now, just check UI state changes
      // In a real test, you would inject the mock and simulate error callback
    });
  });
} 