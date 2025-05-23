import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://192.168.100.53:5000";

class DoctorFaqTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorFaqTab({required this.doctor});

  @override
  State<DoctorFaqTab> createState() => _DoctorFaqTabState();
}

class _DoctorFaqTabState extends State<DoctorFaqTab> {
  List<Map<String, dynamic>> faqs = [];
  bool loading = false;
  final Map<int, TextEditingController> answerControllers = {};

  @override
  void initState() {
    super.initState();
    fetchFaqs();
  }

  @override
  void dispose() {
    answerControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void fetchFaqs() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$apiBase/faqs"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => faqs = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loading = false);
  }

  void answerFaq(int faqId) async {
    final ctrl = answerControllers[faqId];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;
    await http.post(
      Uri.parse("$apiBase/faqs/answer/$faqId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"answer": ctrl.text, "doctor_id": widget.doctor['id']}),
    );
    ctrl.clear();
    fetchFaqs();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: EdgeInsets.all(18),
        child:
            loading
                ? Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FAQs",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.deepPurple[900],
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemCount: faqs.length,
                        itemBuilder: (context, idx) {
                          final f = faqs[idx];
                          answerControllers.putIfAbsent(
                            f['id'],
                            () => TextEditingController(),
                          );
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['question'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.deepPurple[900],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  if (f['answer'] != null)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        "A: ${f['answer']}\nBy: ${f['doctor_name'] ?? ''}",
                                        style: TextStyle(
                                          color: Colors.deepPurple[800],
                                          fontSize: 15,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "No answer yet.",
                                          style: TextStyle(
                                            color: Colors.deepPurple[300],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        TextField(
                                          controller:
                                              answerControllers[f['id']],
                                          decoration: InputDecoration(
                                            labelText: "Your Answer",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            fillColor: Colors.deepPurple[50],
                                            filled: true,
                                          ),
                                          minLines: 1,
                                          maxLines: 2,
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => answerFaq(f['id']),
                                          icon: Icon(Icons.send),
                                          label: Text("Submit Answer"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepPurple,
                                            foregroundColor: Colors.white,
                                            shape: StadiumBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
