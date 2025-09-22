import 'package:cloud_firestore/cloud_firestore.dart';
import 'fuzzy_match.dart';

class MentorMatcher {
  static double calculateMatchScore({
    required String menteeInterest,
    required int menteeSemester,
    required String menteeBranch,
    required String menteeCourse,
    required Map<String, dynamic> mentorData,
  }) {
    double score = 0.0;

    // Fuzzy match interest and expertise (weight: 0.5)
    final expertise = mentorData['expertise']?.toString() ?? '';
    if (FuzzyMatcher.isFuzzyMatch(menteeInterest, expertise)) {
      score += 0.5;
    }

    // Semester check (mentor must be senior, weight: 0.2)
    final mentorSemester = int.tryParse(mentorData['semester']?.toString() ?? '0') ?? 0;
    if (mentorSemester > menteeSemester) {
      score += 0.2;
    }

    // Branch match (weight: 0.15)
    final mentorBranch = mentorData['branch']?.toString().toLowerCase() ?? '';
    if (mentorBranch == menteeBranch.toLowerCase()) {
      score += 0.15;
    }

    // Course code match (weight: 0.15)
    final mentorCourse = mentorData['courseCode']?.toString().toLowerCase() ?? '';
    if (mentorCourse == menteeCourse.toLowerCase()) {
      score += 0.15;
    }

    return score;
  }
}
