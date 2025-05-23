import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../patient_home.dart';
import '../article_view_page.dart';

class ArticlesTab extends StatefulWidget {
  @override
  State<ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<ArticlesTab> {
  List<Map<String, dynamic>> articles = [];
  bool loadingArticles = false;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  void fetchArticles() async {
    setState(() => loadingArticles = true);
    final res = await http.get(Uri.parse("$apiBase/articles"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          articles = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingArticles = false);
  }

  void openArticle(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleViewPage(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(18),
      child: loadingArticles
          ? Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? Center(
                  child: Text("No articles found.",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])))
              : ListView.separated(
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => SizedBox(height: 18),
                  itemBuilder: (context, idx) {
                    final a = articles[idx];
                    return ArticleCard(
                      article: a,
                      onTap: () => openArticle(a),
                    );
                  },
                ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  const ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.article, color: Colors.blue[700]),
                radius: 28,
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.blue[900]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      article['doctor_name'] != null
                          ? "By ${article['doctor_name']}"
                          : "",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      article['timestamp'] != null ? article['timestamp'] : "",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.arrow_forward_ios, color: Colors.blue[300], size: 22)
            ],
          ),
        ),
      ),
    );
  }
}
