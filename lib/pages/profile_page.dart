import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  File? _selectedImage;
  Map<String, dynamic>? userData;
  bool isLoading = false;

  final bioController = TextEditingController();
  final availabilityController = TextEditingController();
  final interestController = TextEditingController();
  final courseCodeController = TextEditingController();
  final branchController = TextEditingController();
  final semesterController = TextEditingController();
  final expertiseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.email?.toLowerCase())
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      userData = data;

      bioController.text = data['bio'] ?? '';
      availabilityController.text = data['availability'] ?? '';
      interestController.text = data['interest'] ?? '';
      courseCodeController.text = data['courseCode'] ?? '';
      branchController.text = data['branch'] ?? '';
      semesterController.text = data['semester']?.toString() ?? '';
      expertiseController.text = data['expertise'] ?? '';

      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dz5ok53gh';
    final preset = 'flutter_upload';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final jsonRes = json.decode(resStr);
      return jsonRes['secure_url'];
    } else {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);

    final data = <String, dynamic>{
      'bio': bioController.text.trim(),
      'courseCode': courseCodeController.text.trim(),
      'branch': branchController.text.trim(),
      'semester': int.tryParse(semesterController.text.trim()) ?? 0,
    };

    if (widget.role == 'mentor') {
      data['availability'] = availabilityController.text.trim();
      data['expertise'] = expertiseController.text.trim();
    } else {
      data['interest'] = interestController.text.trim();
    }

    if (_selectedImage != null) {
      final imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl != null) {
        data['profileImageUrl'] = imageUrl;
      }
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.email!.toLowerCase())
        .update(data);

    await _loadUserData();

    setState(() {
      _selectedImage = null;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = widget.role;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    role == 'mentor' ? 'You are a Mentor' : 'You are a Mentee',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : userData!['profileImageUrl'] != null
                        ? NetworkImage(userData!['profileImageUrl'])
                        : const AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit),
                    label: const Text("Change Photo"),
                  ),
                  Text(userData!['username'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(userData!['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Bio"),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Short bio"),
            ),
            if (role == 'mentor') ...[
              const SizedBox(height: 15),
              const Text("Expertise"),
              TextField(
                controller: expertiseController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "e.g. flutter, ai, big data",
                ),
              ),
              const SizedBox(height: 15),
              const Text("Availability"),
              TextField(
                controller: availabilityController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Availability schedule",
                ),
              ),
            ],
            if (role == 'mentee') ...[
              const SizedBox(height: 15),
              const Text("Interests"),
              TextField(
                controller: interestController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "e.g. flutter, ai, big data"),
              ),
            ],
            const SizedBox(height: 15),
            const Text("Course Code"),
            TextField(
              controller: courseCodeController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "e.g. CSC543"),
            ),
            const SizedBox(height: 15),
            const Text("Branch"),
            TextField(
              controller: branchController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "University branch"),
            ),
            const SizedBox(height: 15),
            const Text("Semester"),
            TextField(
              controller: semesterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "e.g. 5"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _saveProfile,
              child: isLoading ? const CircularProgressIndicator() : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
