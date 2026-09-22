import 'package:flutter/material.dart';

import '../models/recovery_models.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.type,
    required this.record,
    required this.scheduledTime,
    required this.onTap,
  });

  final SessionType type;
  final SessionRecord record;
  final String scheduledTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = record.isCompleted;
    final missed = record.isMissed;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: completed ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: completed
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : type == SessionType.morning
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'Selesai ${_timeOnly(record.completedAt)}'
                          : missed
                              ? 'Terlewat'
                              : 'Mulai $scheduledTime • reminder sampai selesai',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!completed) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String _timeOnly(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
