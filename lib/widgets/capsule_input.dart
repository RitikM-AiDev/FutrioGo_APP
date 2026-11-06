import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'gemini_glow_bar.dart';

class CapsuleInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onClear;
  final VoidCallback onOpenSettings;

  const CapsuleInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.onSend,
    required this.onMicToggle,
    required this.onClear,
    required this.onOpenSettings,
  });

  @override
  State<CapsuleInput> createState() => _CapsuleInputState();
}

class _CapsuleInputState extends State<CapsuleInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _micPulseController;
  late Animation<double> _pulseAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void didUpdateWidget(covariant CapsuleInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _micPulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _micPulseController.stop();
      _micPulseController.reset();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _micPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading || widget.isListening) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: GeminiGlowBar(isAnimated: true, height: 3.0),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: widget.isListening
                  ? AppColors.primary
                  : (widget.isLoading
                      ? AppColors.accent
                      : AppColors.borderHighlight),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Clear button (+)
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textMuted, size: 22),
                tooltip: 'New Conversation',
                onPressed: widget.isLoading ? null : widget.onClear,
              ),

              // Settings button
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                tooltip: 'API Settings',
                onPressed: widget.onOpenSettings,
              ),

              // Text input field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.isLoading && !widget.isListening,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSend(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.isListening
                        ? 'Listening to speech...'
                        : (widget.isLoading
                            ? 'Reasoning...'
                            : 'Ask Futrio Go or tap mic...'),
                    hintStyle: TextStyle(
                      color: widget.isListening
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              // Mic / Send button
              if (_hasText && !widget.isListening) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: widget.isLoading ? null : widget.onSend,
                ),
              ] else ...[
                ScaleTransition(
                  scale: widget.isListening
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: IconButton(
                    icon: Icon(
                      widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: widget.isListening ? Colors.white : AppColors.primary,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.isListening
                          ? AppColors.red
                          : AppColors.primary.withOpacity(0.15),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: widget.isLoading ? null : widget.onMicToggle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

