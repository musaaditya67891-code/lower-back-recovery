import 'package:flutter/material.dart';

import '../models/recovery_models.dart';
import '../services/app_controller.dart';
import '../services/recovery_repository.dart';
import '../widgets/session_card.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<SessionRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final key = RecoveryRepository.dateKey(DateTime.now());
    _future = Future.wait([
      widget.controller.database.getSession(key, SessionType.morning),
      widget.controller.database.getSession(key, SessionType.night),
    ]).then((items) => items.whereType<SessionRecord>().toList());
  }

  Future<void> _open(SessionType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionScreen(controller: widget.controller, type: type),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionRecord>>(
      future: _future,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        final completed = sessions.where((e) => e.isCompleted).length;
        return RefreshIndicator(
          onRefresh: () async {
            await widget.controller.repository
                .reconcileHistory(widget.controller.settings);
            setState(_reload);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
            children: [
              Text('Phase 1 — Reduce',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 6),
              Text('Recovery hari ini',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('$completed / 2 sesi selesai',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              LinearProgressIndicator(value: completed / 2),
              const SizedBox(height: 24),
              for (final type in SessionType.values) ...[
                if (sessions.any((e) => e.type == type))
                  SessionCard(
                    type: type,
                    record: sessions.firstWhere((e) => e.type == type),
                    scheduledTime: widget.controller.settings.formatTime(type),
                    onTap: () => _open(type),
                  ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cara reminder bekerja',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Pagi dan malam berdiri sendiri. Setelah waktu mulai tercapai, aplikasi akan mengingatkan lagi sesuai interval sampai sesi tersebut diselesaikan. Hari baru mereset task; sesi yang tidak selesai masuk History sebagai missed.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
