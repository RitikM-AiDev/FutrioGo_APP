import 'package:flutter/material.dart';
import '../models/api_keys.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class SettingsModal extends StatefulWidget {
  final ApiKeys currentKeys;
  final Function(ApiKeys) onKeysUpdated;

  const SettingsModal({
    super.key,
    required this.currentKeys,
    required this.onKeysUpdated,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final _geminiController = TextEditingController();
  final _tavilyController = TextEditingController();
  final _serperController = TextEditingController();
  final _groqController = TextEditingController();

  bool _isSaving = false;
  String? _statusMessage;
  bool _isError = false;

  late ApiKeys _keys;

  @override
  void initState() {
    super.initState();
    _keys = widget.currentKeys;
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _tavilyController.dispose();
    _serperController.dispose();
    _groqController.dispose();
    super.dispose();
  }

  void _saveKeys() async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      await StorageService.saveKeys(
        gemini: _geminiController.text,
        tavily: _tavilyController.text,
        serper: _serperController.text,
        groq: _groqController.text,
      );

      final updated = await StorageService.loadKeys();
      _geminiController.clear();
      _tavilyController.clear();
      _serperController.clear();
      _groqController.clear();

      setState(() {
        _keys = updated;
        _isSaving = false;
        _isError = false;
        _statusMessage = 'Keys updated successfully!';
      });

      widget.onKeysUpdated(updated);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _isError = true;
        _statusMessage = 'Failed to save keys: $e';
      });
    }
  }

  Widget _buildKeyRow({
    required String label,
    required bool isConfigured,
    required TextEditingController controller,
    required String hint,
    required String portalUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? AppColors.green.withOpacity(0.15)
                        : AppColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isConfigured
                          ? AppColors.green.withOpacity(0.4)
                          : AppColors.red.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isConfigured ? 'Active' : 'Missing',
                    style: TextStyle(
                      color: isConfigured ? AppColors.green : AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => ApiService.launchExternalUrl(portalUrl),
              child: const Text(
                'Get Key ↗',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: isConfigured ? '•••••••••••••••• (Leave blank to keep)' : hint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'API Key Configuration',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your API keys are encrypted and stored locally on your device.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),

            _buildKeyRow(
              label: 'Google Gemini (Required)',
              isConfigured: _keys.hasGemini,
              controller: _geminiController,
              hint: 'AIzaSy...',
              portalUrl: 'https://aistudio.google.com/app/apikey',
            ),
            _buildKeyRow(
              label: 'Tavily Search (Required)',
              isConfigured: _keys.hasTavily,
              controller: _tavilyController,
              hint: 'tvly-...',
              portalUrl: 'https://app.tavily.com/home',
            ),
            _buildKeyRow(
              label: 'Serper Search (Required)',
              isConfigured: _keys.hasSerper,
              controller: _serperController,
              hint: 'Serper API Key',
              portalUrl: 'https://serper.dev/api-key',
            ),
            _buildKeyRow(
              label: 'Groq Voice Transcribe (Optional for Voice)',
              isConfigured: _keys.hasGroq,
              controller: _groqController,
              hint: 'gsk_...',
              portalUrl: 'https://console.groq.com/keys',
            ),

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isError
                      ? AppColors.red.withOpacity(0.12)
                      : AppColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isError ? AppColors.red : AppColors.green,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton(
              onPressed: _isSaving ? null : _saveKeys,
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

