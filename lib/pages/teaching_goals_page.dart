import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeachingGoalPage extends StatefulWidget {
  const TeachingGoalPage({super.key});

  @override
  State<TeachingGoalPage> createState() => _TeachingGoalPageState();
}

class _TeachingGoalPageState extends State<TeachingGoalPage> {
  final _formKey = GlobalKey<FormState>();

  final q1Controller = TextEditingController();
  final q2Controller = TextEditingController();
  final q3Controller = TextEditingController();
  final q4Controller = TextEditingController();
  final q5Controller = TextEditingController();
  final q6Controller = TextEditingController();
  final q7Controller = TextEditingController();

  bool isLoading = false;

  Future<void> _submitGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase();
    if (email == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('Users').doc(email).update({
        'whyMentor': q1Controller.text.trim(),
        'personalGoals': q2Controller.text.trim(),
        'supportType': q3Controller.text.trim(),
        'desiredImpact': q4Controller.text.trim(),
        'expectedOutcomes': q5Controller.text.trim(),
        'anticipatedChallenges': q6Controller.text.trim(),
        'dailyQuote': q7Controller.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mentoring goals saved successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    q1Controller.dispose();
    q2Controller.dispose();
    q3Controller.dispose();
    q4Controller.dispose();
    q5Controller.dispose();
    q6Controller.dispose();
    q7Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Mentoring Goals")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("1. Why did you choose to become a mentor?"),
              TextFormField(
                controller: q1Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., To give back, grow personally, build skills",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("2. What are your personal goals as a mentor this semester?"),
              TextFormField(
                controller: q2Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Guide 2 mentees, improve leadership",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("3. What type of support do you want to give?"),
              TextFormField(
                controller: q3Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Academic guidance, career advice",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("4. What kind of impact do you want to make on your mentees?"),
              TextFormField(
                controller: q4Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Boost confidence, help prepare for industry",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("5. What outcomes do you hope your mentees will achieve?"),
              TextFormField(
                controller: q5Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Submit assignments, build portfolio",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("6. What challenges do you anticipate, and how might you overcome them?"),
              TextFormField(
                controller: q6Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Scheduling conflicts, low engagement",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 20),

              const Text("7. Quote for today?"),
              TextFormField(
                controller: q7Controller,
                decoration: const InputDecoration(
                  hintText: "e.g., Taking a first step is difficult but worth a mile",
                ),
                validator: (val) => val == null || val.isEmpty ? "This field is required" : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isLoading ? null : _submitGoals,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Goals for Today"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
