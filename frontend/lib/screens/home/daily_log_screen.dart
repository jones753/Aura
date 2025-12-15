import 'package:flutter/material.dart';
import '../../services/daily_log_service.dart';
import '../../services/routine_service.dart';
import '../../services/feedback_service.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late Future<List<DailyLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = DailyLogService.getDailyLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Logs'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _logsFuture = DailyLogService.getDailyLogs();
          });
        },
        child: FutureBuilder<List<DailyLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No logs yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first daily log',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final logs = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return DailyLogCard(
                  log: log,
                  onRefresh: () {
                    setState(() {
                      _logsFuture = DailyLogService.getDailyLogs();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateLogDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateDailyLogDialog(),
    ).then((_) {
      setState(() {
        _logsFuture = DailyLogService.getDailyLogs();
      });
    });
  }
}

class DailyLogCard extends StatelessWidget {
  final DailyLog log;
  final Function() onRefresh;

  const DailyLogCard({
    required this.log,
    required this.onRefresh,
  });

  String _getMoodEmoji(int mood) {
    if (mood >= 8) return '😄';
    if (mood >= 6) return '🙂';
    if (mood >= 4) return '😐';
    if (mood >= 2) return '😞';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyLogDetailScreen(
                log: log,
                onRefresh: onRefresh,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood: ${log.mood}/10 ${_getMoodEmoji(log.mood)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.logDate.toString().split(' ')[0],
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _IndicatorColumn(
                    icon: Icons.battery_full,
                    label: 'Energy',
                    value: log.energyLevel,
                  ),
                  _IndicatorColumn(
                    icon: Icons.warning,
                    label: 'Stress',
                    value: log.stressLevel,
                  ),
                  _IndicatorColumn(
                    icon: Icons.task_alt,
                    label: 'Routines',
                    value: log.routineEntriesCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _IndicatorColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class CreateDailyLogDialog extends StatefulWidget {
  const CreateDailyLogDialog({super.key});

  @override
  State<CreateDailyLogDialog> createState() => _CreateDailyLogDialogState();
}

class _CreateDailyLogDialogState extends State<CreateDailyLogDialog> {
  int _mood = 5;
  int _energy = 5;
  int _stress = 5;
  final _notesController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _challengesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _highlightsController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Daily Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mood: $_mood/10'),
            Slider(
              value: _mood.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _mood.toString(),
              onChanged: (value) {
                setState(() {
                  _mood = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Energy Level: $_energy/10'),
            Slider(
              value: _energy.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _energy.toString(),
              onChanged: (value) {
                setState(() {
                  _energy = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Stress Level: $_stress/10'),
            Slider(
              value: _stress.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _stress.toString(),
              onChanged: (value) {
                setState(() {
                  _stress = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                hintText: 'What happened today?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _highlightsController,
              decoration: const InputDecoration(
                labelText: 'Highlights',
                border: OutlineInputBorder(),
                hintText: 'What went well?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _challengesController,
              decoration: const InputDecoration(
                labelText: 'Challenges',
                border: OutlineInputBorder(),
                hintText: 'What was difficult?',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createLog,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createLog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DailyLogService.createDailyLog(
        mood: _mood,
        energyLevel: _energy,
        stressLevel: _stress,
        notes: _notesController.text,
        highlights: _highlightsController.text,
        challenges: _challengesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily log created successfully')),
        );
      }
    } catch (e) {
      if (e.toString().contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a log for today')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class DailyLogDetailScreen extends StatefulWidget {
  final DailyLog log;
  final Function() onRefresh;

  const DailyLogDetailScreen({
    required this.log,
    required this.onRefresh,
  });

  @override
  State<DailyLogDetailScreen> createState() => _DailyLogDetailScreenState();
}

class _DailyLogDetailScreenState extends State<DailyLogDetailScreen> {
  late Future<DailyLogDetail> _detailFuture;
  late Future<List<Routine>> _routinesFuture;
  MentorFeedback? _feedback;
  bool _feedbackLoading = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = DailyLogService.getDailyLogByDate(widget.log.logDate);
    _routinesFuture = RoutineService.getRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log.logDate.toString().split(' ')[0]),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _detailFuture = DailyLogService.getDailyLogByDate(widget.log.logDate);
          });
        },
        child: FutureBuilder<DailyLogDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            }

            final detail = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Metrics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MetricCard(
                                label: 'Mood',
                                value: detail.mood,
                                icon: Icons.sentiment_satisfied,
                              ),
                              _MetricCard(
                                label: 'Energy',
                                value: detail.energyLevel,
                                icon: Icons.battery_full,
                              ),
                              _MetricCard(
                                label: 'Stress',
                                value: detail.stressLevel,
                                icon: Icons.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextSection(
                    context,
                    'Notes',
                    detail.notes,
                    Icons.note,
                  ),
                  const SizedBox(height: 12),
                  _buildTextSection(
                    context,
                    'Highlights',
                    detail.highlights,
                    Icons.star,
                  ),
                  const SizedBox(height: 12),
                  _buildTextSection(
                    context,
                    'Challenges',
                    detail.challenges,
                    Icons.warning_amber,
                  ),
                  const SizedBox(height: 16),
                  _buildRoutineSection(context, detail),
                  const SizedBox(height: 16),
                  _buildFeedbackSection(context, detail),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content.isEmpty ? 'No entry' : content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSection(BuildContext context, DailyLogDetail detail) {
    return FutureBuilder<List<Routine>>(
      future: _routinesFuture,
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Routines (${detail.routineEntries.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (snapshot.hasData)
                      ElevatedButton.icon(
                        onPressed: () => _showAddRoutineDialog(context, detail, snapshot.data!),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (detail.routineEntries.isEmpty)
                  Text(
                    'No routines logged yet',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.routineEntries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = detail.routineEntries[index];
                      return RoutineEntryTile(entry: entry);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection(BuildContext context, DailyLogDetail detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Feedback',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!_feedbackLoading)
                  ElevatedButton.icon(
                    onPressed: _generateFeedback,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_feedbackLoading)
              const Center(child: CircularProgressIndicator())
            else if (_feedback != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance Rate: ${_feedback!.routineComplianceRate}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top Performer: ${_feedback!.topPerformer}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Biggest Miss: ${_feedback!.biggestMiss}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _feedback!.suggestions,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              Text(
                'No feedback yet. Click Generate to get AI feedback.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFeedback() async {
    setState(() {
      _feedbackLoading = true;
    });

    try {
      final feedback = await FeedbackService.generateFeedback(widget.log.id);
      setState(() {
        _feedback = feedback;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _feedbackLoading = false;
      });
    }
  }

  void _showAddRoutineDialog(
    BuildContext context,
    DailyLogDetail detail,
    List<Routine> allRoutines,
  ) {
    final availableRoutines = allRoutines
        .where((r) => !detail.routineEntries.any((e) => e.routineId == r.id))
        .toList();

    if (availableRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All routines already logged')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddRoutineEntryDialog(
        logId: widget.log.id,
        routines: availableRoutines,
        onAdded: () {
          setState(() {
            _detailFuture = DailyLogService.getDailyLogByDate(widget.log.logDate);
          });
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          '$value/10',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class RoutineEntryTile extends StatelessWidget {
  final RoutineEntry entry;

  const RoutineEntryTile({required this.entry});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'skipped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.routineName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(entry.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.status.capitalize(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(entry.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (entry.actualDuration != null)
          Text(
            'Duration: ${entry.actualDuration} min (${entry.completionPercentage}%)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        if (entry.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              entry.notes,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class AddRoutineEntryDialog extends StatefulWidget {
  final int logId;
  final List<Routine> routines;
  final Function() onAdded;

  const AddRoutineEntryDialog({
    required this.logId,
    required this.routines,
    required this.onAdded,
  });

  @override
  State<AddRoutineEntryDialog> createState() => _AddRoutineEntryDialogState();
}

class _AddRoutineEntryDialogState extends State<AddRoutineEntryDialog> {
  late Routine _selectedRoutine;
  String _status = 'completed';
  int _completionPercentage = 100;
  int? _actualDuration;
  int? _difficultyFelt;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoutine = widget.routines.first;
    _actualDuration = _selectedRoutine.targetDuration;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Routine Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Routine>(
              value: _selectedRoutine,
              decoration: const InputDecoration(
                labelText: 'Routine',
                border: OutlineInputBorder(),
              ),
              items: widget.routines
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoutine = value!;
                  _actualDuration = _selectedRoutine.targetDuration;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['completed', 'partial', 'skipped', 'not_done']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Completion: $_completionPercentage%'),
            Slider(
              value: _completionPercentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: _completionPercentage.toString(),
              onChanged: (value) {
                setState(() {
                  _completionPercentage = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Actual Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _actualDuration = int.tryParse(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Difficulty Felt (1-10)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _difficultyFelt = int.tryParse(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addEntry,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DailyLogService.addRoutineEntry(
        logId: widget.logId,
        routineId: _selectedRoutine.id,
        status: _status,
        completionPercentage: _completionPercentage,
        actualDuration: _actualDuration,
        difficultyFelt: _difficultyFelt,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine entry added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

extension StringExt on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
