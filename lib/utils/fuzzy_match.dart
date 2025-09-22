// lib/utils/fuzzy_match.dart
import 'package:string_similarity/string_similarity.dart';

class FuzzyMatcher {
  static final Map<String, List<String>> _synonymMap = {
    'ai': ['artificial intelligence', 'a.i', 'ai research'],
    'ml': ['machine learning', 'ml research'],
    'programming': ['coding', 'software development'],
    'web dev': ['web development', 'frontend', 'backend'],
    'cybersecurity': ['information security', 'network security'],
    // Add more as needed
  };

  static bool isFuzzyMatch(String interest, String expertise) {
    interest = interest.toLowerCase().trim();
    expertise = expertise.toLowerCase().trim();

    if (interest.similarityTo(expertise) > 0.6) return true;

    for (var synonym in _synonymMap[interest] ?? []) {
      if (synonym.similarityTo(expertise) > 0.6) return true;
    }

    return false;
  }
}
