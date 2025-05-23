import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../patient_home.dart';

class ChatTab extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? myDoctor;
  const ChatTab({required this.user, required this.myDoctor});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<Map<String, dynamic>> messages = [];
  final chatCtrl = TextEditingController();
  bool loadingMessages = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    chatCtrl.dispose();
    super.dispose();
  }

  void fetchMessages() async {
    if (widget.myDoctor == null) return;
    setState(() => loadingMessages = true);
    final res = await http.get(Uri.parse(
        "$apiBase/messages/${widget.user['id']}/${widget.myDoctor!['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          messages = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingMessages = false);
  }

  void sendMessage() async {
    if (chatCtrl.text.isEmpty || widget.myDoctor == null) return;
    await http.post(Uri.parse("$apiBase/messages"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "sender_id": widget.user['id'],
          "receiver_id": widget.myDoctor!['id'],
          "message": chatCtrl.text,
        }));
    chatCtrl.clear();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myDoctor == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "No doctor assigned. Assign one first to chat.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, color: Colors.blue[800]),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Chat with Dr. ${widget.myDoctor!['name']}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue[900]),
                ),
              ),
              Icon(Icons.chat_bubble, color: Colors.blue[400])
            ],
          ),
        ),
        Expanded(
          child: loadingMessages
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[messages.length - 1 - i];
                      final isMe = m['sender_id'] == widget.user['id'];
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft: isMe
                                  ? Radius.circular(18)
                                  : Radius.circular(2),
                              bottomRight: isMe
                                  ? Radius.circular(2)
                                  : Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            m['message'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        SafeArea(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (val) => sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  elevation: 1,
                  mini: true,
                  backgroundColor: Colors.blueAccent,
                  onPressed: sendMessage,
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                  heroTag: "sendBtn",
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
