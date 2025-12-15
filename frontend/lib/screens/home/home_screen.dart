import 'package:flutter/material.dart';
import '../../services/daily_log_service.dart';
import '../../services/routine_service.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Routines',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Daily Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
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
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _routinesFuture = RoutineService.getRoutines();
            _logsFuture = DailyLogService.getDailyLogs();
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Logs
              Text(
                'Recent Daily Logs',
                style: Theme.of(context).textTheme.titleLarge,
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
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No daily logs yet. Create your first one!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  
                  final logs = snapshot.data!.take(3).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineMedium!,
              child: value,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final DailyLog log;

  const _LogCard({required this.log});

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood: ${log.mood}/10 ${_getMoodEmoji(log.mood)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  log.logDate.toString().split(' ')[0],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _IndicatorBadge(
                  icon: Icons.battery_full,
                  value: log.energyLevel,
                  label: 'Energy',
                ),
                _IndicatorBadge(
                  icon: Icons.warning,
                  value: log.stressLevel,
                  label: 'Stress',
                ),
                _IndicatorBadge(
                  icon: Icons.task_alt,
                  value: log.routineEntriesCount,
                  label: 'Routines',
                ),
              ],
            ),
          ],
        ),
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
