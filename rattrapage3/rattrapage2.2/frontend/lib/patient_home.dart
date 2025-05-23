import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tabs/profile_tab.dart';
import 'tabs/glucose_tab.dart';
import 'tabs/patient_appointments_tab.dart';
import 'tabs/medications_tab.dart';
import 'tabs/meals_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/reminders_tab.dart';
import 'tabs/doctor_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/articles_tab.dart';
import 'tabs/challenges_tab.dart';
import 'tabs/faq_tab.dart';
import 'dart:ui' as ui;

const String apiBase = "http://192.168.100.53:5000";

class PatientHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const PatientHome({required this.user});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int selectedIndex = 0;
  Map<String, dynamic>? myDoctor;
  List<dynamic> latestReminders = [];
  Map<String, dynamic>? latestGlucose;
  Map<String, dynamic>? latestMeal;
  Map<String, dynamic>? latestActivity;
  Map<String, dynamic>? latestMedication;

  // Notification Support
  List<Map<String, dynamic>> notifications = [];
  bool isNotifPanelOpen = false;
  bool hasNewNotification = false;

  late List<Widget> _extraPages;

  @override
  void initState() {
    super.initState();
    fetchMyDoctor();
    fetchDashboardData();
    fetchNotifications();
  }

  void fetchMyDoctor() async {
    final res = await http.get(
      Uri.parse("$apiBase/mydoctor/${widget.user['id']}"),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => myDoctor = data.isNotEmpty ? data : null);
    }
  }

  void fetchDashboardData() async {
    final remindersRes = await http.get(
      Uri.parse("$apiBase/reminders/${widget.user['id']}"),
    );
    final glucoseRes = await http.get(
      Uri.parse("$apiBase/glucose/${widget.user['id']}"),
    );
    final mealsRes = await http.get(
      Uri.parse("$apiBase/meals/${widget.user['id']}"),
    );
    final activityRes = await http.get(
      Uri.parse("$apiBase/activities/${widget.user['id']}"),
    );
    final medsRes = await http.get(
      Uri.parse("$apiBase/medications/${widget.user['id']}"),
    );

    if (!mounted) return;

    setState(() {
      latestReminders = remindersRes.statusCode == 200
          ? List.from(jsonDecode(remindersRes.body)).take(3).toList()
          : [];
      latestGlucose = glucoseRes.statusCode == 200 &&
              List.from(jsonDecode(glucoseRes.body)).isNotEmpty
          ? List.from(jsonDecode(glucoseRes.body)).first
          : null;
      latestMeal = mealsRes.statusCode == 200 &&
              List.from(jsonDecode(mealsRes.body)).isNotEmpty
          ? List.from(jsonDecode(mealsRes.body)).first
          : null;
      latestActivity = activityRes.statusCode == 200 &&
              List.from(jsonDecode(activityRes.body)).isNotEmpty
          ? List.from(jsonDecode(activityRes.body)).first
          : null;
      latestMedication = medsRes.statusCode == 200 &&
              List.from(jsonDecode(medsRes.body)).isNotEmpty
          ? List.from(jsonDecode(medsRes.body)).first
          : null;
    });
  }

  void fetchNotifications() async {
    final res = await http
        .get(Uri.parse("$apiBase/notifications/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final nList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        notifications = nList;
        hasNewNotification =
            notifications.any((n) => n['read'] == 0 || n['read'] == false);
      });
    }
  }

  void markAllNotificationsRead() async {
    await http.put(
        Uri.parse("$apiBase/notifications/mark_read/${widget.user['id']}"));
    fetchNotifications();
  }

  void onTabTapped(int idx) {
    setState(() {
      selectedIndex = idx;
    });
    if (selectedIndex == 0) fetchDashboardData();
  }

  Widget buildDashboardBox({
    required IconData icon,
    required String title,
    required Widget child,
    required Color color,
    VoidCallback? onTap,
    required String sentence,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: color, size: 28),
              radius: 28,
            ),
            const SizedBox(width: 19),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black87,
                      letterSpacing: 0.4,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                  const SizedBox(height: 6),
                  Text(
                    sentence,
                    style: TextStyle(
                      color: Colors.deepPurple[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  Widget buildCustomNavBar() {
    final List<IconData> icons = [
      Icons.home_rounded,
      Icons.article_rounded,
      Icons.flag_rounded,
      Icons.live_help_rounded,
      Icons.chat_rounded,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50.0,
          decoration: BoxDecoration(
            color: Colors.deepPurple[50]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              bool isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onTabTapped(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Icon(
                    icons[index],
                    color:
                        isSelected ? Colors.deepPurple[400] : Colors.grey[500],
                    size: isSelected ? 28 : 24,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void openNotificationsPanel() async {
    setState(() {
      isNotifPanelOpen = true;
    });
    markAllNotificationsRead();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 420),
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    "Notifications",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  Spacer(),
                  IconButton(
                      icon: Icon(Icons.close, color: Colors.grey, size: 26),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Divider(),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Text(
                          "No notifications yet.",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final n = notifications[idx];
                          IconData notifIcon;
                          Color notifColor;
                          String type = n['type'] ?? '';
                          if (type == 'message') {
                            notifIcon = Icons.chat_bubble_outline;
                            notifColor = Colors.blueAccent;
                          } else if (type == 'medication') {
                            notifIcon = Icons.medication_outlined;
                            notifColor = Colors.purple;
                          } else if (type == 'appointment') {
                            notifIcon = Icons.calendar_today_outlined;
                            notifColor = Colors.teal;
                          } else {
                            notifIcon = Icons.notifications;
                            notifColor = Colors.deepPurple;
                          }
                          return ListTile(
                            leading: Icon(notifIcon, color: notifColor),
                            title: Text(n['title'] ?? ''),
                            subtitle: Text(n['body'] ?? ''),
                            trailing: n['read'] == 0 || n['read'] == false
                                ? Icon(Icons.circle,
                                    color: Colors.red, size: 12)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {
      isNotifPanelOpen = false;
      hasNewNotification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _extraPages = [
      ArticlesTab(),
      ChallengesTab(user: widget.user),
      FAQTab(user: widget.user),
      ChatTab(user: widget.user, myDoctor: myDoctor),
    ];

    final dashboard = RefreshIndicator(
      onRefresh: () async => fetchDashboardData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          const SizedBox(height: 12),
          buildDashboardBox(
            icon: Icons.bloodtype_rounded,
            title: "Latest Glucose",
            color: const Color(0xFFFED9E1),
            child: latestGlucose != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${latestGlucose!['glucose_level']} mg/dL",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.pink[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${latestGlucose!['timestamp'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "No recent glucose reading.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GlucoseTab(user: widget.user))),
            sentence: "Log blood glucose, view trends and alerts.",
          ),
          buildDashboardBox(
            icon: Icons.calendar_today_rounded,
            title: "Appointments",
            color: const Color(0xFFE4D5F5),
            child: const Text(
              "Review, reschedule, or cancel your appointments.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    PatientAppointmentsTab(patientId: widget.user['id']))),
            sentence: "View and manage your appointments.",
          ),
          buildDashboardBox(
            icon: Icons.medical_services_rounded,
            title: "Current Medication",
            color: const Color(0xFFD6EAF8),
            child: latestMedication != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${latestMedication!['med_name']} (${latestMedication!['dosage']})",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${latestMedication!['prescribed_at'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "No medications found.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MedicationsTab(user: widget.user))),
            sentence: "See or update your medicines and doses.",
          ),
          buildDashboardBox(
            icon: Icons.fastfood_rounded,
            title: "Last Meal",
            color: const Color(0xFFFFF6D6),
            child: latestMeal != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${latestMeal!['description']} (${latestMeal!['meal_type']})",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${latestMeal!['timestamp'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "No meals logged.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MealsTab(user: widget.user))),
            sentence: "Log meals and see your meal history.",
          ),
          buildDashboardBox(
            icon: Icons.directions_run_rounded,
            title: "Latest Activity",
            color: const Color(0xFFD6F5E3),
            child: latestActivity != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${latestActivity!['activity_type']} (${latestActivity!['duration_minutes']} min)",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${latestActivity!['timestamp'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "No recent activity.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PhysicalActivityTab(user: widget.user))),
            sentence: "Log physical activity and view stats.",
          ),
          buildDashboardBox(
            icon: Icons.alarm_rounded,
            title: "Reminders",
            color: const Color(0xFFD6EAF8),
            child: latestReminders.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: latestReminders
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              "${r['title']} @ ${r['time']} (${r['frequency']})",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : const Text(
                    "No reminders set.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RemindersTab(user: widget.user))),
            sentence: "Set and manage reminders easily.",
          ),
          buildDashboardBox(
            icon: Icons.local_hospital_rounded,
            title: "My Doctor",
            color: const Color(0xFFE4D5F5),
            child: myDoctor != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        myDoctor!['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.purple[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myDoctor!['specialty'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "No doctor assigned.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DoctorTab(
                      user: widget.user,
                      myDoctor: myDoctor,
                      onDoctorChanged: () {
                        fetchMyDoctor();
                        fetchDashboardData();
                      },
                    ))),
            sentence: "Contact or change your doctor.",
          ),
        ],
      ),
    );

    final List<Widget> bottomBarPages = [
      dashboard,
      _extraPages[0],
      _extraPages[1],
      _extraPages[2],
      _extraPages[3],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.grey[700], size: 27),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, ${widget.user['name']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 19.5,
                  color: Colors.black87,
                  letterSpacing: 1.1,
                  fontFamily: 'Montserrat',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // NOTIFICATION BELL
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                    color: Colors.deepPurple[300], size: 28),
                tooltip: 'Notifications',
                onPressed: () {
                  openNotificationsPanel();
                  fetchNotifications();
                },
              ),
              if (hasNewNotification)
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Colors.deepPurple[300],
              size: 28,
            ),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileTab(user: widget.user),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red[300], size: 27),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 330),
        child: bottomBarPages[selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
        child: buildCustomNavBar(),
      ),
    );
  }
}
