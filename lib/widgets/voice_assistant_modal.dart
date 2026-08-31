import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../l10n/strings.dart';
import '../services/voice_assistant_service.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

enum _ViewState { recording, processing, response, error }

/// Bottom sheet for the Help screen voice assistant:
/// records a question, asks Gemini and reads the answer aloud.
class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  static const _maxRecordingSeconds = 60;

  final VoiceAssistantService _service = VoiceAssistantService();

  _ViewState _state = _ViewState.recording;
  VoiceAssistantError _error = VoiceAssistantError.generic;
  String? _answer;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Timer? _tickTimer;
  Timer? _levelTimer;
  int _elapsedSeconds = 0;
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _levelTimer?.cancel();
    _pulse.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _state = _ViewState.recording;
      _elapsedSeconds = 0;
      _level = 0;
      _answer = null;
    });

    try {
      await _service.startRecording();
    } on VoiceAssistantError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _state = _ViewState.error;
      });
      return;
    }

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
      if (_elapsedSeconds >= _maxRecordingSeconds) _stopAndSubmit();
    });
    _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final level = await _service.getMicLevel();
      if (!mounted) return;
      setState(() => _level = level);
    });
  }

  Future<void> _stopAndSubmit() async {
    if (_state != _ViewState.recording) return;
    _tickTimer?.cancel();
    _levelTimer?.cancel();
    setState(() => _state = _ViewState.processing);

    try {
      final answer = await _service.stopRecordingAndAsk();
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _state = _ViewState.response;
      });
      // Read the answer aloud right away — the button can replay or pause it.
      final app = context.read<AppState>();
      await _service.speak(answer, language: app.language);
    } on VoiceAssistantError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _state = _ViewState.error;
      });
    }
  }

  Future<void> _retry() async {
    await _service.stopSpeaking();
    await _startRecording();
  }

  Future<void> _close() async {
    await _service.stopSpeaking();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleTts() async {
    final app = context.read<AppState>();
    if (_service.isSpeaking.value) {
      await _service.pauseSpeaking();
    } else {
      await _service.speak(_answer!, language: app.language);
    }
  }

  String get _timerLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _errorMessage(DashboardStrings s) {
    return switch (_error) {
      VoiceAssistantError.micPermission => s.voiceErrorMic,
      VoiceAssistantError.network => s.voiceErrorNetwork,
      _ => s.voiceErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.ink800 : Colors.white;
    final textColor = dark ? Colors.white : AppColors.ink900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
          boxShadow: kLiftShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink700 : AppColors.ink200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.saffron600, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.voiceHelpTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
              ),
              _CloseButton(onTap: _close, dark: dark),
            ]),
            const SizedBox(height: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: switch (_state) {
                _ViewState.recording => _buildRecording(s, textColor),
                _ViewState.processing => _buildProcessing(s, textColor),
                _ViewState.response => _buildResponse(s, dark, textColor),
                _ViewState.error => _buildError(s, dark, textColor),
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Recording view: pulsing mic ring, live bars + timer, stop button ---

  Widget _buildRecording(DashboardStrings s, Color textColor) {
    return Column(children: [
      SizedBox(
        width: 168, height: 168,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = _pulse.value;
            return Stack(alignment: Alignment.center, children: [
              Container(
                width: 120 + 44 * t, height: 120 + 44 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.saffron600.withAlpha((120 * (1 - t)).round()),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.saffron600, shape: BoxShape.circle,
                  boxShadow: kLiftShadow,
                ),
                child: const Icon(Icons.mic_rounded, size: 52, color: Colors.white),
              ),
            ]);
          },
        ),
      ),
      const SizedBox(height: 16),
      Text(s.listeningStatus,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
      const SizedBox(height: 16),
      _Waveform(level: _level),
      const SizedBox(height: 8),
      Text(_timerLabel,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink500)),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: s.voiceStopSubmit,
        icon: Icons.stop_rounded,
        onTap: _stopAndSubmit,
      ),
    ]);
  }

  // --- Processing view ---

  Widget _buildProcessing(DashboardStrings s, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: AppColors.saffron600, shape: BoxShape.circle, boxShadow: kLiftShadow,
          ),
          child: const Padding(
            padding: EdgeInsets.all(34),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
          ),
        ),
        const SizedBox(height: 24),
        Text(s.processingStatus,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
      ]),
    );
  }

  // --- Response view: written answer + play/pause + close ---

  Widget _buildResponse(DashboardStrings s, bool dark, Color textColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: dark ? AppColors.saffron600.withAlpha(40) : AppColors.saffron50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.saffron600, width: 2),
          ),
          child: const Icon(Icons.auto_awesome_rounded, size: 22, color: AppColors.saffron600),
        ),
        const SizedBox(width: 12),
        Text(s.voiceAnswerTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
      ]),
      const SizedBox(height: 12),
      Container(
        constraints: const BoxConstraints(maxHeight: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.ink900 : AppColors.saffron50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron200),
        ),
        child: SingleChildScrollView(
          child: Text(_answer!,
            style: TextStyle(fontSize: 16, height: 1.6, color: dark ? Colors.white : AppColors.ink900)),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([_service.isSpeaking, _service.ttsPaused]),
            builder: (context, _) {
              final speaking = _service.isSpeaking.value;
              return _PrimaryButton(
                label: speaking ? s.voicePause : s.voicePlay,
                icon: speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onTap: speaking ? () => _service.pauseSpeaking() : _toggleTts,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        _SecondaryButton(label: s.voiceTryAgain, onTap: _retry),
      ]),
      const SizedBox(height: 12),
    ]);
  }

  // --- Error view ---

  Widget _buildError(DashboardStrings s, bool dark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: AppColors.red500.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red500),
        ),
        const SizedBox(height: 16),
        Text(_errorMessage(s), textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 20),
        _PrimaryButton(label: s.voiceTryAgain, icon: Icons.refresh_rounded, onTap: _retry),
        const SizedBox(height: 8),
      ]),
    );
  }
}

/// Simple live waveform: five bars driven by the mic amplitude.
class _Waveform extends StatelessWidget {
  final double level;

  const _Waveform({required this.level});

  @override
  Widget build(BuildContext context) {
    const multipliers = [0.5, 0.85, 1.0, 0.75, 0.45];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in multipliers)
          Container(
            width: 8,
            height: (12 + 34 * level * m).clamp(10, 46).toDouble(),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.saffron600.withAlpha(120 + (135 * level).round()),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.saffron600,
            borderRadius: BorderRadius.circular(999),
            boxShadow: kLiftShadow,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: dark ? Colors.white : AppColors.ink900,
              )),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool dark;

  const _CloseButton({required this.onTap, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
          ),
          child: Icon(Icons.close_rounded, size: 22,
            color: dark ? Colors.white : AppColors.ink900),
        ),
      ),
    );
  }
}
