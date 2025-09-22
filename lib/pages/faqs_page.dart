import 'package:flutter/material.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'question': 'How to connect with a mentor?',
      'answer': 'Try sending them a request! ;)'
    },
    {
      'question': 'How to schedule meetings?',
      'answer': 'Similar to calendar on phone, use the schedule section to set up your meetings with mentors or mentees. This function is still under maintenance and will have future upgrades.'
    },
    {
      'question': 'What are the matching algorithms used?',
      'answer': 'For the search mentors page, I used simple rule-based to match mentor and mentees. For the recommendation, i used weighted rule based with custom algorithms that implemented with fuzzy logic for subjects and interests matching'
    },
    {
      'question': 'Who can I contact for support?',
      'answer': 'You can reach out to mayushiimary@gmail.com for help or any inquiries.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Color(0xFFC8A2C8),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return ExpansionTile(
            title: Text(faq['question'] ?? ''),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(faq['answer'] ?? ''),
              ),
            ],
          );
        },
      ),
    );
  }
}
