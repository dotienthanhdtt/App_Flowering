/// Response body from POST /scenario/chat
class ScenarioChatTurnResponse {
  final String reply;
  final String conversationId;
  final int turn;
  final int maxTurns;
  final bool completed;

  const ScenarioChatTurnResponse({
    required this.reply,
    required this.conversationId,
    required this.turn,
    required this.maxTurns,
    required this.completed,
  });

  factory ScenarioChatTurnResponse.fromJson(Map<String, dynamic> json) =>
      ScenarioChatTurnResponse(
        reply: json['reply'] as String? ?? '',
        conversationId:
            json['conversation_id'] as String? ?? json['conversationId'] as String? ?? '',
        turn: (json['turn'] as int?) ?? 0,
        maxTurns: (json['max_turns'] as int?) ?? (json['maxTurns'] as int?) ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
