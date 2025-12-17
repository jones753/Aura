import 'package:flutter/material.dart';
import '../../services/routine_service.dart';
import '../home/home_screen.dart';

class ManualRoutineScreen extends StatefulWidget {
  const ManualRoutineScreen({super.key});

  @override
  State<ManualRoutineScreen> createState() => _ManualRoutineScreenState();
}

class _ManualRoutineScreenState extends State<ManualRoutineScreen> {
  final List<Map<String, dynamic>> _routines = [];
  bool _isSaving = false;

  void _addRoutine() {
    showDialog(
      context: context,
      builder: (context) => _RoutineDialog(
        onSave: (routine) {
          setState(() {
            _routines.add(routine);
          });
        },
      ),
    );
  }

  void _editRoutine(int index) {
    showDialog(
      context: context,
      builder: (context) => _RoutineDialog(
        initialRoutine: _routines[index],
        onSave: (routine) {
          setState(() {
            _routines[index] = routine;
          });
        },
      ),
    );
  }

  void _removeRoutine(int index) {
    setState(() {
      _routines.removeAt(index);
    });
  }

  Future<void> _saveAndContinue() async {
    if (_routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one routine')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (final routine in _routines) {
        await RoutineService.createRoutine(
          name: routine['name'],
          description: routine['description'] ?? '',
          category: routine['category'] ?? 'general',
          targetDuration: routine['target_duration'] ?? 30,
          priority: routine['priority'] ?? 5,
          difficulty: routine['difficulty'] ?? 5,
        );
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routines created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Routines'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Add routines you want to track daily',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: _routines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No routines yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first routine',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _routines.length,
                      itemBuilder: (context, index) {
                        final routine = _routines[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(routine['name']),
                            subtitle: Text(
                              '${routine['category']} • ${routine['target_duration']} min',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editRoutine(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeRoutine(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save and Continue'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoutine,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoutineDialog extends StatefulWidget {
  final Map<String, dynamic>? initialRoutine;
  final Function(Map<String, dynamic>) onSave;

  const _RoutineDialog({
    this.initialRoutine,
    required this.onSave,
  });

  @override
  State<_RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends State<_RoutineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _category;
  late int _targetDuration;
  late int _priority;
  late int _difficulty;

  @override
  void initState() {
    super.initState();
    final routine = widget.initialRoutine;
    _nameController = TextEditingController(text: routine?['name'] ?? '');
    _descriptionController = TextEditingController(text: routine?['description'] ?? '');
    _category = routine?['category'] ?? 'general';
    _targetDuration = routine?['target_duration'] ?? 30;
    _priority = routine?['priority'] ?? 5;
    _difficulty = routine?['difficulty'] ?? 5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }

    widget.onSave({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'category': _category,
      'target_duration': _targetDuration,
      'priority': _priority,
      'difficulty': _difficulty,
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialRoutine == null ? 'Add Routine' : 'Edit Routine',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Routine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'health', child: Text('Health')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'social', child: Text('Social')),
                ],
                onChanged: (value) {
                  setState(() {
                    _category = value ?? 'general';
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Target Duration: $_targetDuration min'),
              Slider(
                value: _targetDuration.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: '$_targetDuration min',
                onChanged: (value) {
                  setState(() {
                    _targetDuration = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Priority: $_priority'),
              Slider(
                value: _priority.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_priority',
                onChanged: (value) {
                  setState(() {
                    _priority = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Difficulty: $_difficulty'),
              Slider(
                value: _difficulty.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_difficulty',
                onChanged: (value) {
                  setState(() {
                    _difficulty = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
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
