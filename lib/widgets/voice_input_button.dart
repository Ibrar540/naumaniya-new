import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class VoiceInputButton extends StatefulWidget {
  final bool isUrdu;
  final ValueChanged<String> onResult;
  final double? size;

  const VoiceInputButton({
    Key? key, 
    required this.isUrdu, 
    required this.onResult,
    this.size,
  }) : super(key: key);

  @override
  _VoiceInputButtonState createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String? _errorMessage;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<bool> _isOffline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity == ConnectivityResult.none;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isListening = false;
      _isInitializing = false;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _listen() async {
    if (!_isListening && !_isInitializing) {
      setState(() { _isInitializing = true; });
      bool available = false;
      try {
        available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (error) {
            _showError(error.errorMsg ?? 'Speech recognition error');
          },
        );
      } catch (e) {
        _showError('Failed to initialize speech recognition: $e');
      }
      setState(() { _isInitializing = false; });
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: widget.isUrdu ? 'ur-PK' : 'en-US',
          onResult: (result) {
            if (result.finalResult) {
              widget.onResult(result.recognizedWords);
              setState(() => _isListening = false);
              _speech.stop();
            }
          },
        );
      } else {
        if (await _isOffline()) {
          String platformInstructions = '';
          if (Platform.isAndroid) {
            platformInstructions = 'To use voice input offline, download the offline speech recognition language pack:\nSettings > System > Languages & input > Virtual keyboard > Google voice typing > Offline speech recognition.';
          } else if (Platform.isIOS) {
            platformInstructions = 'To use voice input offline, ensure your device is updated and the language is supported for offline recognition.';
          }
          _showError('Offline voice input is not available. $platformInstructions');
        } else {
          _showError('Speech recognition unavailable or permission denied.');
        }
      }
    } else if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: _isInitializing
              ? SizedBox(width: widget.size ?? 24, height: widget.size ?? 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_isListening ? Icons.mic : Icons.mic_none, color: _errorMessage != null ? Colors.red : Colors.blue),
          onPressed: _isInitializing ? null : _listen,
          tooltip: widget.isUrdu ? 'آواز سے لکھیں' : 'Voice Input',
          iconSize: widget.size ?? 24,
        ),
      ],
    );
  }
} 