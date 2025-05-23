import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://192.168.1.35:5000";

class DoctorArticlesTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const DoctorArticlesTab({required this.user});

  @override
  State<DoctorArticlesTab> createState() => _DoctorArticlesTabState();
}

class _DoctorArticlesTabState extends State<DoctorArticlesTab> {
  List<Map<String, dynamic>> articles = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$apiBase/articles"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        // Map JSON fields to include doctor name and timestamp
        articles =
            List<Map<String, dynamic>>.from(jsonDecode(res.body)).map((a) {
              return {
                ...a,
                // Ensure these fields exist in your API response or adjust accordingly
                'doctor_name': a['doctor_name'] ?? a['doctor']?['name'] ?? '',
                'timestamp': a['timestamp'] ?? a['created_at'] ?? '',
              };
            }).toList();
      });
    }
    setState(() => loading = false);
  }

  void openWritePage([Map<String, dynamic>? article]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WriteEditArticlePage(user: widget.user, article: article),
      ),
    );
    fetchArticles();
  }

  void openArticleViewPage(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleViewPage(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text("Write Article"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () => openWritePage(),
      ),
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : ListView.separated(
                padding: EdgeInsets.all(16),
                separatorBuilder: (_, __) => Divider(),
                itemCount: articles.length,
                itemBuilder: (context, idx) {
                  final a = articles[idx];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 2,
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      onTap: () => openArticleViewPage(a),
                      title: Text(
                        a['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "By: ${a['doctor_name']}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if ((a['timestamp'] ?? '').isNotEmpty)
                            Text(
                              "Posted: ${a['timestamp']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing:
                          (a['doctor_id'] == widget.user['id'])
                              ? IconButton(
                                icon: Icon(Icons.edit, color: Colors.purple),
                                onPressed: () => openWritePage(a),
                                tooltip: "Edit Article",
                              )
                              : null,
                    ),
                  );
                },
              ),
    );
  }
}

class ArticleViewPage extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleViewPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text(article['title'] ?? ''),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Colors.deepPurple[900],
                  ),
                ),
                SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "By: ${article['doctor_name']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((article['timestamp'] ?? '').isNotEmpty)
                      Text(
                        "${article['timestamp']}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple[200],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 18),
                Divider(),
                SizedBox(height: 12),
                Text(
                  article['content'] ?? '',
                  style: TextStyle(fontSize: 17, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WriteEditArticlePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? article;
  const WriteEditArticlePage({required this.user, this.article});

  @override
  State<WriteEditArticlePage> createState() => _WriteEditArticlePageState();
}

class _WriteEditArticlePageState extends State<WriteEditArticlePage> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      titleCtrl.text = widget.article!['title'] ?? '';
      contentCtrl.text = widget.article!['content'] ?? '';
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  Future<void> saveArticle() async {
    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty)
      return;
    setState(() => saving = true);
    final body = {
      'doctor_id': widget.user['id'],
      'title': titleCtrl.text,
      'content': contentCtrl.text,
    };
    if (widget.article != null) {
      // Edit existing
      await http.put(
        Uri.parse("$apiBase/articles/${widget.article!['id']}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } else {
      // Create new
      await http.post(
        Uri.parse("$apiBase/articles"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    }
    setState(() => saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Article' : 'Write Article'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
            ),
            SizedBox(height: 18),
            Expanded(
              child: TextField(
                controller: contentCtrl,
                expands: true,
                minLines: null,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'Write your article here...',
                ),
                style: TextStyle(fontSize: 17),
                keyboardType: TextInputType.multiline,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text(isEditing ? 'Save Changes' : 'Post Article'),
                  onPressed: saving ? null : saveArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: StadiumBorder(),
                  ),
                ),
                if (saving) ...[
                  SizedBox(width: 18),
                  CircularProgressIndicator(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
