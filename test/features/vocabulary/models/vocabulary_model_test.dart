import 'package:flutter_test/flutter_test.dart';

import 'package:flowering/features/vocabulary/models/vocabulary-model.dart';

void main() {
  group('VocabularyListResponse', () {
    test(
      'parses snake_case response with nullable timestamps and examples',
      () {
        final response = VocabularyListResponse.fromJson({
          'items': [
            {
              'id': 'v1',
              'word': 'hello',
              'translation': 'xin chao',
              'box': 3,
              'examples': ['Hello there'],
              'created_at': null,
              'updated_at': '2026-04-24T10:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 20,
        });

        expect(response.total, 1);
        expect(response.page, 1);
        expect(response.limit, 20);
        expect(response.items, hasLength(1));

        final item = response.items.single;
        expect(item.id, 'v1');
        expect(item.word, 'hello');
        expect(item.translation, 'xin chao');
        expect(item.box, 3);
        expect(item.examples, ['Hello there']);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, DateTime.parse('2026-04-24T10:00:00Z'));
      },
    );
  });
}
