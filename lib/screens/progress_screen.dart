import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/recovery_models.dart';
import '../services/app_controller.dart';
import '../services/recovery_repository.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int days = 14;

  Future<List<SessionRecord>> _load() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    return widget.controller.database.sessionsBetween(
      RecoveryRepository.dateKey(start),
      RecoveryRepository.dateKey(now),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionRecord>>(
      future: _load(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        final completed = rows.where((e) => e.isCompleted).toList();
        final totalExpected = rows.length;
        final adherence = totalExpected == 0
            ? 0
            : ((completed.length / totalExpected) * 100).round();
        final before = completed
            .where((e) => e.painBefore != null)
            .map((e) => e.painBefore!)
            .toList();
        final after = completed
            .where((e) => e.painAfter != null)
            .map((e) => e.painAfter!)
            .toList();
        final avgBefore = before.isEmpty
            ? null
            : before.reduce((a, b) => a + b) / before.length;
        final avgAfter = after.isEmpty
            ? null
            : after.reduce((a, b) => a + b) / after.length;
        final better = completed.where((e) => e.legSymptom == 'better').length;
        final same = completed.where((e) => e.legSymptom == 'same').length;
        final worse = completed.where((e) => e.legSymptom == 'worse').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Progress',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                DropdownButton<int>(
                  value: days,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 hari')),
                    DropdownMenuItem(value: 14, child: Text('14 hari')),
                    DropdownMenuItem(value: 30, child: Text('30 hari')),
                  ],
                  onChanged: (v) => setState(() => days = v ?? 14),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _metric('Adherence', '$adherence%')),
                const SizedBox(width: 10),
                Expanded(child: _metric('Sesi', '${completed.length}/$totalExpected')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _metric('Pain awal',
                        avgBefore == null ? '—' : avgBefore.toStringAsFixed(1))),
                const SizedBox(width: 10),
                Expanded(
                    child: _metric('Pain akhir',
                        avgAfter == null ? '—' : avgAfter.toStringAsFixed(1))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Pain trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Setiap titik = satu sesi selesai. Garis menunjukkan pain sebelum dan sesudah.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(height: 240, child: _chart(completed)),
            const SizedBox(height: 24),
            Text('Respons gejala', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _smallStat('Membaik', better),
                    _smallStat('Sama', same),
                    _smallStat('Memburuk', worse),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metric(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );

  Widget _smallStat(String label, int value) => Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _chart(List<SessionRecord> completed) {
    if (completed.isEmpty) {
      return const Card(child: Center(child: Text('Belum cukup data.')));
    }
    final ordered = [...completed]..sort((a, b) {
        final aKey = '${a.dateKey}${a.type.key}';
        final bKey = '${b.dateKey}${b.type.key}';
        return aKey.compareTo(bKey);
      });

    final before = <FlSpot>[];
    final after = <FlSpot>[];
    for (var i = 0; i < ordered.length; i++) {
      final row = ordered[i];
      if (row.painBefore != null) before.add(FlSpot(i.toDouble(), row.painBefore!.toDouble()));
      if (row.painAfter != null) after.add(FlSpot(i.toDouble(), row.painAfter!.toDouble()));
    }

    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.tertiary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 18, 10),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 10,
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 2),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: before,
                isCurved: true,
                color: primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: after,
                isCurved: true,
                color: secondary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
