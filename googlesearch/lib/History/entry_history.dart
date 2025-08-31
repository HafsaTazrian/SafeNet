// ignore_for_file: prefer_const_constructors, avoid_web_libraries_in_flutter, deprecated_member_use, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/History/history_page.dart';
import 'package:googlesearch/History/kids_history_page.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart';

class EntryHistory extends StatefulWidget {
  const EntryHistory({super.key});

  @override
  State<EntryHistory> createState() => _EntryHistoryState();
}

class _EntryHistoryState extends State<EntryHistory> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _speechEnabled = false;
  String _status = '';
  String _ageCategory = '';
  String _predictedAgeText = '';


  html.MediaRecorder? _recorder;
  html.MediaStream? _mediaStream;
  final List<html.Blob> _audioChunks = [];
  Timer? _silenceTimer;
  Timer? _maxRecordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeRecorder();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initializeRecorder() async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (_mediaStream != null) {
        _recorder = html.MediaRecorder(_mediaStream!);

        _recorder!.addEventListener('dataavailable', (event) {
          if (event is html.BlobEvent && event.data != null) {
            _audioChunks.add(event.data!);
            _resetSilenceTimer();
          }
        });

        _recorder!.addEventListener('stop', (_) {
          _cancelTimers();
          _processAudioChunks();
        });

        setState(() => _status = 'Recorder initialized');
      }
    } catch (e) {
      setState(() => _status = 'Error initializing recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    _audioChunks.clear();
    setState(() {
      _isRecording = true;
      _status = 'Recording...';
    });

    _maxRecordingTimer = Timer(const Duration(seconds: 30), () {
      if (_isRecording) _stopRecording();
    });

    try {
      _recorder?.start(100);
      _resetSilenceTimer();
    } catch (e) {
      setState(() {
        _status = 'Error starting recorder: $e';
        _isRecording = false;
      });
      _cancelTimers();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isProcessing) return;

    setState(() {
      _isRecording = false;
      _isListening = false;
      _status = 'Stopping recording...';
    });

    _cancelTimers();

    try {
      _recorder?.stop();
      _speech.stop();
    } catch (e) {
      setState(() => _status = 'Error stopping: $e');
      _isProcessing = false;
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 1), () {
      if (_isRecording) _stopRecording();
    });
  }

  void _cancelTimers() {
    _silenceTimer?.cancel();
    _maxRecordingTimer?.cancel();
  }

  Future<void> _processAudioChunks() async {
    if (_audioChunks.isEmpty) return;

    final blob = html.Blob(_audioChunks, 'audio/webm');
    await _predictAgeFromVoice(blob);
  }

  Future<void> _predictAgeFromVoice(html.Blob audioBlob) async {
    try {
      setState(() {
        _status = 'Sending audio to server...';
        _isProcessing = true;
      });

      final formData = html.FormData();
      final file = html.File([audioBlob], 'audio.webm', {'type': 'audio/webm'});
      formData.appendBlob('file', file);

      final request = html.HttpRequest();
      request.open('POST', 'http://127.0.0.1:5001/predict_age');

      final completer = Completer<void>();

      request.onLoad.listen((_) {
        if (request.status == 200) {
          try {
            final result = json.decode(request.responseText!);
           _ageCategory = result['predicted_age_category'];
_predictedAgeText = 'Detected age group: $_ageCategory';
_status = 'Detected successfully. Redirecting shortly...';

setState(() {}); // Update the UI to show the age

// Wait for 2 seconds before navigating
Future.delayed(Duration(seconds: 4), () {
  _navigateBasedOnAge();
});

          } catch (e) {
            setState(() => _status = 'Error parsing response');
          }
        } else {
          setState(() => _status = 'Server error: ${request.status}');
        }
        _isProcessing = false;
        completer.complete();
      });

      request.onError.listen((_) {
        setState(() {
          _status = 'Network error';
          _isProcessing = false;
        });
        completer.complete();
      });

      request.send(formData);
      await completer.future;
    } catch (e) {
      setState(() {
        _status = 'Error sending audio: $e';
        _isProcessing = false;
      });
    }
  }

 void _navigateBasedOnAge() {
  final age = _ageCategory.trim().toLowerCase();

  print('Navigating based on age: $age'); 

  if (age == 'fifties' || age == 'twenties') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => KidsHistoryPage()));
  } else {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage()));
  }
}

  void _handleMicClick() async {
    if (_isProcessing) return;

    if (_isRecording || _isListening) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.blue.shade300,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context); // Or pushReplacement to SearchScreen
        },
      ),
      title: Center(
        child: Text(
          'Who’s Speaking?',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none
          ),
        ),
      ),
    ),
    backgroundColor: Color(0xFFFFF8F0), // Soft warm peach tone
    body: Center(
      child: Container(
        width: 600,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/Lovely cats.json', height: 350),
            SizedBox(height: 20),
            Text(
              'Look at this animal! Can you tell its name?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Click the mic and say it out loud.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                decoration: TextDecoration.none,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 20),
            IconButton(
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 36,
                color: _isRecording ? Colors.red : Colors.black,
              ),
              onPressed: _handleMicClick,
            ),
            if (_predictedAgeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _predictedAgeText,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _status,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}




}