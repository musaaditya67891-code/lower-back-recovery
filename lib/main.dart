import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/session_screen.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(RecoveryApp(controller: controller));
}

class RecoveryApp extends StatelessWidget {
  const RecoveryApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF356B7D);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lower Back Recovery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
      ),
      home: RecoveryShell(controller: controller),
    );
  }
}

class RecoveryShell extends StatefulWidget {
  const RecoveryShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<RecoveryShell> createState() => _RecoveryShellState();
}

class _RecoveryShellState extends State<RecoveryShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.notifications.tappedSession.addListener(_handleNotificationTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationTap());
  }

  @override
  void dispose() {
    widget.controller.notifications.tappedSession.removeListener(_handleNotificationTap);
    super.dispose();
  }

  void _handleNotificationTap() {
    final type = widget.controller.notifications.tappedSession.value;
    if (type == null || !mounted) return;
    widget.controller.notifications.tappedSession.value = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(controller: widget.controller, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pages = [
          HomeScreen(controller: widget.controller),
          HistoryScreen(controller: widget.controller),
          ProgressScreen(controller: widget.controller),
          SettingsScreen(controller: widget.controller),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lower Back Recovery'),
            centerTitle: false,
          ),
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today_rounded),
                  label: 'Today'),
              NavigationDestination(
                  icon: Icon(Icons.history_rounded), label: 'History'),
              NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Progress'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
