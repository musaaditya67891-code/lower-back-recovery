import 'package:flutter/material.dart';

import '../models/recovery_models.dart';
import '../services/app_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionRecord>>(
      future: widget.controller.database.recentSessions(limit: 120),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('Belum ada history.'));
        }
        final grouped = <String, List<SessionRecord>>{};
        for (final row in rows) {
          grouped.putIfAbsent(row.dateKey, () => []).add(row);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
          children: [
            Text('History', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            for (final entry in grouped.entries) ...[
              Text(_prettyDate(entry.key),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      _row(entry.value[i]),
                      if (i != entry.value.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _row(SessionRecord row) {
    final icon = row.isCompleted
        ? Icons.check_circle_rounded
        : row.isMissed
            ? Icons.cancel_outlined
            : Icons.schedule_rounded;
    return ListTile(
      leading: Icon(icon),
      title: Text(row.type.shortLabel),
      subtitle: Text(row.isCompleted
          ? 'Pain ${row.painBefore ?? '-'} → ${row.painAfter ?? '-'} • ${_symptom(row.legSymptom)}'
          : row.isMissed
              ? 'Missed'
              : 'Pending'),
      trailing: row.isCompleted
          ? Text('${row.leftReps}/${row.rightReps}',
              style: Theme.of(context).textTheme.labelMedium)
          : null,
    );
  }

  String _symptom(String? value) => switch (value) {
        'better' => 'membaik',
        'worse' => 'memburuk',
        _ => 'sama',
      };

  String _prettyDate(String key) {
    final parts = key.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
