import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import 'nc_logo.dart';

class ChatMessageTile extends StatefulWidget {
  final ChatMessage message;
  final AudioPlayer? audioPlayer;

  const ChatMessageTile({
    super.key,
    required this.message,
    this.audioPlayer,
  });

  @override
  State<ChatMessageTile> createState() => _ChatMessageTileState();
}

class _ChatMessageTileState extends State<ChatMessageTile> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.isVoiceNote && widget.audioPlayer != null) {
      widget.audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
      widget.audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      widget.audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    }
  }

  void _toggleAudio() async {
    final player = widget.audioPlayer;
    if (player == null || widget.message.audioPath == null) return;

    if (_isPlaying) {
      await player.pause();
    } else {
      await player.stop();
      await player.play(DeviceFileSource(widget.message.audioPath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Padding(
              padding: EdgeInsets.only(top: 2.0, right: 8.0),
              child: NCLogo(size: 28, glowing: false),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary.withOpacity(0.2)
                    : (widget.message.isError
                        ? AppColors.red.withOpacity(0.12)
                        : AppColors.cardSurface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: widget.message.isError
                      ? AppColors.red.withOpacity(0.4)
                      : (isUser
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.isVoiceNote) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          onPressed: _toggleAudio,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPlaying
                              ? '${_position.inSeconds}s / ${_duration.inSeconds}s'
                              : 'Voice Note',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    MarkdownBody(
                      data: widget.message.text,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          ApiService.launchExternalUrl(href);
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: widget.message.isError
                              ? AppColors.red
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                        code: const TextStyle(
                          color: AppColors.cyan,
                          backgroundColor: Colors.transparent,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.darkObsidian,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

