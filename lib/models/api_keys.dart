class ApiKeys {
  final String gemini;
  final String tavily;
  final String serper;
  final String groq;

  const ApiKeys({
    this.gemini = '',
    this.tavily = '',
    this.serper = '',
    this.groq = '',
  });

  bool get hasGemini => gemini.trim().isNotEmpty;
  bool get hasTavily => tavily.trim().isNotEmpty;
  bool get hasSerper => serper.trim().isNotEmpty;
  bool get hasGroq => groq.trim().isNotEmpty;

  /// Gemini, Tavily, and Serper are required for text queries.
  bool get isReadyForText => hasGemini && hasTavily && hasSerper;

  /// Groq is additionally required for voice queries.
  bool get isReadyForVoice => isReadyForText && hasGroq;

  ApiKeys copyWith({
    String? gemini,
    String? tavily,
    String? serper,
    String? groq,
  }) {
    return ApiKeys(
      gemini: gemini ?? this.gemini,
      tavily: tavily ?? this.tavily,
      serper: serper ?? this.serper,
      groq: groq ?? this.groq,
    );
  }
}

