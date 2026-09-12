import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../l10n/strings.dart';
import '../models/product.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../services/gemini_service.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import 'success_feedback_widgets.dart';

enum _EditState { idle, recording, processing, success, error }

/// Bottom sheet modal allowing artisans to update product details by voice.
class EditVoiceInfoModal extends StatefulWidget {
  final Product product;

  const EditVoiceInfoModal({super.key, required this.product});

  @override
  State<EditVoiceInfoModal> createState() => _EditVoiceInfoModalState();
}

class _EditVoiceInfoModalState extends State<EditVoiceInfoModal>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  _EditState _state = _EditState.idle;
  String? _errorMessage;
  String? _successSummary;
  Product? _updatedProduct;

  Timer? _timer;
  Timer? _levelTimer;
  int _seconds = 0;
  double _micLevel = 0.0;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _pulseController.repeat(reverse: true);
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _levelTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _state = _EditState.error;
          _errorMessage = 'Microphone permission denied.';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/edit_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      setState(() {
        _state = _EditState.recording;
        _seconds = 0;
        _micLevel = 0.0;
        _errorMessage = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= 45) _stopAndProcess();
      });

      _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        try {
          final amp = await _recorder.getAmplitude();
          if (!mounted) return;
          final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0).toDouble();
          setState(() => _micLevel = normalized);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Could not start recording: $e');
      setState(() {
        _state = _EditState.error;
        _errorMessage = 'Something went wrong. / कुछ गलत हो गया।';
      });
    }
  }

  Future<void> _stopAndProcess() async {
    if (_state != _EditState.recording) return;
    _timer?.cancel();
    _levelTimer?.cancel();

    final appLang = context.read<AppState>().language;
    final dataProvider = context.read<DataProvider>();

    setState(() => _state = _EditState.processing);

    try {
      final path = await _recorder.stop();

      if (path == null) {
        setState(() {
          _state = _EditState.error;
          _errorMessage = 'No audio recorded.';
        });
        return;
      }

      final file = File(path);
      if (!await file.exists() || (await file.length()) == 0) {
        setState(() {
          _state = _EditState.error;
          _errorMessage = 'Audio file was empty.';
        });
        return;
      }

      // Send to Gemini Vision/Audio Processing
      final parsed = await GeminiService.processVoiceProductEdit(
        audioFile: file,
        currentProduct: widget.product,
        language: appLang,
      );

      // Clean up temp audio file
      try {
        await file.delete();
      } catch (_) {}

      final newNameEn = parsed['name_en'] as String? ?? widget.product.nameEn;
      final newNameHi = parsed['name_hi'] as String? ?? widget.product.nameHi;
      final newPrice = (parsed['price_in_rupees'] as num?)?.toInt() ?? widget.product.priceInRupees;
      final newDesc = parsed['description'] as String? ?? widget.product.description;
      final newCategory = parsed['category'] as String? ?? widget.product.category;

      final summaryEn = parsed['summary_en'] as String? ?? 'Product updated to ₹$newPrice';
      final summaryHi = parsed['summary_hi'] as String? ?? 'उत्पाद की जानकारी अपडेट कर दी गई है';
      final summaryLocalized = parsed['summary_localized'] as String? ??
          (appLang == Language.hi ? summaryHi : summaryEn);

      final spokenText = appLang == Language.en
          ? summaryEn
          : (appLang == Language.hi ? summaryHi : summaryLocalized);

      final updated = widget.product.copyWith(
        nameEn: newNameEn,
        nameHi: newNameHi,
        priceInRupees: newPrice,
        description: newDesc,
        category: newCategory,
        status: ProductStatus.live,
      );

      // Save to SQLite & Supabase
      await dataProvider.updateProduct(updated);

      if (!mounted) return;

      setState(() {
        _state = _EditState.success;
        _updatedProduct = updated;
        _successSummary = spokenText;
      });

      // Announce confirmation aloud via TTS
      _speakConfirmation(spokenText, appLang);
    } catch (e) {
      debugPrint('Edit voice info error: $e');
      if (!mounted) return;
      final errStr = e.toString();
      final String message;
      if (errStr.contains('429') ||
          errStr.toLowerCase().contains('quota exceeded') ||
          errStr.contains('RESOURCE_EXHAUSTED')) {
        message =
            'Server is currently busy. Please wait a minute and try again. / सर्वर अभी व्यस्त है। कृपया 1 मिनट बाद पुनः प्रयास करें।';
      } else {
        message = 'Something went wrong. / कुछ गलत हो गया।';
      }

      setState(() {
        _state = _EditState.error;
        _errorMessage = message;
      });
    }
  }

  Future<void> _speakConfirmation(String text, Language language) async {
    try {
      await _tts.stop();
      // Explicitly set language to active language's localeCode with safe fallback
      try {
        await _tts.setLanguage(language.localeCode);
      } catch (e) {
        debugPrint('⚠️ TTS setLanguage(${language.localeCode}) failed, falling back to en-IN: $e');
        try {
          await _tts.setLanguage('en-IN');
        } catch (_) {}
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Widget _buildProductThumbnail(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(image, fit: BoxFit.cover);
    } else if (image.startsWith('assets/')) {
      return Image.asset(image, fit: BoxFit.cover);
    } else if (image.isNotEmpty && File(image).existsSync()) {
      return Image.file(File(image), fit: BoxFit.cover);
    } else {
      return Container(
        color: AppColors.saffron50,
        child: const Icon(Icons.inventory_2_rounded, color: AppColors.saffron600),
      );
    }
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isHi = app.language == Language.hi;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.ink800 : Colors.white;
    final textColor = dark ? Colors.white : AppColors.ink900;

    final currentName = isHi ? widget.product.nameHi : widget.product.nameEn;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron200),
          boxShadow: kLiftShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink700 : AppColors.ink200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header row with title & close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.saffron600.withAlpha(dark ? 40 : 25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.saffron600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isHi ? 'आवाज़ से जानकारी बदलें' : 'Edit Voice Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.ink700 : AppColors.ink200.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: dark ? Colors.white70 : AppColors.ink700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product Summary Card preview (hidden in success state to focus on results)
            if (_state != _EditState.success)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink900 : AppColors.saffron50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron200),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildProductThumbnail(widget.product.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                widget.product.formattedPrice,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.saffron600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.green50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.product.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_state != _EditState.success) const SizedBox(height: 20),

            // State specific contents with smooth animated cross fade
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (_state) {
                _EditState.idle => _buildIdleView(isHi, dark, textColor),
                _EditState.recording => _buildRecordingView(isHi, dark, textColor),
                _EditState.processing => _buildProcessingView(isHi, textColor),
                _EditState.success => _buildSuccessView(isHi, dark, textColor),
                _EditState.error => _buildErrorView(isHi, textColor),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleView(bool isHi, bool dark, Color textColor) {
    return Column(
      key: const ValueKey('idle_view'),
      children: [
        // Helper prompt text
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? AppColors.ink700.withAlpha(80) : AppColors.amber100.withAlpha(120),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: AppColors.amber600, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHi
                      ? 'बदलाव बोलें (जैसे "कीमत 500 रुपये कर दो" या "विवरण में शुद्ध मिट्टी लिखें")'
                      : 'Speak changes (e.g., "Set price to 500 rupees" or "Update description to handmade terracotta clay")',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white70 : AppColors.ink700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Record Action Button
        GestureDetector(
          onTap: _startRecording,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.saffron600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.saffron600.withAlpha(
                        (80 + 80 * _pulseController.value).round(),
                      ),
                      blurRadius: 16 + 10 * _pulseController.value,
                      spreadRadius: 2 + 4 * _pulseController.value,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isHi ? 'बोलने के लिए टैप करें' : 'Tap to Start Speaking',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingView(bool isHi, bool dark, Color textColor) {
    return Column(
      key: const ValueKey('recording_view'),
      children: [
        // Recording timer
        Text(
          _formatTimer(_seconds),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.saffron600,
          ),
        ),
        const SizedBox(height: 10),

        // Live mic level waveform
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final multipliers = [0.3, 0.6, 0.9, 1.0, 0.85, 0.5, 0.3];
            final height = (10 + 36 * _micLevel * multipliers[index]).clamp(8.0, 44.0);
            return Container(
              width: 6,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.saffron600,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          isHi ? 'आपकी बात सुन रहे हैं...' : 'Listening to your instructions...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),

        // Finish button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _stopAndProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffron600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.stop_rounded, size: 22),
            label: Text(
              isHi ? 'समाप्त करें और अपडेट लागू करें' : 'Finish & Apply Update',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView(bool isHi, Color textColor) {
    return Padding(
      key: const ValueKey('processing_view'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: AppColors.saffron600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isHi ? 'AI बदलावों को अपडेट कर रहा है...' : 'Gemini AI is updating product details...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isHi, bool dark, Color textColor) {
    final original = widget.product;
    final updated = _updatedProduct ?? original;

    final priceChanged = original.priceInRupees != updated.priceInRupees;
    final nameChanged = isHi
        ? (original.nameHi != updated.nameHi)
        : (original.nameEn != updated.nameEn);
    final descChanged = original.description != updated.description && updated.description.isNotEmpty;

    return Column(
      key: const ValueKey('success_view'),
      children: [
        const SizedBox(height: 8),

        // Animated spring checkmark icon with glowing ring
        const SuccessCheckAnimation(
          size: 68,
          primaryColor: AppColors.green600,
        ),
        const SizedBox(height: 14),

        // Heading
        Text(
          isHi ? 'उत्पाद अपडेट हो गया!' : 'Product Updated!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),

        // Spoken confirmation summary pill
        if (_successSummary != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? AppColors.ink900 : AppColors.saffron50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.saffron600),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _successSummary!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.saffron700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Before -> After Diff Breakdown Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? AppColors.ink900 : AppColors.saffron50.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 16, color: AppColors.saffron600),
                  const SizedBox(width: 6),
                  Text(
                    isHi ? 'बदलाव विवरण' : 'Change Breakdown',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.saffron600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price diff
              if (priceChanged)
                BeforeAfterDiffRow(
                  label: isHi ? 'कीमत' : 'Price',
                  oldValue: original.formattedPrice,
                  newValue: updated.formattedPrice,
                  isDark: dark,
                ),

              // Title diff
              if (nameChanged)
                BeforeAfterDiffRow(
                  label: isHi ? 'नाम' : 'Title',
                  oldValue: isHi ? original.nameHi : original.nameEn,
                  newValue: isHi ? updated.nameHi : updated.nameEn,
                  isDark: dark,
                ),

              // Description diff
              if (descChanged)
                BeforeAfterDiffRow(
                  label: isHi ? 'विवरण' : 'Desc',
                  oldValue: original.description.isNotEmpty ? original.description : (isHi ? 'कोई नहीं' : 'None'),
                  newValue: updated.description,
                  isDark: dark,
                ),

              // If no specific field was identified as changed
              if (!priceChanged && !nameChanged && !descChanged)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.green600),
                      const SizedBox(width: 8),
                      Text(
                        isHi ? 'जानकारी सत्यापित और सुरक्षित' : 'Details verified & saved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white70 : AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffron600,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isHi ? 'हो गया' : 'Done',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(bool isHi, Color textColor) {
    return Column(
      key: const ValueKey('error_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.red600, size: 40),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              _errorMessage ??
                  (isHi
                      ? 'कुछ गलत हो गया।'
                      : 'Something went wrong.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.red600,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _state = _EditState.idle);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isHi ? 'पुनः प्रयास करें' : 'Try Again'),
          ),
        ),
      ],
    );
  }
}
