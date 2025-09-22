import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_two/components/my_textfield.dart';
import 'package:app_two/components/my_button.dart';
import 'package:app_two/helper/helper_functions.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPwController = TextEditingController();
  String selectedRole = 'mentee';

  void registerUser() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    if (passwordController.text != confirmPwController.text) {
      Navigator.pop(context);
      displayMessageToUser("Passwords do not match", context);
      return;
    }

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();

      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection("Users").doc(email).set({
        'email': email,
        'username': usernameController.text.trim(),
        'role': selectedRole,
      });

      Navigator.pop(context);
      debugPrint("User registered and role saved.");
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      displayMessageToUser(e.message ?? e.code, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 12,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        "Create an account, it is free!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Username
                      MyTextField(
                        controller: usernameController,
                        hintText: "Username",
                        obscureText: false,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      MyTextField(
                        controller: emailController,
                        hintText: "Email",
                        obscureText: false,
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      MyTextField(
                        controller: passwordController,
                        hintText: "Password",
                        obscureText: true,
                        icon: Icons.lock,
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      MyTextField(
                        controller: confirmPwController,
                        hintText: "Confirm Password",
                        obscureText: true,
                        icon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 14),

                      // Role dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: 'Select Role',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'mentor', child: Text("Mentor")),
                          DropdownMenuItem(value: 'mentee', child: Text("Mentee")),
                        ],
                        onChanged: (value) {
                          setState(() => selectedRole = value!);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Register Button
                      MyButton(
                        text: "Register",
                        onTap: registerUser,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: const Text(
                              "Login here",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
