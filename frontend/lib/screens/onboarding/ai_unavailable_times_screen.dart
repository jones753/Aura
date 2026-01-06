import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_challenges_screen.dart';
import 'ai_desired_routines_screen.dart';

class AiUnavailableTimesScreen extends StatefulWidget {
  final String goals;
  final String desiredRoutines;

  const AiUnavailableTimesScreen({
    super.key,
    required this.goals,
    required this.desiredRoutines,
  });

  @override
  State<AiUnavailableTimesScreen> createState() => _AiUnavailableTimesScreenState();
}

class _AiUnavailableTimesScreenState extends State<AiUnavailableTimesScreen> {
  final List<String> _unavailableTimeSlots = [];

  final List<String> _timeSlots = [
    '5-7 AM', '7-9 AM', '9-11 AM', '11 AM-1 PM',
    '1-3 PM', '3-5 PM', '5-7 PM', '7-9 PM', '9-11 PM'
  ];

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiChallengesScreen(
          goals: widget.goals,
          desiredRoutines: widget.desiredRoutines,
          unavailableTimes: _unavailableTimeSlots,
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
                          'What time are you\nnot available?',
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
                          'Select time slots when you cannot do routines',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Time Slots
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _timeSlots.map((slot) {
                            final isSelected = _unavailableTimeSlots.contains(slot);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _unavailableTimeSlots.remove(slot);
                                  } else {
                                    _unavailableTimeSlots.add(slot);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0A84FF)
                                      : Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0A84FF)
                                        : Colors.white.withOpacity(0.2),
                                    width: isSelected ? 0 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 48),
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
                        MaterialPageRoute(
                          builder: (_) => AiDesiredRoutinesScreen(
                            goals: widget.goals,
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
