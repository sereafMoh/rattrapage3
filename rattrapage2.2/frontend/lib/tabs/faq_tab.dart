import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../patient_home.dart';

class FAQTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const FAQTab({required this.user});
  @override
  State<FAQTab> createState() => _FAQTabState();
}

class _FAQTabState extends State<FAQTab> {
  List<Map<String, dynamic>> faqs = [];
  List<Map<String, dynamic>> filteredFaqs = [];
  bool loadingFaqs = false;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    fetchFaqs();
  }

  void fetchFaqs() async {
    setState(() => loadingFaqs = true);
    final res = await http.get(Uri.parse("$apiBase/faqs"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        faqs = list;
        filteredFaqs = list;
      });
    }
    setState(() => loadingFaqs = false);
  }

  void filterFaqs(String query) {
    setState(() {
      searchText = query;
      filteredFaqs = faqs
          .where((f) =>
              (f['question'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (f['answer'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(18),
      child: loadingFaqs
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.blue[900]),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onChanged: filterFaqs,
                ),
                SizedBox(height: 18),
                Expanded(
                  child: filteredFaqs.isEmpty
                      ? Center(
                          child: Text(
                            "No FAQs found.",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredFaqs.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final f = filteredFaqs[idx];
                            return FAQCard(faq: f);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class FAQCard extends StatefulWidget {
  final Map<String, dynamic> faq;
  const FAQCard({required this.faq});

  @override
  State<FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<FAQCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (expanded)
            BoxShadow(
              color: Colors.blue[100]!.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue[700]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.faq['question'] ?? "",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[900]),
              ),
            ),
          ],
        ),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
        backgroundColor: Colors.blue[50],
        onExpansionChanged: (v) => setState(() => expanded = v),
        trailing: Icon(
          expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.blue[600],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.faq['answer'] ?? "",
              style: TextStyle(
                  fontSize: 15, color: Colors.grey[800], height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
