import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_unavailable_times_screen.dart';
import 'ai_routine_summary_screen.dart';
import '../../services/api_service.dart';

class AiChallengesScreen extends StatefulWidget {
  final String goals;
  final String desiredRoutines;
  final List<String> unavailableTimes;

  const AiChallengesScreen({
    super.key,
    required this.goals,
    required this.desiredRoutines,
    required this.unavailableTimes,
  });

  @override
  State<AiChallengesScreen> createState() => _AiChallengesScreenState();
}

class _AiChallengesScreenState extends State<AiChallengesScreen> {
  final _challengesController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _challengesController.dispose();
    super.dispose();
  }

  Future<void> _generateRoutines() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Collect responses
      final responses = {
        'goals': widget.goals,
        'unavailable_times': widget.unavailableTimes.join(', '),
        'challenges': _challengesController.text.trim(),
        if (widget.desiredRoutines.isNotEmpty)
          'desired_routines': widget.desiredRoutines,
      };

      // Call backend to generate routines
      final resp = await ApiService.post('/routines/generate-ai', responses);
      final summary = (resp['summary'] ?? '').toString();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AiRoutineSummaryScreen(summary: summary)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routines generated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        const Text(
                          'What challenges\ndo you face?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Subtitle
                        Text(
                          'Help us understand what holds you back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Challenges Input
                        TextField(
                          controller: _challengesController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'e.g., Lack of motivation, time constraints, staying consistent...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
                            ),
                          ),
                        ),
                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isGenerating ? null : _generateRoutines,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Generate My Routines',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isGenerating ? null : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => AiUnavailableTimesScreen(
                            goals: widget.goals,
                            desiredRoutines: widget.desiredRoutines,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
