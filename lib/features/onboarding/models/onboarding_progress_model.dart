/// Onboarding progress checkpoint model — persisted as JSON in preferences box.
///
/// Schema version (`_v`) guards against future incompatible changes; unknown
/// versions are treated as empty (user restarts onboarding).
class OnboardingProgress {
  static const int schemaVersion = 1;

  final LangCheckpoint? nativeLang;
  final LangCheckpoint? learningLang;
  final ChatCheckpoint? chat;
  final bool profileComplete;
  final DateTime? updatedAt;

  const OnboardingProgress({
    this.nativeLang,
    this.learningLang,
    this.chat,
    this.profileComplete = false,
    this.updatedAt,
  });

  factory OnboardingProgress.empty() => const OnboardingProgress();

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final version = json['_v'] as int?;
    if (version != schemaVersion) return OnboardingProgress.empty();

    final native = json['native_lang'] as Map<String, dynamic>?;
    final learning = json['learning_lang'] as Map<String, dynamic>?;
    final chat = json['chat'] as Map<String, dynamic>?;
    final updated = json['updated_at'] as String?;

    return OnboardingProgress(
      nativeLang: native != null ? LangCheckpoint.fromJson(native) : null,
      learningLang: learning != null ? LangCheckpoint.fromJson(learning) : null,
      chat: chat != null ? ChatCheckpoint.fromJson(chat) : null,
      profileComplete: json['profile_complete'] as bool? ?? false,
      updatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_v': schemaVersion,
        if (nativeLang != null) 'native_lang': nativeLang!.toJson(),
        if (learningLang != null) 'learning_lang': learningLang!.toJson(),
        if (chat != null) 'chat': chat!.toJson(),
        'profile_complete': profileComplete,
        'updated_at':
            (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

  OnboardingProgress copyWith({
    LangCheckpoint? nativeLang,
    LangCheckpoint? learningLang,
    ChatCheckpoint? chat,
    bool? profileComplete,
    DateTime? updatedAt,
    bool clearChat = false,
  }) {
    return OnboardingProgress(
      nativeLang: nativeLang ?? this.nativeLang,
      learningLang: learningLang ?? this.learningLang,
      chat: clearChat ? null : (chat ?? this.chat),
      profileComplete: profileComplete ?? this.profileComplete,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty =>
      nativeLang == null &&
      learningLang == null &&
      chat == null &&
      !profileComplete;
}

/// Language checkpoint: stores language code + optional server-side UUID.
class LangCheckpoint {
  final String code;
  final String? id;

  const LangCheckpoint({required this.code, this.id});

  factory LangCheckpoint.fromJson(Map<String, dynamic> json) => LangCheckpoint(
        code: json['code'] as String,
        id: json['id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        if (id != null) 'id': id,
      };
}

/// Chat checkpoint: stores active onboarding conversation UUID.
class ChatCheckpoint {
  final String conversationId;

  const ChatCheckpoint({required this.conversationId});

  factory ChatCheckpoint.fromJson(Map<String, dynamic> json) => ChatCheckpoint(
        conversationId: json['conversation_id'] as String,
      );

  Map<String, dynamic> toJson() => {'conversation_id': conversationId};
}
