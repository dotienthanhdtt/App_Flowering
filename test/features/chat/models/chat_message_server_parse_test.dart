import 'package:flutter_test/flutter_test.dart';
import 'package:flowering/features/chat/models/chat_message_model.dart';

void main() {
  group('ChatMessage.fromServerJson', () {
    test('parses assistant role into aiText type', () {
      final msg = ChatMessage.fromServerJson({
        'id': 'msg-1',
        'role': 'assistant',
        'content': 'Hello!',
        'created_at': '2026-04-14T23:20:00Z',
      });

      expect(msg.id, 'msg-1');
      expect(msg.type, ChatMessageType.aiText);
      expect(msg.text, 'Hello!');
      expect(msg.timestamp.toUtc(),
          DateTime.utc(2026, 4, 14, 23, 20));
    });

    test('parses user role into userText type', () {
      final msg = ChatMessage.fromServerJson({
        'id': 'msg-2',
        'role': 'user',
        'content': 'I want to learn English',
        'created_at': '2026-04-14T23:21:00Z',
      });

      expect(msg.type, ChatMessageType.userText);
      expect(msg.text, 'I want to learn English');
    });

    test('unknown role falls back to aiText (forward-compat)', () {
      final msg = ChatMessage.fromServerJson({
        'id': 'msg-3',
        'role': 'system',
        'content': 'ping',
        'created_at': '2026-04-14T23:22:00Z',
      });

      expect(msg.type, ChatMessageType.aiText);
    });

    test('missing id generates a fallback identifier', () {
      final msg = ChatMessage.fromServerJson({
        'role': 'user',
        'content': 'hi',
      });

      expect(msg.id, startsWith('srv_'));
      expect(msg.text, 'hi');
    });

    test('invalid timestamp falls back to now without throwing', () {
      final before = DateTime.now();
      final msg = ChatMessage.fromServerJson({
        'id': 'msg-4',
        'role': 'user',
        'content': 'hi',
        'created_at': 'not-a-date',
      });
      final after = DateTime.now();

      // Falls back to "now" — must be within the test window.
      expect(msg.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(msg.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('missing content becomes empty string (no null)', () {
      final msg = ChatMessage.fromServerJson({
        'id': 'msg-5',
        'role': 'assistant',
      });

      expect(msg.text, '');
    });
  });
}
