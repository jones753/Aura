import '../services/api_service.dart';

class DailyLog {
  final int id;
  final DateTime logDate;
  final int mood;
  final int energyLevel;
  final int stressLevel;
  final String notes;
  final String highlights;
  final String challenges;
  final int routineEntriesCount;
  final DateTime createdAt;

  DailyLog({
    required this.id,
    required this.logDate,
    required this.mood,
    required this.energyLevel,
    required this.stressLevel,
    required this.notes,
    required this.highlights,
    required this.challenges,
    required this.routineEntriesCount,
    required this.createdAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'],
      logDate: DateTime.parse(json['log_date']),
      mood: json['mood'] ?? 5,
      energyLevel: json['energy_level'] ?? 5,
      stressLevel: json['stress_level'] ?? 5,
      notes: json['notes'] ?? '',
      highlights: json['highlights'] ?? '',
      challenges: json['challenges'] ?? '',
      routineEntriesCount: json['routine_entries_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RoutineEntry {
  final int id;
  final int routineId;
  final String routineName;
  final String status;
  final int completionPercentage;
  final int? actualDuration;
  final int? difficultyFelt;
  final String notes;

  RoutineEntry({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.status,
    required this.completionPercentage,
    this.actualDuration,
    this.difficultyFelt,
    required this.notes,
  });

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    return RoutineEntry(
      id: json['id'],
      routineId: json['routine_id'],
      routineName: json['routine_name'] ?? 'Unknown',
      status: json['status'] ?? 'not_done',
      completionPercentage: json['completion_percentage'] ?? 0,
      actualDuration: json['actual_duration'],
      difficultyFelt: json['difficulty_felt'],
      notes: json['notes'] ?? '',
    );
  }
}

class DailyLogDetail {
  final int id;
  final DateTime logDate;
  final int mood;
  final int energyLevel;
  final int stressLevel;
  final String notes;
  final String highlights;
  final String challenges;
  final List<RoutineEntry> routineEntries;
  final DateTime createdAt;

  DailyLogDetail({
    required this.id,
    required this.logDate,
    required this.mood,
    required this.energyLevel,
    required this.stressLevel,
    required this.notes,
    required this.highlights,
    required this.challenges,
    required this.routineEntries,
    required this.createdAt,
  });

  factory DailyLogDetail.fromJson(Map<String, dynamic> json) {
    final entries = (json['routine_entries'] as List<dynamic>?)
        ?.map((e) => RoutineEntry.fromJson(e))
        .toList() ?? [];

    return DailyLogDetail(
      id: json['id'],
      logDate: DateTime.parse(json['log_date']),
      mood: json['mood'] ?? 5,
      energyLevel: json['energy_level'] ?? 5,
      stressLevel: json['stress_level'] ?? 5,
      notes: json['notes'] ?? '',
      highlights: json['highlights'] ?? '',
      challenges: json['challenges'] ?? '',
      routineEntries: entries,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DailyLogService {
  /// Get all daily logs
  static Future<List<DailyLog>> getDailyLogs() async {
    try {
      final response = await ApiService.get('/daily-logs');
      final List<dynamic> logsList = response['logs'] ?? [];
      return logsList.map((log) => DailyLog.fromJson(log)).toList();
    } catch (e) {
      throw Exception('Failed to get daily logs: $e');
    }
  }

  /// Get daily log by date
  static Future<DailyLogDetail> getDailyLogByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await ApiService.get('/daily-logs/date/$dateStr');
      return DailyLogDetail.fromJson(response['log']);
    } catch (e) {
      throw Exception('Failed to get daily log: $e');
    }
  }

  /// Create a daily log
  static Future<DailyLog> createDailyLog({
    required int mood,
    required int energyLevel,
    required int stressLevel,
    String notes = '',
    String highlights = '',
    String challenges = '',
  }) async {
    try {
      final response = await ApiService.post('/daily-logs', {
        'mood': mood,
        'energy_level': energyLevel,
        'stress_level': stressLevel,
        'notes': notes,
        'highlights': highlights,
        'challenges': challenges,
      });
      
      // Return a basic DailyLog object
      return DailyLog(
        id: response['log_id'],
        logDate: DateTime.parse(response['log_date']),
        mood: mood,
        energyLevel: energyLevel,
        stressLevel: stressLevel,
        notes: notes,
        highlights: highlights,
        challenges: challenges,
        routineEntriesCount: 0,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create daily log: $e');
    }
  }

  /// Update a daily log
  static Future<DailyLog> updateDailyLog({
    required int logId,
    int? mood,
    int? energyLevel,
    int? stressLevel,
    String? notes,
    String? highlights,
    String? challenges,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (mood != null) body['mood'] = mood;
      if (energyLevel != null) body['energy_level'] = energyLevel;
      if (stressLevel != null) body['stress_level'] = stressLevel;
      if (notes != null) body['notes'] = notes;
      if (highlights != null) body['highlights'] = highlights;
      if (challenges != null) body['challenges'] = challenges;

      final response = await ApiService.put('/daily-logs/$logId', body);
      return DailyLog.fromJson(response['log']);
    } catch (e) {
      throw Exception('Failed to update daily log: $e');
    }
  }

  /// Add routine entry to daily log
  static Future<void> addRoutineEntry({
    required int logId,
    required int routineId,
    required String status,
    int completionPercentage = 0,
    int? actualDuration,
    int? difficultyFelt,
    String notes = '',
  }) async {
    try {
      await ApiService.post('/daily-logs/$logId/routine-entry', {
        'routine_id': routineId,
        'status': status,
        'completion_percentage': completionPercentage,
        'actual_duration': actualDuration,
        'difficulty_felt': difficultyFelt,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to add routine entry: $e');
    }
  }

  /// Update routine entry
  static Future<void> updateRoutineEntry({
    required int entryId,
    String? status,
    int? completionPercentage,
    int? actualDuration,
    int? difficultyFelt,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (completionPercentage != null) body['completion_percentage'] = completionPercentage;
      if (actualDuration != null) body['actual_duration'] = actualDuration;
      if (difficultyFelt != null) body['difficulty_felt'] = difficultyFelt;
      if (notes != null) body['notes'] = notes;

      await ApiService.put('/daily-logs/routine-entry/$entryId', body);
    } catch (e) {
      throw Exception('Failed to update routine entry: $e');
    }
  }
}
