import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import 'nc_logo.dart';

class SetupWizard extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupWizard({
    super.key,
    required this.onComplete,
  });

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

enum WizardStep { welcome, gemini, tavily, serper, groq, done }

class _SetupWizardState extends State<SetupWizard> {
  WizardStep _step = WizardStep.welcome;

  final _geminiController = TextEditingController();
  final _tavilyController = TextEditingController();
  final _serperController = TextEditingController();
  final _groqController = TextEditingController();

  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _geminiController.dispose();
    _tavilyController.dispose();
    _serperController.dispose();
    _groqController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _errorMessage = null);
    switch (_step) {
      case WizardStep.welcome:
        setState(() => _step = WizardStep.gemini);
        break;
      case WizardStep.gemini:
        if (_geminiController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your Google Gemini API key.');
          return;
        }
        setState(() => _step = WizardStep.tavily);
        break;
      case WizardStep.tavily:
        if (_tavilyController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your Tavily Search API key.');
          return;
        }
        setState(() => _step = WizardStep.serper);
        break;
      case WizardStep.serper:
        if (_serperController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your Serper API key.');
          return;
        }
        setState(() => _step = WizardStep.groq);
        break;
      case WizardStep.groq:
        // Groq is optional; can proceed even if empty, but recommended for voice
        _saveAllKeys();
        break;
      case WizardStep.done:
        widget.onComplete();
        break;
    }
  }

  void _back() {
    setState(() => _errorMessage = null);
    switch (_step) {
      case WizardStep.welcome:
        break;
      case WizardStep.gemini:
        setState(() => _step = WizardStep.welcome);
        break;
      case WizardStep.tavily:
        setState(() => _step = WizardStep.gemini);
        break;
      case WizardStep.serper:
        setState(() => _step = WizardStep.tavily);
        break;
      case WizardStep.groq:
        setState(() => _step = WizardStep.serper);
        break;
      case WizardStep.done:
        setState(() => _step = WizardStep.groq);
        break;
    }
  }

  void _saveAllKeys() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await StorageService.saveKeys(
        gemini: _geminiController.text,
        tavily: _tavilyController.text,
        serper: _serperController.text,
        groq: _groqController.text,
      );

      setState(() {
        _isSaving = false;
        _step = WizardStep.done;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save keys: $e';
      });
    }
  }

  Widget _buildStepDots(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == activeIndex;
        final isPassed = index < activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (isPassed ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildKeyStep({
    required int stepNumber,
    required String title,
    required String description,
    required String portalName,
    required String portalUrl,
    required TextEditingController controller,
    required String hintText,
    bool isOptional = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepDots(stepNumber - 1),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
            label: Text(
              'Get $portalName Key ↗',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => ApiService.launchExternalUrl(portalUrl),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderHighlight),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isOptional && controller.text.trim().isEmpty ? 'Skip / Continue' : 'Continue',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderHighlight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: () {
            switch (_step) {
              case WizardStep.welcome:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NCLogo(size: 64, glowing: true),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to Futrio Go',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your smart on-screen AI assistant.\nLet’s quickly configure your free API keys.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Get Started →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

              case WizardStep.gemini:
                return _buildKeyStep(
                  stepNumber: 1,
                  title: 'Google Gemini API Key',
                  description:
                      'Required for core intelligence and smart reasoning.',
                  portalName: 'Gemini',
                  portalUrl: 'https://aistudio.google.com/app/apikey',
                  controller: _geminiController,
                  hintText: 'Enter AIzaSy... key',
                );

              case WizardStep.tavily:
                return _buildKeyStep(
                  stepNumber: 2,
                  title: 'Tavily Search API Key',
                  description:
                      'Provides live web browsing and real-time knowledge.',
                  portalName: 'Tavily',
                  portalUrl: 'https://app.tavily.com/home',
                  controller: _tavilyController,
                  hintText: 'Enter tvly-... key',
                );

              case WizardStep.serper:
                return _buildKeyStep(
                  stepNumber: 3,
                  title: 'Serper Google Search Key',
                  description:
                      'Provides real-time Google Search and YouTube link actions.',
                  portalName: 'Serper',
                  portalUrl: 'https://serper.dev/api-key',
                  controller: _serperController,
                  hintText: 'Enter Serper API key',
                );

              case WizardStep.groq:
                return _buildKeyStep(
                  stepNumber: 4,
                  title: 'Groq Voice Transcribe Key',
                  description:
                      'Enables ultra-fast Whisper Large v3 voice recording.',
                  portalName: 'Groq',
                  portalUrl: 'https://console.groq.com/keys',
                  controller: _groqController,
                  hintText: 'Enter gsk_... key (Optional)',
                  isOptional: true,
                );

              case WizardStep.done:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Setup Complete!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your keys are safely encrypted.\nFutrio Go is now ready to assist you anywhere!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Launch Assistant 🚀',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
            }
          }(),
        ),
      ),
    );
  }
}
