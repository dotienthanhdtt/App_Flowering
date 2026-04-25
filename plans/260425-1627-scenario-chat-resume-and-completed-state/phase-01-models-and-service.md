# Phase 01 — Models + Service: New Response Shape

## Context Links
- Brainstorm: [`../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md`](../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md)
- Plan overview: [`plan.md`](plan.md)

## Overview
- **Priority:** P1
- **Status:** done
- **Effort:** 1h
- Replace single-turn DTO with full state DTO. Update service generic. No behavior change yet — controller still calls `chat()` and crashes if not updated; phase 2 fixes that.

## Key Insights
- Same endpoint `POST /scenario/chat`. Same request body. Only response changes.
- Status string is `CHATTING` | `DONE`. Use enum + defensive default to absorb any backend drift.
- snake_case + camelCase tolerant parsing (existing code style).

## Requirements

### Functional
- Parse `{scenario: {conversation_id, max_turns, turn, status}, messages: [{id, role, content, created_at}]}`.
- Status enum: `chatting`, `done`. Unknown / null → `chatting`.
- Preserve current request DTO unchanged.

### Non-functional
- No new external deps.
- All fields nullable-tolerant (defaults: empty string, 0, current DateTime).

## Architecture

```
ScenarioChatService.chat(req) → ApiResponse<ScenarioChatResponse>
                                    ├── ScenarioState
                                    └── List<ScenarioMessage>
```

## Related Code Files

### Modified
- `lib/features/scenario-chat/models/scenario_chat_turn_response.dart` — full rewrite
- `lib/features/scenario-chat/services/scenario_chat_service.dart` — generic type swap

### Created
- (none — keep `scenario_chat_turn_response.dart` filename for git diff hygiene; rename optional in follow-up)

### Deleted
- (none in this phase)

## Implementation Steps

1. Open `lib/features/scenario-chat/models/scenario_chat_turn_response.dart`.
2. Replace contents with:

```dart
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
        maxTurns: (json['max_turns'] as int?) ??
            (json['maxTurns'] as int?) ??
            0,
        turn: (json['turn'] as int?) ?? 0,
        status: _statusFromString(json['status'] as String?),
      );
}

class ScenarioMessage {
  final String id;
  final String role; // "assistant" | "user"
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
```

3. Open `lib/features/scenario-chat/services/scenario_chat_service.dart`.
4. Swap generic type `ScenarioChatTurnResponse` → `ScenarioChatResponse`. Update import + `fromJson` callback. Final shape:

```dart
import 'package:get/get.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/scenario_chat_turn_request.dart';
import '../models/scenario_chat_turn_response.dart';

class ScenarioChatService extends GetxService {
  ApiClient get _apiClient => Get.find<ApiClient>();

  Future<ApiResponse<ScenarioChatResponse>> chat(
    ScenarioChatTurnRequest req,
  ) {
    return _apiClient.post<ScenarioChatResponse>(
      ApiEndpoints.scenarioChat,
      data: req.toJson(),
      fromJson: (data) =>
          ScenarioChatResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
```

5. Run `flutter analyze` — expect compile errors in `scenario_chat_controller_messaging.dart` (still references old DTO fields). That's intentional; phase 2 fixes.

## Todo List

- [x] Rewrite `scenario_chat_turn_response.dart` with new model classes
- [x] Update `scenario_chat_service.dart` generic type and import
- [x] Verify only expected analyzer errors remain (controller usage sites)

## Success Criteria

- Models compile; `ScenarioChatResponse.fromJson(samplePayload)` round-trips correctly.
- Service signature returns `ApiResponse<ScenarioChatResponse>`.
- No analyzer errors inside `models/` or `services/`.

## Risk Assessment

- **Risk:** silent field drift if backend renames `conversation_id` → `conversation`. **Mitigation:** defensive defaults; verify against real API response in QA.
- **Risk:** `created_at` parse failure on bad timestamps. **Mitigation:** `DateTime.tryParse` fallback to `DateTime.now()`.

## Security Considerations
- None — DTO change only. No PII handling change.

## Next Steps
- Phase 2 consumes new DTOs in controller.
