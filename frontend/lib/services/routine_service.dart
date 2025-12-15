import '../services/api_service.dart';

class Routine {
  final int id;
  final String name;
  final String description;
  final String category;
  final String frequency;
  final int targetDuration;
  final int priority;
  final int difficulty;
  final bool isActive;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDuration,
    required this.priority,
    required this.difficulty,
    required this.isActive,
    required this.createdAt,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      frequency: json['frequency'] ?? 'daily',
      targetDuration: json['target_duration'] ?? 30,
      priority: json['priority'] ?? 5,
      difficulty: json['difficulty'] ?? 5,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()),
      ),
    );
  }
}

class RoutineService {
  /// Get all routines
  static Future<List<Routine>> getRoutines() async {
    try {
      final response = await ApiService.get('/routines');
      final List<dynamic> routinesList = response['routines'] ?? [];
      return routinesList.map((r) => Routine.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to get routines: $e');
    }
  }

  /// Create a new routine
  static Future<Routine> createRoutine({
    required String name,
    String description = '',
    String category = 'general',
    String frequency = 'daily',
    int targetDuration = 30,
    int priority = 5,
    int difficulty = 5,
  }) async {
    try {
      final response = await ApiService.post('/routines', {
        'name': name,
        'description': description,
        'category': category,
        'frequency': frequency,
        'target_duration': targetDuration,
        'priority': priority,
        'difficulty': difficulty,
      });
      return Routine.fromJson(response['routine']);
    } catch (e) {
      throw Exception('Failed to create routine: $e');
    }
  }

  /// Update a routine
  static Future<Routine> updateRoutine({
    required int routineId,
    String? name,
    String? description,
    String? category,
    String? frequency,
    int? targetDuration,
    int? priority,
    int? difficulty,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (frequency != null) body['frequency'] = frequency;
      if (targetDuration != null) body['target_duration'] = targetDuration;
      if (priority != null) body['priority'] = priority;
      if (difficulty != null) body['difficulty'] = difficulty;
      if (isActive != null) body['is_active'] = isActive;

      final response = await ApiService.put('/routines/$routineId', body);
      return Routine.fromJson(response['routine']);
    } catch (e) {
      throw Exception('Failed to update routine: $e');
    }
  }

  /// Delete a routine
  static Future<void> deleteRoutine(int routineId) async {
    try {
      await ApiService.delete('/routines/$routineId');
    } catch (e) {
      throw Exception('Failed to delete routine: $e');
    }
  }
}
