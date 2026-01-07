import '../services/api_service.dart';

class Routine {
  final int id;
  final String name;
  final String description;
  final String category;
  final String frequency;
  final List<String> selectedDays; // List of days: ['Mon', 'Wed', 'Fri']
  final int targetDuration;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.selectedDays,
    required this.targetDuration,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    // Parse selected_days from backend
    List<String> days = [];
    final selectedDaysStr = json['selected_days'] ?? 'all';
    if (selectedDaysStr == 'all') {
      days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      days = (selectedDaysStr as String)
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    
    return Routine(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      frequency: json['frequency'] ?? 'daily',
      selectedDays: days,
      targetDuration: json['target_duration'] is int ? json['target_duration'] : int.parse(json['target_duration']?.toString() ?? '30'),
      priority: json['priority'] is int ? json['priority'] : int.parse(json['priority']?.toString() ?? '5'),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()),
      ),
      currentStreak: json['current_streak'] is int ? json['current_streak'] : int.parse(json['current_streak']?.toString() ?? '0'),
      longestStreak: json['longest_streak'] is int ? json['longest_streak'] : int.parse(json['longest_streak']?.toString() ?? '0'),
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'])
          : null,
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
    List<String>? selectedDays,
    int targetDuration = 30,
    int priority = 5,
  }) async {
    try {
      // Convert selectedDays to comma-separated string or 'all'
      String daysStr = 'all';
      if (selectedDays != null && selectedDays.isNotEmpty) {
        if (selectedDays.length == 7) {
          daysStr = 'all';
        } else {
          daysStr = selectedDays.join(',');
        }
      }
      
      final response = await ApiService.post('/routines', {
        'name': name,
        'description': description,
        'category': category,
        'frequency': frequency,
        'selected_days': daysStr,
        'target_duration': targetDuration,
        'priority': priority,
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
    List<String>? selectedDays,
    int? targetDuration,
    int? priority,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (frequency != null) body['frequency'] = frequency;
      if (selectedDays != null) {
        if (selectedDays.length == 7) {
          body['selected_days'] = 'all';
        } else {
          body['selected_days'] = selectedDays.join(',');
        }
      }
      if (targetDuration != null) body['target_duration'] = targetDuration;
      if (priority != null) body['priority'] = priority;
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
