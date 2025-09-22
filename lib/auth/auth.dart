import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_or_register.dart';
import '../pages/mentor_home_page.dart';
import '../pages/mentee_home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading spinner while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Not logged in? Show login/register page
          if (!snapshot.hasData) {
            return const LoginOrRegister();
          }

          // Logged in — fetch user role from Firestore (email in lowercase)
          return FutureBuilder<String?>(
            future: _fetchUserRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (roleSnapshot.hasError) {
                return Center(child: Text("Error: ${roleSnapshot.error}"));
              }

              final role = roleSnapshot.data;
              print("Fetched role: $role"); // Debug print

              if (role == 'mentor') {
                return MentorHomePage();  // Removed const here
              } else if (role == 'mentee') {
                return MenteeHomePage();   // Removed const here
              } else {
                return const Center(child: Text("Role not assigned or unknown"));
              }
            },
          );
        },
      ),
    );
  }

  // Fetch user role using email in lowercase as Firestore document ID
  Future<String?> _fetchUserRole(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email!.toLowerCase())
          .get();

      if (doc.exists) {
        return doc.data()?['role'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching role: $e");
      return null;
    }
  }
}
