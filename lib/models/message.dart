class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final bool isError;
  final String? audioPath;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isError = false,
    this.audioPath,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isVoiceNote => audioPath != null && audioPath!.isNotEmpty;
}

