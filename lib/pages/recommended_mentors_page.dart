// lib/pages/recommended_mentors_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/matching_algorithm.dart';

class RecommendedMentorsPage extends StatelessWidget {
  const RecommendedMentorsPage({super.key});

  Future<List<Map<String, dynamic>>> fetchRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();

    final menteeInterest = userDoc['interest']?.toString() ?? '';
    final menteeSemester = int.tryParse(userDoc['semester']?.toString() ?? '0') ?? 0;
    final menteeBranch = userDoc['branch']?.toString() ?? '';
    final menteeCourse = userDoc['courseCode']?.toString() ?? '';

    final mentorDocs = await FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'mentor')
        .get();

    final List<Map<String, dynamic>> matches = [];

    for (var doc in mentorDocs.docs) {
      final mentorData = doc.data();
      final score = MentorMatcher.calculateMatchScore(
        menteeInterest: menteeInterest,
        menteeSemester: menteeSemester,
        menteeBranch: menteeBranch,
        menteeCourse: menteeCourse,
        mentorData: mentorData,
      );

      if (score >= 0.5) {
        mentorData['matchScore'] = score; // Save for sorting
        matches.add(mentorData);
      }
    }

    // Sort by match score descending
    matches.sort((a, b) => (b['matchScore'] as double).compareTo(a['matchScore'] as double));

    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No recommendations found."));
        }

        final mentors = snapshot.data!;
        return ListView.builder(
          itemCount: mentors.length,
          itemBuilder: (context, index) {
            final mentor = mentors[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: mentor['profilePicture'] != null
                    ? NetworkImage(mentor['profilePicture'])
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
              title: Text(mentor['username'] ?? 'No name'),
              subtitle: Text('Expertise: ${mentor['expertise'] ?? 'N/A'}\n'
                  'Match Score: ${(mentor['matchScore'] as double).toStringAsFixed(2)}'),
              trailing: const Icon(Icons.send),
            );
          },
        );
      },
    );
  }
}
