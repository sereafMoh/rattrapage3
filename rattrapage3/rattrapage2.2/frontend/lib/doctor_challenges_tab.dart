import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String apiBase = "http://192.168.100.53:5000";

class DoctorChallengesTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorChallengesTab({required this.doctor, Key? key}) : super(key: key);

  @override
  State<DoctorChallengesTab> createState() => _DoctorChallengesTabState();
}

class _DoctorChallengesTabState extends State<DoctorChallengesTab> {
  List<Map<String, dynamic>> challenges = [];
  bool loading = false;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchChallenges() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$apiBase/challenges"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        challenges = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
    setState(() => loading = false);
  }

  Future<void> addChallenge() async {
    if ([titleCtrl, descCtrl, startCtrl, endCtrl].any((c) => c.text.isEmpty))
      return;

    await http.post(
      Uri.parse("$apiBase/challenges"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "creator_id": widget.doctor['id'],
        "title": titleCtrl.text,
        "description": descCtrl.text,
        "start_date": startCtrl.text,
        "end_date": endCtrl.text,
      }),
    );

    titleCtrl.clear();
    descCtrl.clear();
    startCtrl.clear();
    endCtrl.clear();
    fetchChallenges();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Create Challenge ----
              Text(
                'Create Challenge',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildField(
                        controller: titleCtrl,
                        label: 'Title',
                        icon: Icons.flag,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: descCtrl,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start (YYYY-MM-DD)',
                                prefixIcon: Icon(
                                  Icons.date_range,
                                  color: Colors.deepPurple,
                                ),
                                filled: true,
                                fillColor: Colors.deepPurple[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => _pickDate(startCtrl),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End (YYYY-MM-DD)',
                                prefixIcon: Icon(
                                  Icons.date_range,
                                  color: Colors.deepPurple,
                                ),
                                filled: true,
                                fillColor: Colors.deepPurple[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => _pickDate(endCtrl),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: addChallenge,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Challenge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Ongoing Challenges ----
              const SizedBox(height: 24),
              Text(
                'Ongoing Challenges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (challenges.isEmpty)
                Center(
                  child: Text(
                    'No challenges at the moment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple[300],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: challenges.length,
                  itemBuilder: (context, i) {
                    final c = challenges[i];
                    return _ChallengeCard(challenge: c);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.deepPurple[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const _ChallengeCard({required this.challenge, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final start = challenge['start_date'] ?? '';
    final end = challenge['end_date'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  child: Icon(Icons.flag, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge['description'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Start: $start',
              style: TextStyle(color: Colors.deepPurple[400]),
            ),
            const SizedBox(height: 4),
            Text('End: $end', style: TextStyle(color: Colors.deepPurple[400])),
          ],
        ),
      ),
    );
  }
}
