import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../onboarding/routine_setup_choice_screen.dart';

class MentorSetupScreen extends StatefulWidget {
  const MentorSetupScreen({super.key});

  @override
  State<MentorSetupScreen> createState() => _MentorSetupScreenState();
}

class _MentorSetupScreenState extends State<MentorSetupScreen> {
  String _mentorStyle = 'balanced';
  int _mentorIntensity = 5;
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await AuthService().updateProfile(
        mentorStyle: _mentorStyle,
        mentorIntensity: _mentorIntensity,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoutineSetupChoiceScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentor configured!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Mentor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's set up how your mentor should behave.",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mentor Style',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: _mentorStyle,
                        isExpanded: true,
                        items: ['strict', 'gentle', 'balanced', 'hilarious']
                            .map((style) => DropdownMenuItem(
                                  value: style,
                                  child: Text(_capitalize(style)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _mentorStyle = value ?? 'balanced';
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mentor Intensity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _mentorIntensity.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _mentorIntensity.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _mentorIntensity = value.toInt();
                                });
                              },
                            ),
                          ),
                          Text(
                            _mentorIntensity.toString(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save and Continue'),
                ),
              ),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const RoutineSetupChoiceScreen()),
                        );
                      },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
