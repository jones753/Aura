import '../services/api_service.dart';

class MentorFeedback {
  final int id;
  final String feedbackText;
  final double routineComplianceRate;
  final String topPerformer;
  final String biggestMiss;
  final String suggestions;
  final DateTime createdAt;

  MentorFeedback({
    required this.id,
    required this.feedbackText,
    required this.routineComplianceRate,
    required this.topPerformer,
    required this.biggestMiss,
    required this.suggestions,
    required this.createdAt,
  });

  factory MentorFeedback.fromJson(Map<String, dynamic> json) {
    final rate = json['routine_compliance_rate'];
    double parsedRate;
    if (rate is int) {
      parsedRate = rate.toDouble();
    } else if (rate is double) {
      parsedRate = rate;
    } else {
      parsedRate = 0.0;
    }
    return MentorFeedback(
      id: json['id'],
      feedbackText: json['feedback_text'] ?? '',
      routineComplianceRate: parsedRate,
      topPerformer: json['top_performer'] ?? 'N/A',
      biggestMiss: json['biggest_miss'] ?? 'N/A',
      suggestions: json['suggestions'] ?? '',
      createdAt: DateTime.parse((json['created_at'] ?? DateTime.now().toIso8601String())),
    );
  }
}

class FeedbackService {
  /// Get feedback for a specific daily log
  static Future<MentorFeedback> getFeedbackForLog(int logId) async {
    try {
      final response = await ApiService.get('/feedback/daily/$logId');
      return MentorFeedback.fromJson(response['feedback']);
    } catch (e) {
      throw Exception('Failed to get feedback: $e');
    }
  }

  /// Generate feedback for a daily log
  static Future<MentorFeedback> generateFeedback(int logId) async {
    try {
      final response = await ApiService.post('/feedback/generate/$logId', {});
      return MentorFeedback.fromJson(response['feedback']);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('already exists')) {
        // Idempotent fetch of existing feedback
        return await getFeedbackForLog(logId);
      }
      throw Exception('Failed to generate feedback: $e');
    }
  }

  /// Get all feedback
  static Future<List<MentorFeedback>> getAllFeedback() async {
    try {
      final response = await ApiService.get('/feedback');
      final List<dynamic> feedbackList = response['feedback_history'] ?? [];
      return feedbackList.map((f) => MentorFeedback.fromJson(f)).toList();
    } catch (e) {
      throw Exception('Failed to get feedback: $e');
    }
  }
}
