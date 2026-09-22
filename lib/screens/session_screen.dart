import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recovery_models.dart';
import '../services/app_controller.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.controller,
    required this.type,
  });

  final AppController controller;
  final SessionType type;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _step = 0;
  int _painBefore = 5;
  int _painAfter = 5;
  int _breathingSeconds = 300;
  Timer? _timer;
  bool _breathingDone = false;
  String _extensionLevel = 'Elbow';
  int _extensionReps = 0;
  bool _extensionDone = false;
  int _left = 0;
  int _right = 0;
  String _symptom = 'same';
  bool _saving = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer?.isActive == true || _breathingSeconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _breathingSeconds--;
        if (_breathingSeconds <= 0) {
          _breathingDone = true;
          timer.cancel();
        }
      });
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {});
  }

  Future<void> _openSource(int seconds) async {
    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=EuaSU-8OfUc&t=$seconds',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _painBeforeStep();
      case 1:
        return _breathingStep();
      case 2:
        return _extensionStep();
      case 3:
        return _legLiftStep();
      default:
        return _finishStep();
    }
  }

  Widget _header(String eyebrow, String title, String subtitle) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _painBeforeStep() {
    return Column(
      key: const ValueKey('before'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Check-in', 'Sebelum mulai',
            'Catat rasa nyeri sekarang untuk melihat tren, bukan untuk diagnosis.'),
        _painSelector(_painBefore, (v) => setState(() => _painBefore = v)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await widget.controller.repository.startSession(
              widget.type,
              painBefore: _painBefore,
            );
            if (mounted) setState(() => _step = 1);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Mulai recovery'),
        ),
      ],
    );
  }

  Widget _breathingStep() {
    final min = _breathingSeconds ~/ 60;
    final sec = _breathingSeconds % 60;
    return Column(
      key: const ValueKey('breathing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('1 dari 3', '90-90 Breathing',
            'Telentang, pinggul dan lutut sekitar 90°. Satu tangan di perut, satu di dada. Bernapas melalui perut secara 360° dan biarkan lower back rileks.'),
        _tutorialButton(155),
        const SizedBox(height: 22),
        Center(
          child: Text(
            '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _timer?.isActive == true ? _pauseTimer : _startTimer,
                child: Text(_timer?.isActive == true ? 'Pause' : 'Start timer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() {
                  _breathingDone = true;
                  _timer?.cancel();
                }),
                child: const Text('Tandai selesai'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.tonal(
          onPressed: _breathingDone ? () => setState(() => _step = 2) : null,
          child: const Text('Lanjut'),
        ),
      ],
    );
  }

  Widget _extensionStep() {
    return Column(
      key: const ValueKey('extension'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('2 dari 3', 'Prone Extension',
            'Mulai tengkurap dengan tumpuan siku. Lower back dan glute tetap rileks. Progress ke hand press-up hanya jika terasa sesuai.'),
        _tutorialButton(231),
        const SizedBox(height: 18),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Elbow', label: Text('Elbow')),
            ButtonSegment(value: 'Hand press-up', label: Text('Hand press-up')),
          ],
          selected: {_extensionLevel},
          onSelectionChanged: (v) => setState(() => _extensionLevel = v.first),
        ),
        const SizedBox(height: 22),
        _counter(
          label: 'Repetisi (tanpa target wajib)',
          value: _extensionReps,
          onMinus: () => setState(
              () => _extensionReps = (_extensionReps - 1).clamp(0, 999).toInt()),
          onPlus: () => setState(() => _extensionReps++),
        ),
        const SizedBox(height: 18),
        Text('Respons gejala kaki', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'better', label: Text('Membaik')),
            ButtonSegment(value: 'same', label: Text('Sama')),
            ButtonSegment(value: 'worse', label: Text('Memburuk')),
          ],
          selected: {_symptom},
          onSelectionChanged: (v) => setState(() => _symptom = v.first),
        ),
        if (_symptom == 'worse') ...[
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'Jangan memaksa range. Jika gejala menjalar atau kelemahan/mati rasa bertambah, hentikan latihan dan evaluasi secara profesional.'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => setState(() => _extensionDone = true),
          child: Text(_extensionDone ? 'Selesai ✓' : 'Tandai selesai'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: _extensionDone ? () => setState(() => _step = 3) : null,
          child: const Text('Lanjut'),
        ),
      ],
    );
  }

  Widget _legLiftStep() {
    final ready = _left >= 20 && _right >= 20;
    return Column(
      key: const ValueKey('leglift'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('3 dari 3', 'Bracing Leg Lift',
            'Telentang, lutut ditekuk dan kaki menapak. Tekan lower back lembut ke lantai, pertahankan abdominal pressure, lalu angkat kaki bergantian.'),
        _tutorialButton(319),
        const SizedBox(height: 22),
        _counter(
          label: 'Kiri — target 20',
          value: _left,
          onMinus: () => setState(() => _left = (_left - 1).clamp(0, 999).toInt()),
          onPlus: () => setState(() => _left++),
        ),
        const SizedBox(height: 16),
        _counter(
          label: 'Kanan — target 20',
          value: _right,
          onMinus: () => setState(() => _right = (_right - 1).clamp(0, 999).toInt()),
          onPlus: () => setState(() => _right++),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: ready ? () => setState(() => _step = 4) : null,
          child: Text(ready ? 'Selesaikan sesi' : 'Capai 20/20 untuk lanjut'),
        ),
      ],
    );
  }

  Widget _finishStep() {
    return Column(
      key: const ValueKey('finish'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Check-out', 'Setelah recovery',
            'Catat kondisi setelah sesi. History dan grafik akan memakai data ini.'),
        _painSelector(_painAfter, (v) => setState(() => _painAfter = v)),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan & hentikan reminder'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.controller.completeSession(
      type: widget.type,
      painBefore: _painBefore,
      painAfter: _painAfter,
      legSymptom: _symptom,
      breathingDuration: 300 - _breathingSeconds,
      extensionLevel: _extensionLevel,
      extensionReps: _extensionReps,
      leftReps: _left,
      rightReps: _right,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _painSelector(int value, ValueChanged<int> onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text('$value / 10', style: Theme.of(context).textTheme.headlineMedium),
            Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0 • tidak nyeri'), Text('10 • sangat berat')],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counter({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
            SizedBox(
              width: 44,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
    );
  }

  Widget _tutorialButton(int seconds) {
    return OutlinedButton.icon(
      onPressed: () => _openSource(seconds),
      icon: const Icon(Icons.play_circle_outline_rounded),
      label: const Text('Lihat tutorial sumber pada timestamp gerakan'),
    );
  }
}
