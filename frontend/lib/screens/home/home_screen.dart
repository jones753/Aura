import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/daily_log_service.dart';
import '../../services/routine_service.dart';
import '../../services/theme_service.dart';
import '../../services/feedback_service.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'routines_screen.dart';
import 'daily_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardTab(),
      const RoutinesScreen(),
      const DailyLogScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF2F2F7)
                  : const Color(0xFF3A3A3C),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.house_outlined),
                selectedIcon: Icon(Icons.house),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Routines',
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: 'Daily Log',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with SingleTickerProviderStateMixin {
  late Future<List<Routine>> _routinesFuture;
  late Future<List<DailyLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _routinesFuture = RoutineService.getRoutines();
    _logsFuture = DailyLogService.getDailyLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Mentor'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                _logout();
              } else if (value == 'light') {
                await ThemeService.setMode(ThemeMode.light);
              } else if (value == 'dark') {
                await ThemeService.setMode(ThemeMode.dark);
              } else if (value == 'system') {
                await ThemeService.setMode(ThemeMode.system);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'light',
                child: Text('Light theme'),
              ),
              const PopupMenuItem(
                value: 'dark',
                child: Text('Dark theme'),
              ),
              const PopupMenuItem(
                value: 'system',
                child: Text('Use system theme'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.microtask(() {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _routinesFuture = RoutineService.getRoutines();
                  _logsFuture = DailyLogService.getDailyLogs();
                });
              }
            });
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient Hero Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26007AFF),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep Building Your Habits 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your consistency matters. Every habit completed brings you closer to your goals.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Routines',
                      value: FutureBuilder<List<Routine>>(
                        future: _routinesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(snapshot.data!.length.toString());
                          }
                          return const Text('-');
                        },
                      ),
                      icon: Icons.checklist,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Daily Logs',
                      value: FutureBuilder<List<DailyLog>>(
                        future: _logsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(snapshot.data!.length.toString());
                          }
                          return const Text('-');
                        },
                      ),
                      icon: Icons.book,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // Best Streaks
              Text(
                'Top Streaks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Routine>>(
                future: _routinesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final routines = snapshot.data!;
                  final routinesWithStreaks = routines
                      .where((r) => r.currentStreak > 0)
                      .toList()
                      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

                  if (routinesWithStreaks.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFFF2F2F7)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 12),
                          Text(
                            'Start your first streak',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routinesWithStreaks.take(3).length,
                    itemBuilder: (context, index) {
                      final routine = routinesWithStreaks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFFF2F2F7)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routine.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Best: ${routine.longestStreak} days',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${routine.currentStreak}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF9500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 28),
              
              // Recent Logs Section
              Text(
                'Recent Daily Logs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<DailyLog>>(
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
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFFF2F2F7)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 32,
                            color: const Color(0xFF8E8E93),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No daily logs yet',
                            style: TextStyle(
                              color: const Color(0xFF8E8E93),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final logs = snapshot.data!.take(3).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _LogCard(log: log);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // You'll need to import auth_service
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            child: value,
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final DailyLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    // Combine highlights and challenges into one feedback message
    final feedbackText = [
      if (log.highlights.isNotEmpty) log.highlights,
      if (log.challenges.isNotEmpty) log.challenges,
    ].join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5856D6).withOpacity(0.15),
            const Color(0xFF5856D6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🤖 Mentor Feedback',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5856D6),
                ),
              ),
              Text(
                log.logDate.toString().split(' ')[0],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          if (feedbackText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              feedbackText,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF1C1C1E),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'No feedback generated yet',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IndicatorBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _IndicatorBadge({
    required this.icon,
    required this.value,
    required this.label,
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
