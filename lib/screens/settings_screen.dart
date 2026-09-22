import 'package:flutter/material.dart';

import '../models/recovery_models.dart';
import '../services/app_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pick(SessionType type) async {
    final current = widget.controller.settings;
    final initial = type == SessionType.morning
        ? TimeOfDay(hour: current.morningHour, minute: current.morningMinute)
        : TimeOfDay(hour: current.nightHour, minute: current.nightMinute);
    final value = await showTimePicker(context: context, initialTime: initial);
    if (value == null) return;

    final updated = type == SessionType.morning
        ? current.copyWith(
            morningHour: value.hour,
            morningMinute: value.minute,
          )
        : current.copyWith(
            nightHour: value.hour,
            nightMinute: value.minute,
          );
    await widget.controller.updateSettings(updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Morning Recovery'),
                subtitle: const Text('Waktu reminder pertama'),
                trailing: Text(settings.formatTime(SessionType.morning)),
                onTap: () => _pick(SessionType.morning),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Night Recovery'),
                subtitle: const Text('Waktu reminder pertama'),
                trailing: Text(settings.formatTime(SessionType.night)),
                onTap: () => _pick(SessionType.night),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interval reminder',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: settings.reminderIntervalMinutes,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 menit')),
                    DropdownMenuItem(value: 30, child: Text('30 menit')),
                    DropdownMenuItem(value: 60, child: Text('1 jam')),
                    DropdownMenuItem(value: 120, child: Text('2 jam')),
                    DropdownMenuItem(value: 240, child: Text('4 jam')),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.updateSettings(
                      settings.copyWith(reminderIntervalMinutes: value),
                    );
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Reminder untuk sesi tersebut berhenti ketika seluruh sesi disimpan sebagai selesai. Jika tidak diselesaikan, reminder berlanjut sampai akhir hari.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: widget.controller.requestNotificationPermissions,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Minta izin notifikasi lagi'),
        ),
      ],
    );
  }
}
