import 'package:flutter/material.dart';

class ArticleViewPage extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleViewPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text(article['title'] ?? "Article"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.article,
                          color: Colors.blue[700], size: 34),
                      radius: 32,
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article['title'] ?? "",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900])),
                          SizedBox(height: 4),
                          Text(
                            article['doctor_name'] != null
                                ? "By ${article['doctor_name']}"
                                : "",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 2),
                          Text(
                            article['timestamp'] != null
                                ? article['timestamp']
                                : "",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 10),
                Text(
                  article['content'] ?? "",
                  style: TextStyle(
                      fontSize: 17, color: Colors.grey[900], height: 1.7),
                ),
                SizedBox(height: 28),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    label: Text("Back", style: TextStyle(fontSize: 16)),
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
