import 'package:flutter/material.dart';
import '../../services/routine_service.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  late Future<List<Routine>> _routinesFuture;

  @override
  void initState() {
    super.initState();
    _routinesFuture = RoutineService.getRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _routinesFuture = RoutineService.getRoutines();
          });
        },
        child: FutureBuilder<List<Routine>>(
          future: _routinesFuture,
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
                      Icons.checklist,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No routines yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first routine to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final routines = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return RoutineCard(routine: routine, onRefresh: _refreshRoutines);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoutineDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshRoutines() async {
    setState(() {
      _routinesFuture = RoutineService.getRoutines();
    });
  }

  void _showCreateRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateRoutineDialog(),
    ).then((_) {
      _refreshRoutines();
    });
  }
}

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final Future<void> Function() onRefresh;

  const RoutineCard({
    required this.routine,
    required this.onRefresh,
  });

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditRoutineDialog(context),
                  icon: const Icon(Icons.edit),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(routine.frequency),
                  avatar: const Icon(Icons.repeat, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${routine.targetDuration} min'),
                  avatar: const Icon(Icons.schedule, size: 16),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Difficulty',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(routine.difficulty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${routine.difficulty}/10',
                        style: TextStyle(
                          color: _getDifficultyColor(routine.difficulty),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoutineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditRoutineDialog(
        routine: routine,
      ),
    ).then((_) {
      onRefresh();
    });
  }
}

class CreateRoutineDialog extends StatefulWidget {
  const CreateRoutineDialog({super.key});

  @override
  State<CreateRoutineDialog> createState() => _CreateRoutineDialogState();
}

class _CreateRoutineDialogState extends State<CreateRoutineDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'general';
  String _frequency = 'daily';
  int _targetDuration = 30;
  int _priority = 5;
  int _difficulty = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Routine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['health', 'work', 'personal', 'social', 'general']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _category = value ?? 'general';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ['daily', 'weekly', 'custom']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _frequency = value ?? 'daily';
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Target Duration: $_targetDuration minutes'),
            Slider(
              value: _targetDuration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              label: _targetDuration.toString(),
              onChanged: (value) {
                setState(() {
                  _targetDuration = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Difficulty: $_difficulty/10'),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _difficulty.toString(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value.toInt();
                });
              },
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
          onPressed: _isLoading ? null : _createRoutine,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createRoutine() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter routine name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RoutineService.createRoutine(
        name: _nameController.text,
        description: _descriptionController.text,
        category: _category,
        frequency: _frequency,
        targetDuration: _targetDuration,
        priority: _priority,
        difficulty: _difficulty,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine created successfully')),
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

class EditRoutineDialog extends StatefulWidget {
  final Routine routine;

  const EditRoutineDialog({required this.routine});

  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _category;
  late int _difficulty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController = TextEditingController(text: widget.routine.description);
    _category = widget.routine.category;
    _difficulty = widget.routine.difficulty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Routine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text('Difficulty: $_difficulty/10'),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _difficulty.toString(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _deleteRoutine,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateRoutine,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateRoutine() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await RoutineService.updateRoutine(
        routineId: widget.routine.id,
        name: _nameController.text,
        description: _descriptionController.text,
        difficulty: _difficulty,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine updated successfully')),
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

  Future<void> _deleteRoutine() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text('Are you sure you want to delete this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmDelete(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    Navigator.pop(context); // Close confirmation dialog
    setState(() {
      _isLoading = true;
    });

    try {
      await RoutineService.deleteRoutine(widget.routine.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine deleted successfully')),
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
