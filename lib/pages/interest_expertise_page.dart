// interest_expertise_settings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterestExpertisePage extends StatefulWidget {
  const InterestExpertisePage({super.key});

  @override
  _InterestExpertisePageState createState() => _InterestExpertisePageState();
}

class _InterestExpertisePageState extends State<InterestExpertisePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _tags = [];
  bool _isLoading = true;

  final String docId = 'SubjectExpertiseMap';
  final String field = 'tags';

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final doc = await FirebaseFirestore.instance.collection('SystemSettings').doc(docId).get();
    if (doc.exists && doc.data() != null && doc.data()![field] is List) {
      setState(() {
        _tags = List<String>.from(doc.data()![field]);
        _isLoading = false;
      });
    } else {
      setState(() {
        _tags = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addTag(String tag) async {
    tag = tag.toLowerCase().trim();
    if (tag.isEmpty || _tags.contains(tag)) return;

    setState(() {
      _tags.add(tag);
    });

    await FirebaseFirestore.instance.collection('SystemSettings').doc(docId).set({
      field: _tags,
    }, SetOptions(merge: true));

    _controller.clear();
  }

  Future<void> _removeTag(String tag) async {
    setState(() {
      _tags.remove(tag);
    });

    await FirebaseFirestore.instance.collection('SystemSettings').doc(docId).set({
      field: _tags,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Interests / Expertise")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add new tag (interest or expertise):"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "e.g., cybersecurity, AI, CSC404",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTag(_controller.text),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text("Current Tags:"),
            Wrap(
              spacing: 8,
              children: _tags
                  .map((tag) => Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _removeTag(tag),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
