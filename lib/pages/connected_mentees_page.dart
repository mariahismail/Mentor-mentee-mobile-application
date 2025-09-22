import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_page.dart';

class ConnectedMenteesPage extends StatefulWidget {
  const ConnectedMenteesPage({super.key});

  @override
  State<ConnectedMenteesPage> createState() => _ConnectedMenteesPageState();
}

class _ConnectedMenteesPageState extends State<ConnectedMenteesPage> {
  late final String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  }

  Future<List<Map<String, dynamic>>> getConnectedMentees() async {
    if (userEmail == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('mentorEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: 'accepted')
        .get();

    final menteeEmails = snapshot.docs
        .map((doc) => (doc['menteeEmail'] as String).toLowerCase())
        .toList();

    if (menteeEmails.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < menteeEmails.length; i += 10) {
      chunks.add(menteeEmails.sublist(
        i,
        i + 10 > menteeEmails.length ? menteeEmails.length : i + 10,
      ));
    }

    final List<Map<String, dynamic>> mentees = [];
    for (final chunk in chunks) {
      final menteesSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', whereIn: chunk)
          .get();

      mentees.addAll(
          menteesSnapshot.docs.map((doc) => doc.data()).toList());
    }

    return mentees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Mentees"),
        backgroundColor: const Color(0xFFC8A2C8),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getConnectedMentees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No connected mentees yet."));
          }

          final mentees = snapshot.data!;
          return ListView.builder(
            itemCount: mentees.length,
            itemBuilder: (context, index) {
              final mentee = mentees[index];
              final profilePicUrl = mentee['profilePicture'] ?? mentee['profileImageUrl'];
              final menteeEmail = mentee['email'] ?? '';
              final menteeName = mentee['username'] ?? 'No name';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePicUrl != null
                      ? NetworkImage(profilePicUrl)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                title: Text(menteeName),
                subtitle: Text(mentee['expectations'] ?? 'No expectations provided'),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagePage(
                        otherUserEmail: menteeEmail,
                        otherUserName: menteeName,
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
