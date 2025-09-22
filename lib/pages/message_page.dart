import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';  // <-- Add this import

class MessagePage extends StatefulWidget {
  final String otherUserEmail;
  final String otherUserName;
  final String? otherUserProfileUrl;

  const MessagePage({
    super.key,
    required this.otherUserEmail,
    required this.otherUserName,
    this.otherUserProfileUrl,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String? currentUserProfileUrl;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserProfile();
  }

  Future<void> fetchCurrentUserProfile() async {
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email!.toLowerCase())
          .get();
      if (snapshot.exists) {
        setState(() {
          currentUserProfileUrl = snapshot.data()?['profileImageUrl'];
        });
      }
    }
  }

  String getConversationId() {
    final participants = [currentUser!.email!.toLowerCase(), widget.otherUserEmail.toLowerCase()]..sort();
    return participants.join('_');
  }

  Future<void> sendMessage({String? text, String? fileUrl, String? fileName}) async {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) return;
    final conversationId = getConversationId();

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(conversationId)
        .collection('chats')
        .add({
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'sender': currentUser!.email!.toLowerCase(),
      'timestamp': Timestamp.now(),
    });

    _controller.clear();
  }

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final mimeType = lookupMimeType(file.path);

      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dz5ok53gh/auto/upload");

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'flutter_upload'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));

      try {
        final response = await request.send();
        final resStr = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final secureUrl = RegExp(r'"secure_url"\s*:\s*"([^"]+)"')
              .firstMatch(resStr)
              ?.group(1);

          if (secureUrl != null) {
            await sendMessage(fileUrl: secureUrl, fileName: fileName);
          } else {
            throw Exception("Upload failed: No secure_url found in response.");
          }
        } else {
          throw Exception("Cloudinary upload failed: ${response.statusCode}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }

  Future<void> deleteMessage(String docId) async {
    final conversationId = getConversationId();
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(conversationId)
        .collection('chats')
        .doc(docId)
        .delete();
  }

  Future<void> editMessage(String docId, String oldText) async {
    final newTextController = TextEditingController(text: oldText);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: newTextController,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = newTextController.text.trim();
              if (newText.isNotEmpty) {
                final conversationId = getConversationId();
                await FirebaseFirestore.instance
                    .collection('messages')
                    .doc(conversationId)
                    .collection('chats')
                    .doc(docId)
                    .update({'text': newText});
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> downloadAndSaveFile(BuildContext context, String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  Widget buildFilePreview(String fileUrl, String fileName) {
    final lower = fileUrl.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullImageView(imageUrl: fileUrl),
            ),
          );
        },
        child: Image.network(fileUrl, height: 150, width: 150, fit: BoxFit.cover),
      );
    } else if (lower.endsWith('.pdf')) {
      // Open PDF externally using url_launcher to avoid 401 error on download
      return InkWell(
        onTap: () async {
          if (await canLaunch(fileUrl)) {
            await launch(fileUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open PDF')),
            );
          }
        },
        child: Text(
          fileName,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      );
    } else if (lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx')) {
      return InkWell(
        onTap: () => downloadAndSaveFile(context, fileUrl, fileName),
        child: Text(
          fileName,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      );
    } else {
      return const Text("Unsupported file");
    }
  }

  void onMessageLongPress(String docId, String oldText) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  editMessage(docId, oldText);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  await deleteMessage(docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = getConversationId();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserProfileUrl != null
                  ? NetworkImage(widget.otherUserProfileUrl!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
        backgroundColor: const Color(0xFFC8A2C8),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(conversationId)
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()! as Map<String, dynamic>;

                    final sender = data['sender'] ?? '';
                    final text = data['text'] ?? '';
                    final fileUrl = data['fileUrl'];
                    final fileName = data['fileName'] ?? 'File';

                    final isMe = sender == currentUser!.email!.toLowerCase();

                    return GestureDetector(
                      onLongPress: isMe
                          ? () => onMessageLongPress(doc.id, text)
                          : null,
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFC8A2C8) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: fileUrl != null
                              ? buildFilePreview(fileUrl, fileName)
                              : Text(text),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: pickAndUploadFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(text: _controller.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image'),
        backgroundColor: const Color(0xFFC8A2C8),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
