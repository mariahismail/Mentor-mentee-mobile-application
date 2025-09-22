import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth/login_or_register.dart';
import 'pages/mentor_home_page.dart';
import 'pages/mentee_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _fetchUserRole(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email!.toLowerCase())
          .get();

      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final user = snapshot.data;

          if (user == null) {
            return const LoginOrRegister();
          }

          return FutureBuilder<String?>(
            future: _fetchUserRole(user),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final role = roleSnapshot.data;

              if (role == 'mentor') {
                return const MentorHomePage();
              } else if (role == 'mentee') {
                return const MenteeHomePage();
              } else {
                return const Scaffold(
                  body: Center(child: Text("Role not assigned or unknown. Please contact support.")),
                );
              }
            },
          );
        },
      ),
    );
  }
}
