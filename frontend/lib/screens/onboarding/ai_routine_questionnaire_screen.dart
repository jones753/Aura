import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ai_routine_summary_screen.dart';

class AiRoutineQuestionnaireScreen extends StatefulWidget {
  const AiRoutineQuestionnaireScreen({super.key});

  @override
  State<AiRoutineQuestionnaireScreen> createState() => _AiRoutineQuestionnaireScreenState();
}

class _AiRoutineQuestionnaireScreenState extends State<AiRoutineQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();
  final _wishController = TextEditingController();
  final _challengesController = TextEditingController();
  
  final List<String> _unavailableTimeSlots = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _goalsController.dispose();
    _wishController.dispose();
    _challengesController.dispose();
    super.dispose();
  }
  
  List<Widget> _buildTimeSlots() {
    final timeSlots = [
      '5-7 AM', '7-9 AM', '9-11 AM', '11 AM-1 PM',
      '1-3 PM', '3-5 PM', '5-7 PM', '7-9 PM', '9-11 PM'
    ];
    
    return timeSlots.map((slot) {
      final isSelected = _unavailableTimeSlots.contains(slot);
      return FilterChip(
        label: Text(slot),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _unavailableTimeSlots.add(slot);
            } else {
              _unavailableTimeSlots.remove(slot);
            }
          });
        },
      );
    }).toList();
  }

  Future<void> _generateRoutines() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      // Collect responses
      final responses = {
        'goals': _goalsController.text,
        'unavailable_times': _unavailableTimeSlots.join(', '),
        'challenges': _challengesController.text,
        if (_wishController.text.trim().isNotEmpty)
          'desired_routines': _wishController.text.trim(),
      };

      // Call backend to generate routines
      final resp = await ApiService.post('/routines/generate-ai', responses);
      final summary = (resp['summary'] ?? '').toString();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AiRoutineSummaryScreen(summary: summary)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routines generated successfully!')),
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
        setState(() => _isGenerating = false);
      }
    }
  }

  // Backend handles generation; no local defaults needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Routine Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Help us create the perfect routines for you',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // Goals
              TextFormField(
                controller: _goalsController,
                decoration: const InputDecoration(
                  labelText: 'Where do you see yourself in 5 years?',
                  hintText: 'Dream big. Describe your ideal life, achievements, and the person you want to become.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please share your vision';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Desired routine types (optional)
              Text(
                'What kind of routines do you wish for? (optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _wishController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Strength training, language learning, mindfulness, time blocking',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Unavailable Time Slots
              Text(
                'What time are you not available?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select time slots when you cannot do routines',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildTimeSlots(),
              ),
              const SizedBox(height: 24),
              
              // Challenges
              TextFormField(
                controller: _challengesController,
                decoration: const InputDecoration(
                  labelText: 'What challenges do you face?',
                  hintText: 'e.g., Lack of motivation, time constraints',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateRoutines,
                  child: _isGenerating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate My Routines'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
