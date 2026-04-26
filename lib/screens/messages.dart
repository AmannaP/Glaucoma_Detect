import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class MessagesScreen extends StatefulWidget {
  final String doctorName;
  const MessagesScreen({super.key, required this.doctorName});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id');
    
    if (_currentUserId != null) {
      await _fetchMessages();
      // Poll every 3 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchMessages(autoScroll: false);
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool autoScroll = true}) async {
    if (_currentUserId == null) return;
    
    try {
      final url = Uri.parse(
          'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=fetch&user_id=$_currentUserId&other_name=${Uri.encodeComponent(widget.doctorName)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> newMessages = data['messages'] ?? [];
          if (mounted) {
            setState(() {
              _messages = newMessages;
              _isLoading = false;
            });
            if (autoScroll && newMessages.isNotEmpty) {
              _scrollToBottom();
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    String userText = _controller.text.trim();
    if (userText.isEmpty || _currentUserId == null) return;

    _controller.clear();
    
    // Optimistic UI update
    setState(() {
      _messages.add({
        "sender_id": _currentUserId,
        "message": userText,
        "sender_name": "Me", // Temporary until next poll
      });
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=send'),
        body: json.encode({
          "sender_id": _currentUserId,
          "receiver_name": widget.doctorName,
          "message": userText,
        }),
      );
      
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _fetchMessages(); // Immediately sync to get correct timestamps/IDs
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.doctorName),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // Check if current user is the sender
                final isUser = (msg["sender_id"] != null && msg["sender_id"] == _currentUserId) || msg["sender_name"] == "Me";
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF006400) : const Color(0xFF131C24),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg["message"] ?? "",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: const BoxDecoration(
                color: Color(0xFF131C24),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
