import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> acceptMentorRequest(String menteeEmail, String docId) async {
    final mentorEmail = user.email!.toLowerCase();
    final requestRef =
    firestore.collection('mentorRequests').doc(docId);
    final matchRef = firestore.collection('matches').doc('${menteeEmail}_$mentorEmail');

    await firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {'status': 'accepted'});

      final matchSnapshot = await matchRef.get();
      if (matchSnapshot.exists) {
        transaction.update(matchRef, {'status': 'accepted'});
      } else {
        transaction.set(matchRef, {
          'menteeEmail': menteeEmail,
          'mentorEmail': mentorEmail,
          'status': 'accepted',
          'timestamp': Timestamp.now(),
        });
      }

      final menteeNotification = firestore
          .collection('Users')
          .doc(menteeEmail)
          .collection('notifications')
          .doc();

      transaction.set(menteeNotification, {
        'title': 'Mentor Request Accepted',
        'message': '$mentorEmail has accepted your request!',
        'timestamp': Timestamp.now(),
        'status': 'unread',
        'type': 'request_response',
      });
    });
  }

  Future<void> rejectMentorRequest(String menteeEmail, String docId) async {
    final mentorEmail = user.email!.toLowerCase();
    final requestRef =
    firestore.collection('mentorRequests').doc(docId);
    final matchRef = firestore.collection('matches').doc('${menteeEmail}_$mentorEmail');

    await firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {'status': 'rejected'});

      final matchSnapshot = await matchRef.get();
      if (matchSnapshot.exists) {
        transaction.update(matchRef, {'status': 'rejected'});
      }

      final menteeNotification = firestore
          .collection('Users')
          .doc(menteeEmail)
          .collection('notifications')
          .doc();

      transaction.set(menteeNotification, {
        'title': 'Mentor Request Rejected',
        'message': '$mentorEmail has rejected your request.',
        'timestamp': Timestamp.now(),
        'status': 'unread',
        'type': 'request_response',
      });
    });
  }

  Stream<List<Map<String, dynamic>>> getMergedNotifications() async* {
    final email = user.email!.toLowerCase();

    final notificationsStream = firestore
        .collection('Users')
        .doc(email)
        .collection('notifications')
        .snapshots();

    final requestsStream = firestore
        .collection('mentorRequests')
        .where('mentorEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    await for (final notiSnapshot in notificationsStream) {
      await for (final requestSnapshot in requestsStream) {
        final notis = notiSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'No Title',
            'message': data['message'] ?? '',
            'timestamp': data['timestamp'] ?? Timestamp.now(),
            'status': data['status'] ?? 'unread',
            'type': data['type'] ?? 'notification',
            'isEvent': false,
            'isMatchRequest': false,
            'docRef': doc.reference,
          };
        }).toList();

        final requests = requestSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': 'Mentor Request',
            'message': 'From ${data['menteeName']} (${data['menteeEmail']})',
            'timestamp': data['timestamp'] ?? Timestamp.now(),
            'status': 'unread',
            'type': 'mentor_request',
            'isEvent': false,
            'isMatchRequest': true,
            'menteeEmail': data['menteeEmail'],
            'docRef': doc.reference,
          };
        }).toList();

        final combined = [...notis, ...requests];
        combined.sort((a, b) =>
            (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
        yield combined;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getMergedNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(noti['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(noti['message']),
                      Text(
                        (noti['timestamp'] as Timestamp)
                            .toDate()
                            .toString()
                            .substring(0, 16),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: noti['isMatchRequest']
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          acceptMentorRequest(
                              noti['menteeEmail'], noti['id']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          rejectMentorRequest(
                              noti['menteeEmail'], noti['id']);
                        },
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
