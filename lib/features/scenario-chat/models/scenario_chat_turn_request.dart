/// Request body for POST /scenario/chat
class ScenarioChatTurnRequest {
  final String scenarioId;
  final String message;
  final bool? forceNew;
  final String? conversationId;

  const ScenarioChatTurnRequest({
    required this.scenarioId,
    required this.message,
    this.forceNew,
    this.conversationId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'scenarioId': scenarioId,
      'message': message,
    };
    if (forceNew != null) map['forceNew'] = forceNew;
    if (conversationId != null) map['conversationId'] = conversationId;
    return map;
  }
}
