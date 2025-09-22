import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'connected_mentees_page.dart';
import 'schedule_page.dart';
import 'profile_menu_page.dart';
import 'notification_page.dart';
import 'teaching_goals_page.dart';

class MentorHomePage extends StatefulWidget {
  const MentorHomePage({super.key});

  @override
  State<MentorHomePage> createState() => _MentorHomePageState();
}

class _MentorHomePageState extends State<MentorHomePage> {
  int _selectedIndex = 0;
  String? currentUserEmail;
  String userName = '';
  String branch = '';
  String role = 'mentor';
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email!.toLowerCase())
          .get();
      if (doc.exists) {
        setState(() {
          currentUserEmail = user.email?.toLowerCase();
          userName = doc['username'] ?? '';
          branch = doc['branch'] ?? '';
          role = doc['role'] ?? 'mentor';
          isLoadingUser = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchConnectedMentees() async {
    if (currentUserEmail == null) return [];

    final matchSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('mentorEmail', isEqualTo: currentUserEmail)
        .where('status', isEqualTo: 'accepted')
        .get();

    final menteeEmails = matchSnapshot.docs
        .map((doc) => (doc['menteeEmail'] as String).toLowerCase())
        .toList();

    if (menteeEmails.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < menteeEmails.length; i += 10) {
      chunks.add(menteeEmails.sublist(
          i, i + 10 > menteeEmails.length ? menteeEmails.length : i + 10));
    }

    final mentees = <Map<String, dynamic>>[];

    for (final chunk in chunks) {
      final menteeSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', whereIn: chunk)
          .get();

      mentees.addAll(menteeSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    }

    return mentees;
  }

  Future<List<Map<String, dynamic>>> _fetchUpcomingEvents() async {
    if (currentUserEmail == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('schedule')
        .where('userEmail', isEqualTo: currentUserEmail)
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  Widget _buildHomePage() {
    if (isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    final greetingOptions = ["Hi", "Welcome", "Hello", "Good to see you"];
    final greeting =
    greetingOptions[DateTime.now().second % greetingOptions.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "HOME",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 12,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none, size: 28),
                    onPressed: _openNotifications,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            "$greeting, $userName!",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(branch, style: Theme.of(context).textTheme.bodyMedium),
          Text("Role: $role", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // Goals Card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Let\'s Set Up Your Teaching Goals',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TeachingGoalPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Begin'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/goal_setup.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${DateTime.now().day}",
                            style: const TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          "${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][DateTime.now().month - 1]}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text("${DateTime.now().year}",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Your Mentees",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const ConnectedMenteesPage(),
                                ),
                              );
                            },
                            child: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchConnectedMentees(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text("No connected mentees yet"));
                          }

                          final mentees = snapshot.data!;
                          final topMentees = mentees.take(2).toList();

                          return ListView.separated(
                            itemCount: topMentees.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final mentee = topMentees[index];
                              final profilePicUrl = mentee['profilePicture'] ??
                                  mentee['profileImageUrl'];
                              final rawInterests = mentee['interest'];
                              String interests;
                              if (rawInterests is List) {
                                interests = rawInterests.join(', ');
                              } else if (rawInterests is String) {
                                interests = rawInterests;
                              } else {
                                interests = 'No interests';
                              }
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: profilePicUrl != null
                                      ? NetworkImage(profilePicUrl)
                                      : const AssetImage(
                                      'assets/default_avatar.png')
                                  as ImageProvider,
                                ),
                                title: Text(mentee['username'] ?? 'Unknown'),
                                subtitle: Text(interests),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text("Upcoming Events",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No upcoming events.");
              }

              return Column(
                children: snapshot.data!.map((event) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(event['title'] ?? 'Event'),
                      subtitle: Text("Date: ${event['date'] ?? 'N/A'}"),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> get _pages => [
    _buildHomePage(),
    const ConnectedMenteesPage(),
    currentUserEmail == null
        ? const Center(child: CircularProgressIndicator())
        : SchedulePage(isMentor: true, currentUserEmail: currentUserEmail!),
    ProfileMenuPage(role: 'mentor'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFFC8A2C8),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Mentees'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
