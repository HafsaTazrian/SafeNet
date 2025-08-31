// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, deprecated_member_use, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> messages = [];
  TextEditingController controller = TextEditingController();
  bool isLoading = false;
Future<void> sendMessage(String userMessage) async {
  setState(() {
    // Add the user's message 
    messages.add({'role': 'user', 'content': userMessage});
    isLoading = true; // Show loading spinner
  });

  final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

  
  final List<Map<String, String>> apiMessages = [
    {
      'role': 'system',
      'content':
          'You are a friendly, fun chatbot that talks to kids in a kind and simple way.'
    },
    // Add all previous messages from conversation history
    for (var msg in messages) {"role": msg['role']!, "content": msg['content']!},
  ];

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer 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', // Replace with your API key
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://example.com', 
      'X-Title': 'KidsBot' 
    },
    body: jsonEncode({
      "model": "moonshotai/kimi-k2:free", 
      "messages": apiMessages,
    }),
  );

  // debug prints to 
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
     final utf8Body = utf8.decode(response.bodyBytes);
  final data = jsonDecode(utf8Body);
    final reply = data['choices'][0]['message']['content'];

    setState(() {
      // Add the assistant's reply to the chat UI
      messages.add({'role': 'assistant', 'content': reply});
      isLoading = false; // Hide loading spinner
    });
  } else {
    setState(() {
      // If there's an error, show a polite fallback message
      messages.add({
        'role': 'assistant',
        'content': 'Oops! Something went wrong. Please try again.'
      });
      isLoading = false;
    });
  }

  // Clear the input field for the next user message
  controller.clear();
}



@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50], 
      appBar: AppBar(
        title: Text(
          'CurioBot – Let’s Learn Together!',
          style:GoogleFonts.playfairDisplay(
           
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            fontSize: 29,
          ),
        ),
        backgroundColor: Colors.blue.shade50,
         
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.blueGrey.withOpacity(0.6),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isUser = messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.orangeAccent.shade100 : Colors.lightBlue.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(isUser ? 24 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          offset: Offset(2, 3),
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Text(
                      messages[index]['content'] ?? '',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        color: Colors.black87,
                       
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: Colors.blue.shade50),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.6),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        sendMessage(controller.text);
                      
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}