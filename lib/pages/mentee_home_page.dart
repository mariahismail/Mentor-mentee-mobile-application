import 'package:app_two/pages/connected_mentors_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_page.dart';
import 'explore_mentors_page.dart';
import 'profile_menu_page.dart';
import 'schedule_page.dart';
import 'notification_page.dart';

class MenteeHomePage extends StatefulWidget {
  const MenteeHomePage({super.key});

  @override
  State<MenteeHomePage> createState() => _MenteeHomePageState();
}

class _MenteeHomePageState extends State<MenteeHomePage> {
  int _selectedIndex = 0;
  String? currentUserEmail;
  String userName = '';
  String branch = '';
  String role = 'mentee';
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
          currentUserEmail = user.email!;
          userName = doc['username'] ?? '';
          branch = doc['branch'] ?? '';
          role = doc['role'] ?? 'mentee';
          isLoadingUser = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchConnectedMentors() async {
    if (currentUserEmail == null) return [];

    final matchSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('menteeEmail', isEqualTo: currentUserEmail)
        .where('status', isEqualTo: 'accepted')
        .get();

    final mentorEmails = matchSnapshot.docs
        .map((doc) => (doc['mentorEmail'] as String).toLowerCase())
        .toList();

    if (mentorEmails.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < mentorEmails.length; i += 10) {
      chunks.add(
        mentorEmails.sublist(i, i + 10 > mentorEmails.length ? mentorEmails.length : i + 10),
      );
    }

    final mentors = <Map<String, dynamic>>[];

    for (final chunk in chunks) {
      final mentorSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', whereIn: chunk)
          .get();

      mentors.addAll(
        mentorSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList(),
      );
    }

    return mentors;
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

  Widget _buildHomePage(BuildContext context) {
    final greetingOptions = ["Hi", "Hello", "Welcome back", "Nice to see you"];
    final greeting = greetingOptions[DateTime.now().second % greetingOptions.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar Substitute
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(branch, style: Theme.of(context).textTheme.bodyMedium),
          Text("Role: $role", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // Quiz Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.pink.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset('assets/mentor_quiz.png', height: 80),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Find your best mentor!",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuizPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Do Quiz"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Calendar and Your Mentors Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar block on left
              Expanded(
                flex: 1,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${DateTime.now().day}",
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][DateTime.now().month - 1]}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${DateTime.now().year}",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Your Mentors header and list on right
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header container
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your Mentors",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnectedMentorsPage()),
                              );
                            },
                            child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Mentor list below header with fixed height & scrolling
                    SizedBox(
                      height: 180, // adjust height as you like
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchConnectedMentors(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No connected mentors yet"));
                          }

                          final mentors = snapshot.data!;
                          final topMentors = mentors.take(2).toList();

                          return ListView.separated(
                            itemCount: topMentors.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final mentor = topMentors[index];
                              final profilePicUrl = mentor['profilePicture'] ?? mentor['profileImageUrl'];final rawExpertise = mentor['expertise'];
                              String expertise;
                              if (rawExpertise is List) {
                                expertise = rawExpertise.join(', ');
                              } else if (rawExpertise is String) {
                                expertise = rawExpertise;
                              } else {
                                expertise = 'No expertise';
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: profilePicUrl != null
                                      ? NetworkImage(profilePicUrl)
                                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                ),
                                title: Text(mentor['username'] ?? 'Unknown'),
                                subtitle: Text(expertise),
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

          // Upcoming Events
          Text("Upcoming Events", style: Theme.of(context).textTheme.titleMedium),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    _buildHomePage(context),
    const ExploreMentorsPage(),
    currentUserEmail == null
        ? const Center(child: CircularProgressIndicator())
        : SchedulePage(isMentor: false, currentUserEmail: currentUserEmail!),
    ProfileMenuPage(role: 'mentee'),
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
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Connection'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
