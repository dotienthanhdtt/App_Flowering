enum ScenarioStatus { chatting, done }

ScenarioStatus _statusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'DONE':
      return ScenarioStatus.done;
    case 'CHATTING':
    default:
      return ScenarioStatus.chatting;
  }
}

class ScenarioState {
  final String conversationId;
  final int maxTurns;
  final int turn;
  final ScenarioStatus status;

  const ScenarioState({
    required this.conversationId,
    required this.maxTurns,
    required this.turn,
    required this.status,
  });

  factory ScenarioState.fromJson(Map<String, dynamic> json) => ScenarioState(
        conversationId: json['conversation_id'] as String? ??
            json['conversationId'] as String? ??
            '',
        maxTurns:
            (json['max_turns'] as int?) ?? (json['maxTurns'] as int?) ?? 0,
        turn: (json['turn'] as int?) ?? 0,
        status: _statusFromString(json['status'] as String?),
      );
}

class ScenarioMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ScenarioMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isAssistant => role == 'assistant';
  bool get isUser => role == 'user';

  factory ScenarioMessage.fromJson(Map<String, dynamic> json) => ScenarioMessage(
        id: json['id'] as String? ?? '',
        role: json['role'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.tryParse(
              json['created_at'] as String? ??
                  json['createdAt'] as String? ??
                  '',
            ) ??
            DateTime.now(),
      );
}

class ScenarioChatResponse {
  final ScenarioState scenario;
  final List<ScenarioMessage> messages;

  const ScenarioChatResponse({
    required this.scenario,
    required this.messages,
  });

  factory ScenarioChatResponse.fromJson(Map<String, dynamic> json) {
    final scenarioJson =
        (json['scenario'] as Map<String, dynamic>?) ?? const {};
    final messagesJson = (json['messages'] as List?) ?? const [];
    return ScenarioChatResponse(
      scenario: ScenarioState.fromJson(scenarioJson),
      messages: messagesJson
          .whereType<Map<String, dynamic>>()
          .map(ScenarioMessage.fromJson)
          .toList(growable: false),
    );
  }
}
