import 'package:flutter/material.dart';
import 'mentor_search_page.dart';
import 'connected_mentors_page.dart';
import 'recommended_mentors_page.dart';

class ExploreMentorsPage extends StatelessWidget {
  const ExploreMentorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Explore Mentors"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: "Search"),
              Tab(icon: Icon(Icons.thumb_up), text: "Recommended"),
              Tab(icon: Icon(Icons.people), text: "Connected"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MentorSearchPage(),
            RecommendedMentorsPage(),
            ConnectedMentorsPage(),
          ],
        ),
      ),
    );
  }
}
