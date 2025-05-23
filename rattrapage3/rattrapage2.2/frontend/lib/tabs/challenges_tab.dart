import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../patient_home.dart';

class ChallengesTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const ChallengesTab({required this.user, super.key});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  List<Map<String, dynamic>> challenges = [];
  List<Map<String, dynamic>> myChallenges = [];
  bool loadingChallenges = false;

  @override
  void initState() {
    super.initState();
    fetchChallenges();
    fetchMyChallenges();
  }

  void fetchChallenges() async {
    setState(() => loadingChallenges = true);
    final res = await http.get(Uri.parse("$apiBase/challenges"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          challenges = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingChallenges = false);
  }

  void fetchMyChallenges() async {
    final res = await http
        .get(Uri.parse("$apiBase/challenges/user/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          myChallenges = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
  }

  void joinChallenge(int challengeId) async {
    await http.post(Uri.parse("$apiBase/challenges/join"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "challenge_id": challengeId,
          "user_id": widget.user['id'],
        }));
    fetchMyChallenges();
  }

  void leaveChallenge(int challengeId) async {
    await http.post(Uri.parse("$apiBase/challenges/leave"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "challenge_id": challengeId,
          "user_id": widget.user['id'],
        }));
    fetchMyChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: loadingChallenges
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.flag,
                  title: "Available Challenges",
                  color: Colors.orange[700]!,
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: challenges.isEmpty
                      ? Center(
                          child: Text(
                            "No challenges available.",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.separated(
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: challenges.length,
                          itemBuilder: (context, i) {
                            final c = challenges[i];
                            final joined =
                                myChallenges.any((mc) => mc['id'] == c['id']);
                            return ChallengeCard(
                              challenge: c,
                              joined: joined,
                              onJoin: () => joinChallenge(c['id']),
                              onLeave: () => leaveChallenge(c['id']),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(
                  icon: Icons.emoji_events,
                  title: "Your Challenges",
                  color: Colors.green[700]!,
                ),
                const SizedBox(height: 12),
                myChallenges.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Not participating in any challenges.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: myChallenges.length,
                          itemBuilder: (context, idx) => SizedBox(
                            width: 280,
                            child: MyChallengeBadge(
                              mc: myChallenges[idx],
                              onLeave: () =>
                                  leaveChallenge(myChallenges[idx]['id']),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool joined;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const ChallengeCard({
    required this.challenge,
    required this.joined,
    required this.onJoin,
    required this.onLeave,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: joined
                ? [Colors.green[100]!, Colors.green[50]!]
                : [Colors.orange[100]!, Colors.orange[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        joined ? Icons.check_circle : Icons.flag,
                        color: joined ? Colors.green[700] : Colors.orange[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          challenge['title'] ?? 'Untitled',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: joined ? Colors.green[900] : Colors.orange[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Spacer(),
                      AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: joined
                            ? TextButton.icon(
                                onPressed: onLeave,
                                icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                                label: Text(
                                  "Leave",
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: onJoin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  elevation: 2,
                                ),
                                child: Text(
                                  "Join",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge['description'] ?? "",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.blueGrey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "${challenge['start_date']} - ${challenge['end_date']}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blueGrey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.person, size: 14, color: Colors.blueGrey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          challenge['creator_name'] ?? "",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blueGrey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class MyChallengeBadge extends StatelessWidget {
  final Map<String, dynamic> mc;
  final VoidCallback onLeave;

  const MyChallengeBadge({required this.mc, required this.onLeave, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[200]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      mc['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.green[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                      tooltip: "Leave Challenge",
                      onPressed: onLeave,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  mc['description'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.teal[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "${mc['start_date']} - ${mc['end_date']}",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.teal[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}