import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorSearchPage extends StatefulWidget {
  @override
  _MentorSearchPageState createState() => _MentorSearchPageState();
}

class _MentorSearchPageState extends State<MentorSearchPage> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> mentors = [];

  void searchMentors() async {
    String interest = searchController.text.trim().toLowerCase();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'mentor')
        .get();

    setState(() {
      mentors = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((mentor) =>
          (mentor['expertise'] ?? '')
              .toString()
              .toLowerCase()
              .contains(interest))
          .toList();
    });
  }

  void requestMentor(String mentorEmail, String mentorName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Send a mentor request to Firestore
      await FirebaseFirestore.instance.collection('mentorRequests').add({
        'menteeEmail': user.email,
        'menteeName': user.displayName,
        'mentorEmail': mentorEmail,
        'mentorName': mentorName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create a match document (optional)
      await FirebaseFirestore.instance.collection('matches').add({
        'menteeEmail': user.email,
        'mentorEmail': mentorEmail,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send a notification to the mentor
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientEmail': mentorEmail,
        'title': 'New Mentor Request',
        'message': '${user.displayName ?? user.email} has requested to connect.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'mentor_request',
        'status': 'unread',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentor request sent to $mentorName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Mentors")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(labelText: "Search by expertise"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: searchMentors,
              child: const Text("Search"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: mentors.isEmpty
                  ? const Center(child: Text("No mentors found."))
                  : ListView.builder(
                itemCount: mentors.length,
                itemBuilder: (context, index) {
                  final mentor = mentors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: mentor['profilePicture'] != null &&
                            mentor['profilePicture'] != ''
                            ? NetworkImage(mentor['profilePicture'])
                            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      title: Text(mentor['username'] ?? 'No name'),
                      subtitle: Text("Expertise: ${mentor['expertise'] ?? 'N/A'}"),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            requestMentor(mentor['email'], mentor['username']),
                        child: const Text("Request"),
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
