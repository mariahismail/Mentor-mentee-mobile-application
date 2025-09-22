import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  final _formKey = GlobalKey<FormState>();

  final goalsController = TextEditingController();
  final academicTasksController = TextEditingController();
  final anxietyController = TextEditingController();

  String? supportType;
  String? learningStyle;
  String? connectionFrequency;
  String? mentorStyle;

  Future<void> submitQuiz(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == null || !_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('Users').doc(email).update({
      'mentorshipGoals': goalsController.text.trim(),
      'supportType': supportType,
      'learningStyle': learningStyle,
      'connectionFrequency': connectionFrequency,
      'currentAcademicTasks': academicTasksController.text.trim(),
      'mentorStyle': mentorStyle,
      'studyAnxieties': anxietyController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your preferences have been updated")),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    goalsController.dispose();
    academicTasksController.dispose();
    anxietyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentorship Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. What are your goals from this mentorship?"),
              TextFormField(
                controller: goalsController,
                decoration: const InputDecoration(
                  hintText: "E.g., Improve grades, career planning...",
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              const Text("2. What type of support are you looking for?"),
              DropdownButtonFormField<String>(
                value: supportType,
                items: const [
                  DropdownMenuItem(
                      value: "Academic guidance", child: Text("Academic guidance")),
                  DropdownMenuItem(
                      value: "Career advice", child: Text("Career advice")),
                  DropdownMenuItem(
                      value: "Motivation and accountability",
                      child: Text("Motivation and accountability")),
                  DropdownMenuItem(
                      value: "Personal encouragement",
                      child: Text("Personal encouragement")),
                ],
                onChanged: (val) => setState(() => supportType = val),
                validator: (value) =>
                value == null ? "Please select an option" : null,
              ),
              const SizedBox(height: 16),

              const Text("3. How do you prefer to learn?"),
              DropdownButtonFormField<String>(
                value: learningStyle,
                items: const [
                  DropdownMenuItem(
                      value: "Visual explanations",
                      child: Text("Visual explanations")),
                  DropdownMenuItem(
                      value: "Hands-on practice",
                      child: Text("Hands-on practice")),
                  DropdownMenuItem(
                      value: "Discussions", child: Text("Discussions")),
                  DropdownMenuItem(
                      value: "Real-world examples",
                      child: Text("Real-world examples")),
                ],
                onChanged: (val) => setState(() => learningStyle = val),
                validator: (value) =>
                value == null ? "Please select an option" : null,
              ),
              const SizedBox(height: 16),

              const Text("4. How often do you want to connect with your mentor?"),
              DropdownButtonFormField<String>(
                value: connectionFrequency,
                items: const [
                  DropdownMenuItem(
                      value: "Once a week", child: Text("Once a week")),
                  DropdownMenuItem(
                      value: "Every two weeks",
                      child: Text("Every two weeks")),
                  DropdownMenuItem(
                      value: "Only when needed",
                      child: Text("Only when needed")),
                ],
                onChanged: (val) => setState(() => connectionFrequency = val),
                validator: (value) =>
                value == null ? "Please select an option" : null,
              ),
              const SizedBox(height: 16),

              const Text("5. Are you working on any specific academic tasks right now?"),
              TextFormField(
                controller: academicTasksController,
                decoration: const InputDecoration(
                  hintText: "E.g., FYP, internship applications...",
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              const Text("6. Do you prefer a mentor who is more structured or flexible?"),
              DropdownButtonFormField<String>(
                value: mentorStyle,
                items: const [
                  DropdownMenuItem(
                      value: "Structured", child: Text("Structured")),
                  DropdownMenuItem(value: "Flexible", child: Text("Flexible")),
                ],
                onChanged: (val) => setState(() => mentorStyle = val),
                validator: (value) =>
                value == null ? "Please select an option" : null,
              ),
              const SizedBox(height: 16),

              const Text("7. Is there anything you’re anxious or unsure about in your studies?"),
              TextFormField(
                controller: anxietyController,
                decoration: const InputDecoration(
                  hintText: "E.g., Presentation skills, time management...",
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),

              Center(
                child: ElevatedButton(
                  onPressed: () => submitQuiz(context),
                  child: const Text("Submit"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
