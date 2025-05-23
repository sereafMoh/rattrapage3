import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://192.168.100.53:5000";

class DoctorChatTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Map<String, dynamic>? selectedPatient;
  final VoidCallback? onChatClosed;

  const DoctorChatTab({
    required this.doctor,
    required this.selectedPatient,
    this.onChatClosed,
  });

  @override
  State<DoctorChatTab> createState() => _DoctorChatTabState();
}

class _DoctorChatTabState extends State<DoctorChatTab> {
  List<Map<String, dynamic>> messages = [];
  final chatCtrl = TextEditingController();
  bool loadingMessages = false;

  @override
  void didUpdateWidget(covariant DoctorChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected patient changes, reload chat
    if (widget.selectedPatient != oldWidget.selectedPatient) {
      fetchMessages();
    }
  }

  @override
  void dispose() {
    chatCtrl.dispose();
    super.dispose();
  }

  void fetchMessages() async {
    if (widget.selectedPatient == null) return;
    setState(() => loadingMessages = true);
    final res = await http.get(
      Uri.parse(
        "$apiBase/messages/${widget.doctor['id']}/${widget.selectedPatient!['id']}",
      ),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => messages = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loadingMessages = false);
  }

  void sendMessage() async {
    if (chatCtrl.text.isEmpty || widget.selectedPatient == null) return;
    await http.post(
      Uri.parse("$apiBase/messages"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "sender_id": widget.doctor['id'],
        "receiver_id": widget.selectedPatient!['id'],
        "message": chatCtrl.text,
      }),
    );
    chatCtrl.clear();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedPatient == null) {
      return Container(
        color: Colors.deepPurple[50],
        child: Center(
          child: Text(
            "Select a patient from Patients tab to chat.",
            style: TextStyle(
              color: Colors.deepPurple[200],
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.deepPurple[100],
                  child: Icon(Icons.person, color: Colors.deepPurple[600]),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Chat with ${widget.selectedPatient!['name']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                ),
                if (widget.onChatClosed != null)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.deepPurple),
                    tooltip: "Close chat",
                    onPressed: widget.onChatClosed,
                  ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child:
                  loadingMessages
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, idx) {
                          final m = messages[messages.length - 1 - idx];
                          final isMe = m['sender_id'] == widget.doctor['id'];
                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: 6,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? Colors.deepPurple[100]
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.06),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                m['message'],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.deepPurple[900],
                                  fontWeight:
                                      isMe ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatCtrl,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                  ),
                  child: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
