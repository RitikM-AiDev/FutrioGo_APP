import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/api_keys.dart';
import 'models/message.dart';
import 'services/api_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'theme/colors.dart';
import 'widgets/capsule_input.dart';
import 'widgets/chat_message_tile.dart';
import 'widgets/nc_logo.dart';
import 'widgets/settings_modal.dart';
import 'widgets/setup_wizard.dart';
import 'widgets/thinking_bubble.dart';

const _overlayChannel = MethodChannel('com.futrio.go/overlay');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FutrioGoApp());
}

class FutrioGoApp extends StatelessWidget {
  const FutrioGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futrio Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        fontFamily: 'Roboto',
      ),
      home: const AssistantOverlayScreen(),
    );
  }
}

class AssistantOverlayScreen extends StatefulWidget {
  const AssistantOverlayScreen({super.key});

  @override
  State<AssistantOverlayScreen> createState() => _AssistantOverlayScreenState();
}

class _AssistantOverlayScreenState extends State<AssistantOverlayScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService();

  ApiKeys _apiKeys = const ApiKeys();
  bool _isLoadingKeys = true;
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isExpanded = false;

  final List<ChatMessage> _messages = [];

  void _setExpanded(bool expanded) {
    setState(() => _isExpanded = expanded);
    // Tell the native overlay service to toggle focus so touches
    // pass through the transparent area when collapsed
    _overlayChannel.invokeMethod('setFocusable', {'focusable': expanded})
        .catchError((_) {}); // Ignore if running outside overlay service
  }

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  void _loadInitialState() async {
    final keys = await StorageService.loadKeys();
    setState(() {
      _apiKeys = keys;
      _isLoadingKeys = false;
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) async {
    final queryText = (text ?? _queryController.text).trim();
    if (queryText.isEmpty || _isProcessing) return;

    _queryController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'user',
          text: queryText,
          timestamp: DateTime.now(),
        ),
      );
      _isProcessing = true;
    });
    _setExpanded(true);
    _scrollToBottom();

    try {
      final result = await ApiService.sendQuery(
        query: queryText,
        keys: _apiKeys,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            text: result.text,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            text: e.toString().replaceFirst('Exception: ', ''),
            isError: true,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  void _handleMicToggle() async {
    if (_isProcessing) return;

    if (_isListening) {
      // Stop recording and send audio
      final recordedPath = await _audioService.stopRecording();
      setState(() => _isListening = false);

      if (recordedPath == null) return;

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'user',
            text: 'Voice message',
            audioPath: recordedPath,
            timestamp: DateTime.now(),
          ),
        );
        _isProcessing = true;
      });
      _setExpanded(true);
      _scrollToBottom();

      try {
        if (!_apiKeys.hasGroq) {
          throw Exception(
              'Groq API key is required for voice transcription. Please tap the settings icon to add it.');
        }

        final result = await ApiService.sendAudio(
          audioPath: recordedPath,
          keys: _apiKeys,
        );

        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: 'assistant',
              text: result.text,
              timestamp: DateTime.now(),
            ),
          );
        });
      } catch (e) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: 'assistant',
              text: e.toString().replaceFirst('Exception: ', ''),
              isError: true,
              timestamp: DateTime.now(),
            ),
          );
        });
      } finally {
        setState(() => _isProcessing = false);
        _scrollToBottom();
      }
    } else {
      // Start recording
      final permitted = await _audioService.hasPermission();
      if (!mounted) return;
      if (!permitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }

      await _audioService.startRecording();
      setState(() {
        _isListening = true;
      });
      _setExpanded(true);
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _setExpanded(false);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SettingsModal(
          currentKeys: _apiKeys,
          onKeysUpdated: (updated) {
            setState(() => _apiKeys = updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingKeys) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // If initial keys are not configured, show 6-step onboarding wizard
    if (!_apiKeys.isReadyForText) {
      return Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        body: SafeArea(
          child: SetupWizard(
            onComplete: _loadInitialState,
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_isExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isExpanded) {
          _setExpanded(false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Upper transparent click-through zone: tapping collapses or dismisses overlay
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_isExpanded) {
                    _setExpanded(false);
                  } else {
                    SystemNavigator.pop();
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Google Assistant / Gemini Bottom Sheet Overlay
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: _isExpanded ? screenHeight * 0.72 : 110.0,
                  decoration: BoxDecoration(
                    color: AppColors.darkObsidian.withValues(alpha: 0.96),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border:
                        Border.all(color: AppColors.borderHighlight, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Drag Handle & Expand/Collapse Bar
                        GestureDetector(
                          onVerticalDragUpdate: (details) {
                            if (details.primaryDelta! > 7) {
                              if (_isExpanded) {
                                _setExpanded(false);
                              } else {
                                SystemNavigator.pop();
                              }
                            } else if (details.primaryDelta! < -7) {
                              _setExpanded(true);
                            }
                          },
                          onTap: () => _setExpanded(!_isExpanded),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Assistant Header (visible when expanded)
                        if (_isExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    NCLogo(size: 24, glowing: false),
                                    SizedBox(width: 8),
                                    Text(
                                      'Futrio Go',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20, color: AppColors.textMuted),
                                      onPressed: _clearChat,
                                      tooltip: 'Clear Chat',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down,
                                          size: 24, color: AppColors.textMuted),
                                      onPressed: () =>
                                          _setExpanded(false),
                                      tooltip: 'Collapse',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 20, color: AppColors.textMuted),
                                      onPressed: () => _overlayChannel
                                          .invokeMethod('closeOverlay')
                                          .catchError((_) => SystemNavigator.pop()),
                                      tooltip: 'Close Overlay',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                      // Messages List
                      if (_isExpanded)
                        Expanded(
                          child: _messages.isEmpty && !_isProcessing
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NCLogo(
                                          size: 48,
                                          glowing: _isListening || _isProcessing),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Hi, how can I help you?',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Search YouTube, find answers, or dictate tasks',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _messages.length +
                                      (_isProcessing ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _messages.length) {
                                      return const ThinkingBubble();
                                    }
                                    return ChatMessageTile(
                                      message: _messages[index],
                                      audioPlayer: _audioService.player,
                                    );
                                  },
                                ),
                        ),

                      // Bottom Floating Capsule Input & Mic
                      CapsuleInput(
                        controller: _queryController,
                        isLoading: _isProcessing,
                        isListening: _isListening,
                        onSend: () => _sendMessage(),
                        onMicToggle: _handleMicToggle,
                        onClear: _clearChat,
                        onOpenSettings: _openSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
