import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../services/onboarding_service.dart';

class _WelcomePageData {
  final String title;
  final String subtitle;
  final bool isFinal;

  const _WelcomePageData({
    required this.title,
    required this.subtitle,
    this.isFinal = false,
  });
}

class WelcomeScreen extends StatefulWidget {
  final int initialPage;

  const WelcomeScreen({super.key, this.initialPage = 0});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  static const List<_WelcomePageData> _pages = [
    _WelcomePageData(
      title: 'Welcome to\nAura',
      subtitle: 'Your personal guide to daily growth',
    ),
    _WelcomePageData(
      title: 'Your Personal\nGrowth Journey',
      subtitle:
          'Track habits, set goals, and receive personalized guidance tailored to you',
    ),
    _WelcomePageData(
      title: 'Ready to\nGet Started?',
      subtitle: 'Join thousands building better habits every day',
      isFinal: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Set current page from widget parameter
    _currentPage = widget.initialPage;

    // Create controllers for each page
    _controllers = List.generate(
      _pages.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    // Create fade animations (0.0 to 1.0)
    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );
    }).toList();

    // Create scale animations (0.85 to 1.0 for subtle effect)
    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
        ),
      );
    }).toList();

    // Start initial page animation
    _controllers[_currentPage].forward();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      // Fade out current page
      _controllers[_currentPage].reverse().then((_) {
        setState(() {
          _currentPage++;
        });
        // Fade in next page
        _controllers[_currentPage].forward();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      // Fade out current page
      _controllers[_currentPage].reverse().then((_) {
        setState(() {
          _currentPage--;
        });
        // Fade in previous page
        _controllers[_currentPage].forward();
      });
    }
  }

  void _navigateToAuth({required bool isLogin}) async {
    // Mark onboarding as complete
    await OnboardingService.setWelcomeCompleted();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              isLogin ? const LoginScreen() : const RegisterScreen(),
        ),
      );
    }
  }

  Widget _buildAnimatedContent(int pageIndex) {
    final page = _pages[pageIndex];

    return AnimatedBuilder(
      animation: _controllers[pageIndex],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[pageIndex].value,
          child: Transform.scale(
            scale: _scaleAnimations[pageIndex].value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      children: [
        // Primary: Create Account
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _navigateToAuth(isLogin: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary: Sign In
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _navigateToAuth(isLogin: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

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
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Main content area (tappable for non-final pages)
                Expanded(
                  child: GestureDetector(
                    onTap: page.isFinal ? null : _goToNextPage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAnimatedContent(_currentPage),
                    ),
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF007AFF)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Action buttons (only for final page)
                if (page.isFinal) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildFinalButtons(),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),

            // Back button (only show if not on first page)
            if (_currentPage > 0)
              Positioned(
                top: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToPreviousPage,
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
