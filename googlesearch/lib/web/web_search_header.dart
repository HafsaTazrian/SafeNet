// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:googlesearch/Screens/search_screen.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class WebSearchHeader extends StatefulWidget {
  final String searchQuery;

  const WebSearchHeader({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  State<WebSearchHeader> createState() => _WebSearchHeaderState();
}

class _WebSearchHeaderState extends State<WebSearchHeader> {
  late TextEditingController searchController;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isRecording = false;
  String _ageCategory = '';
  String _status = '';
  html.MediaRecorder? _recorder;
  html.MediaStream? _mediaStream;
  final List<html.Blob> _audioChunks = [];
  bool _isProcessing = false;
  Timer? _silenceTimer;
  Timer? _maxRecordingTimer;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.searchQuery);
    _speech = stt.SpeechToText();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true,
      });
      if (_mediaStream != null) {
        _recorder = html.MediaRecorder(_mediaStream!);
        _recorder!.addEventListener('dataavailable', (event) {
          print('Data available event received');
          if (event is html.BlobEvent && event.data != null) {
            _audioChunks.add(event.data!);
            print('Audio chunk received: ${event.data!.size} bytes');

            // Reset silence timer when audio data is received
            if (mounted) {
              _resetSilenceTimer();
            }
          }
        });

        _recorder!.addEventListener('stop', (event) {
          print('Recorder stopped, processing chunks...');
          _cancelTimers();
          _processAudioChunks();
        });
        if (mounted) {
          setState(() {
            _status = 'Recorder initialized';
          });
        }
        print('Recorder initialized successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error initializing recorder: $e';
        });
      }
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _processAudioChunks() async {
    if (_audioChunks.isEmpty) {
      print('No audio chunks to process');
      return;
    }

    print('Processing ${_audioChunks.length} audio chunks');
    final blob = html.Blob(_audioChunks, 'audio/webm');
    print('Created blob of size: ${blob.size} bytes');

    await _predictAgeFromVoice(blob);
  }

  Future<void> _startRecording() async {
    _audioChunks.clear();
    print('=== Voice Recording Debug ===');
    print('1. Clearing previous audio chunks');
    if (mounted) {
      setState(() {
        _status = 'Started recording';
        _isRecording = true;
      });
    }

    // Set maximum recording duration of 30 seconds
    _maxRecordingTimer = Timer(const Duration(seconds: 30), () {
      print('Maximum recording time reached, stopping');
      if (_isRecording) {
        _stopRecording();
      }
    });

    print('2. Starting recording with recorder state: ${_recorder?.state}');
    try {
      _recorder?.start(
          100); // Record in smaller chunks (100ms) for better silence detection
      print('3. Recording started successfully');

      // Start silence timer
      _resetSilenceTimer();
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        setState(() {
          _status = 'Error starting recording: $e';
          _isRecording = false;
        });
      }
      _cancelTimers();
    }
  }

  Future<void> _stopRecording() async {
    if (_isProcessing || !_isRecording) {
      print('Already processing or not recording, skipping stop recording');
      return;
    }
    _isProcessing = true;
    print('=== Stop Recording Debug ===');
    print('1. Stopping recording');
    if (mounted) {
      setState(() {
        _status = 'Stopping recording...';
        _isRecording = false;
        _isListening = false;
      });
    }

    // Cancel timers
    _cancelTimers();

    try {
      print('2. Current recorder state: ${_recorder?.state}');
      print('3. Number of audio chunks collected: ${_audioChunks.length}');
      _recorder?.stop();
      _speech.stop(); // Also stop speech recognition
      print('4. Recording stopped successfully');
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        setState(() {
          _status = 'Error stopping recording: $e';
        });
      }
      _isProcessing = false;
    }
  }

  Future<void> _predictAgeFromVoice(html.Blob audioBlob) async {
    try {
      print('=== Age Prediction Debug ===');
      print('1. Starting age prediction process');
      print('2. Audio blob size: ${audioBlob.size} bytes');

      if (mounted) {
        setState(() {
          _status = 'Sending audio to server...';
        });
      }

      // Create a FormData object
      final formData = html.FormData();

      // Create a File from the Blob with a proper name
      final file = html.File([audioBlob], 'audio.webm', {'type': 'audio/webm'});
      formData.appendBlob('file', file);

      print('3. FormData created with file size: ${file.size} bytes');
      print('4. Sending request to http://127.0.0.1:5001/predict_age');

      // Create and configure the request
      final request = html.HttpRequest();
      request.open('POST', 'http://127.0.0.1:5001/predict_age');

      final completer = Completer<void>();

      // Set up response handler
      request.onLoad.listen((e) {
        print('5. Received response from server');
        print('6. Response status: ${request.status}');
        print('7. Response text: ${request.responseText}');

        if (request.status == 200) {
          try {
            final result = json.decode(request.responseText!);
            print('8. Parsed response: $result');
            if (mounted) {
              setState(() {
                _ageCategory = result['predicted_age_category'];
                _status = 'Age predicted: $_ageCategory';
              });
            }
          } catch (e) {
            print('Error parsing response: $e');
            if (mounted) {
              setState(() {
                _status = 'Error parsing server response';
              });
            }
          }
        } else {
          print('Server returned error status: ${request.status}');
          if (mounted) {
            setState(() {
              _status = 'Server error: ${request.status}';
            });
          }
        }
        _isProcessing = false;
        completer.complete();
      });

      // Set up error handler
      request.onError.listen((e) {
        print('Error during request: $e');
        print('Request readyState: ${request.readyState}');
        print('Request status: ${request.status}');
        if (mounted) {
          setState(() {
            _status = 'Network error: $e';
            _isProcessing = false;
          });
        } else {
          _isProcessing = false;
        }
        completer.complete();
      });

      // Send the request
      request.send(formData);
      print('9. Request sent, waiting for response...');
      await completer.future;
    } catch (e) {
      print('Error in _predictAgeFromVoice: $e');
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  //for saving the history 
  void _saveQueryToHistory(String query, String ageCategory) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    final box = await Hive.openBox('history_${user.id}');
    await box.add({
      'query': query,
      'ageCategory': ageCategory.isNotEmpty ? ageCategory : 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}


 void _navigateToSearch() {
  if (_isProcessing) return;
  final query = searchController.text.trim();
  if (query.isNotEmpty) {
    _saveQueryToHistory(query, _ageCategory); // ✅ Save to history
    print('Navigating to search with query: $query and age: $_ageCategory');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          searchQuery: query,
          ageCategory: _ageCategory,
        ),
      ),
    );
  }
}


  void _handleMicClick() async {
    if (_isProcessing) return;

    if (_isRecording || _isListening) {
      // Currently recording or listening, so stop
      await _stopRecording();

      // Wait a bit before navigating to ensure audio processing is complete
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isProcessing) {
          _navigateToSearch();
        }
      });
    } else {
      // Not recording, so start
      _startListening();
    }
  }

  void _startListening() async {
    if (_isProcessing) return;

    // Start recording audio for age prediction
    await _startRecording();

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == "notListening") {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }

          // Only auto-stop if we haven't already stopped manually
          if (_isRecording) {
            _stopRecording().then((_) {
              // Wait a bit before navigating to ensure audio processing is complete
              Future.delayed(const Duration(seconds: 1), () {
                if (!_isProcessing && mounted) {
                  _navigateToSearch();
                }
              });
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _isRecording = false;
            _status = 'Speech recognition error: $error';
            _isProcessing = false;
          });
        } else {
          _isListening = false;
          _isRecording = false;
          _isProcessing = false;
        }
        _cancelTimers();
        print("Speech recognition error: $error");
      },
    );
    if (available) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _status = 'Listening...';
        });
      }

      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              searchController.text = result.recognizedWords;
              print("Recognized Words: ${result.recognizedWords}");
            });
          }
        },
        listenFor: const Duration(seconds: 10), // Increased listen duration
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      );
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 1), () {
      print('Silence detected for 1 second, stopping recording');
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _cancelTimers() {
    _silenceTimer?.cancel();
    _maxRecordingTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

   return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(top: 25.0, left: 137.0),
      child: Row(
        children: [
Container(
  width: size.width * 0.45,
  height: 48,
  decoration: BoxDecoration(
     color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(30),
    


   
  ),
  alignment: Alignment.center,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextFormField(
      controller: searchController,
      style: GoogleFonts.playfairDisplay(fontSize: 16, color: Theme.of(context).colorScheme.onSurface,),
      textAlignVertical: TextAlignVertical.center,
      onFieldSubmitted: (_) => _navigateToSearch(),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _isProcessing ? null : _handleMicClick,
              icon: Icon(
                Icons.mic,
                color: _isRecording || _isListening
                    ? Colors.red
                    : (_isProcessing ? Colors.grey : Theme.of(context).iconTheme.color),
              ),
            ),
            IconButton(
              onPressed: _navigateToSearch,
              icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ),
  ),
),

        ],
      ),
    ),
    const SizedBox(height: 6),
    Padding(
      padding: EdgeInsets.only(
        left: size.width <= 768 ? 27 : 150.0,
        top: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _status,
            style: TextStyle(
              fontSize: 14,
             color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (_isRecording || _isListening)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                '(Click mic to stop)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  ],
);

  }
}
