import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_unavailable_times_screen.dart';
import 'ai_goals_screen.dart';

class AiDesiredRoutinesScreen extends StatefulWidget {
  final String goals;

  const AiDesiredRoutinesScreen({
    super.key,
    required this.goals,
  });

  @override
  State<AiDesiredRoutinesScreen> createState() => _AiDesiredRoutinesScreenState();
}

class _AiDesiredRoutinesScreenState extends State<AiDesiredRoutinesScreen> {
  final _routinesController = TextEditingController();

  @override
  void dispose() {
    _routinesController.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiUnavailableTimesScreen(
          goals: widget.goals,
          desiredRoutines: _routinesController.text.trim(),
        ),
      ),
    );
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiUnavailableTimesScreen(
          goals: widget.goals,
          desiredRoutines: '',
        ),
      ),
    );
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
                          'What kind of routines\ndo you wish for?',
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
                          'This is optional. We\'ll tailor suggestions based on your goals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Routines Input
                        TextField(
                          controller: _routinesController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'e.g., Strength training, language learning, mindfulness, time blocking',
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
                        const SizedBox(height: 32),
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Skip Button
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.6),
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
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AiGoalsScreen()),
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
