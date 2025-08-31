// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:googlesearch/Color/colors.dart';
import 'package:googlesearch/Screens/search_screen.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // Controller for the text search input
  final TextEditingController searchController = TextEditingController();

  // Speech-to-text instance
  final SpeechToText _speech = SpeechToText();

  // Various state flags
  bool _isListening = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _speechEnabled = false;
  String _status = '';            // For showing status updates
  String _ageCategory = '';       // Age group predicted from voice

  // HTML-specific media recorder and audio tracking
  html.MediaRecorder? _recorder;
  html.MediaStream? _mediaStream;
  final List<html.Blob> _audioChunks = [];

  // Timers to auto-stop recording
  Timer? _silenceTimer;
  Timer? _maxRecordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();   // Setup for speech-to-text
    _initializeRecorder(); // Setup for browser audio recording
  }

  // Initializes speech-to-text engine
  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  // Initializes browser media recorder for voice capture
  Future<void> _initializeRecorder() async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (_mediaStream != null) {
        _recorder = html.MediaRecorder(_mediaStream!);

        // Listen to audio data chunks
        _recorder!.addEventListener('dataavailable', (event) {
          if (event is html.BlobEvent && event.data != null) {
            _audioChunks.add(event.data!);
            _resetSilenceTimer();
          }
        });

        // Process after stopping
        _recorder!.addEventListener('stop', (_) {
          _cancelTimers();
          _processAudioChunks();
        });

        setState(() {
          _status = 'Recorder initialized';
        });
      }
    } catch (e) {
      setState(() => _status = 'Error initializing recorder: $e');
    }
  }

  // Starts audio recording
  Future<void> _startRecording() async {
    _audioChunks.clear();
    setState(() {
      _isRecording = true;
      _status = 'Recording...';
    });

    // Force stop after 30 seconds
    _maxRecordingTimer = Timer(const Duration(seconds: 30), () {
      if (_isRecording) _stopRecording();
    });

    try {
      _recorder?.start(100); // Records in 100ms chunks
      _resetSilenceTimer();  // Reset silence timeout
    } catch (e) {
      setState(() {
        _status = 'Error starting recorder: $e';
        _isRecording = false;
      });
      _cancelTimers();
    }
  }

  // Stops recording and speech detection
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

  // Timer to detect silence — stops if quiet for 1 second
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 1), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  // Cancel all active timers
  void _cancelTimers() {
    _silenceTimer?.cancel();
    _maxRecordingTimer?.cancel();
  }

  // Handles received audio chunks after recording stops
  Future<void> _processAudioChunks() async {
    if (_audioChunks.isEmpty) return;

    final blob = html.Blob(_audioChunks, 'audio/webm');
    await _predictAgeFromVoice(blob); // Send blob to backend for prediction
  }

  // Sends audio to backend server and receives age prediction
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

      // When server responds with result
      request.onLoad.listen((_) {
        if (request.status == 200) {
          try {
            final result = json.decode(request.responseText!);
            setState(() {
              _ageCategory = result['predicted_age_category'];
              _status = 'Age predicted: $_ageCategory';
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

      // Handle errors from server
      request.onError.listen((e) {
        setState(() {
          _status = 'Network error';
          _isProcessing = false;
        });
        completer.complete();
      });

      request.send(formData);
      await completer.future;

      _navigateToSearch(); // Go to search screen after prediction
    } catch (e) {
      setState(() {
        _status = 'Error sending audio: $e';
        _isProcessing = false;
      });
    }
  }

  // Begins voice input process
  void _startListening() async {
    if (_isProcessing || !_speechEnabled) return;     //done

    await _startRecording();

    // Initialize speech engine and listen
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "notListening" && _isRecording) {
          _stopRecording();
        }
      },
      onError: (error) {
        setState(() {
          _status = 'Speech error: $error';
          _isListening = false;
          _isRecording = false;
          _isProcessing = false;
        });
        _cancelTimers();
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _status = 'Listening...';
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            searchController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      );
    }
  }

  // Called when microphone icon is tapped
  void _handleMicClick() async {
    if (_isProcessing) return;

    if (_isRecording || _isListening) {
      await _stopRecording();
    } else {
      _startListening();
    }
  }

  // Navigates to search results screen
  void _navigateToSearch() {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      _saveQueryToHistory(query, _ageCategory); // Save query for history
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            start: '0',       // start page 
            searchQuery: query,
            ageCategory: _ageCategory,
          ),
        ),
      );
    }
  }

  // Saves search query, age group, and timestamp to Hive box (local database)
  void _saveQueryToHistory(String query, String ageCategory) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final box = await Hive.openBox('history_${user.id}');
      await box.add({
        'query': query,
        'ageCategory': ageCategory,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Stops media streams and timers when widget is destroyed
  @override
  void dispose() {
    _cancelTimers();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicBorderColor = isDark ? Colors.white54 : searchBorder;
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Animated app title
        Center(
          child: SizedBox(
            height: 50,
            child: AnimatedTextKit(
              repeatForever: true,
              animatedTexts: [
                ScaleAnimatedText(
                  'SafeNet',
                  textStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Search input field
        SizedBox(
          width: size.width > 768 ? size.width * 0.4 : size.width * 0.9,
          child: TextFormField(
            controller: searchController,
            onFieldSubmitted: (_) => _navigateToSearch(),
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.grey[900] : Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: dynamicBorderColor),
                borderRadius: const BorderRadius.all(Radius.circular(30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dynamicBorderColor),
                borderRadius: const BorderRadius.all(Radius.circular(30)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(30)),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  'assets/images/search-icon.svg',
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              suffixIcon: GestureDetector(
                onTap: _handleMicClick,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    _isRecording || _isListening ? Icons.mic : Icons.mic_none,
                    key: ValueKey(_isRecording || _isListening),
                    color: _isRecording || _isListening
                        ? Colors.red
                        : isDark
                            ? Colors.white54
                            : searchBorder,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Optional status display
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
