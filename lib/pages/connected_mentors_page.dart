import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_page.dart';

class ConnectedMentorsPage extends StatelessWidget {
  const ConnectedMentorsPage({super.key});

  Future<List<Map<String, dynamic>>> getConnectedMentors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('menteeEmail', isEqualTo: user.email!.toLowerCase())
        .where('status', isEqualTo: 'accepted')
        .get();

    final mentorEmails = snapshot.docs
        .map((doc) => (doc['mentorEmail'] as String).toLowerCase())
        .toList();

    if (mentorEmails.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < mentorEmails.length; i += 10) {
      chunks.add(mentorEmails.sublist(
          i, i + 10 > mentorEmails.length ? mentorEmails.length : i + 10));
    }

    final List<Map<String, dynamic>> mentors = [];
    for (final chunk in chunks) {
      final mentorsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', whereIn: chunk)
          .get();

      mentors.addAll(mentorsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    }

    return mentors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentors"),
        backgroundColor: const Color(0xFFC8A2C8),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getConnectedMentors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No connected mentors yet."));
          }

          final mentors = snapshot.data!;
          return ListView.builder(
            itemCount: mentors.length,
            itemBuilder: (context, index) {
              final mentor = mentors[index];
              final profilePicUrl = mentor['profilePicture'] ?? mentor['profileImageUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePicUrl != null
                      ? NetworkImage(profilePicUrl)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                title: Text(mentor['username'] ?? 'No name'),
                subtitle: Text(mentor['expertise'] ?? 'Expertise not available'),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagePage(
                        otherUserEmail: mentor['email'],
                        otherUserName: mentor['username'],
                        otherUserProfileUrl: profilePicUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
