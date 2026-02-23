# Flutter Dio & Hive Best Practices Report (2025-2026)

**Date:** 2026-02-05
**Focus:** HTTP client patterns, local storage, offline-first architecture

---

## 1. Dio Interceptors for Auth Token Refresh

### Bearer + Refresh Token Pattern

**Key:** Use `QueuedInterceptor` to prevent race conditions during concurrent refresh attempts.

```dart
class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenRepository _tokenRepo;
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenRepo.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenRepo.getRefreshToken();
        final response = await _dio.post('/auth/refresh',
          data: {'refresh_token': refreshToken}
        );

        await _tokenRepo.saveTokens(
          accessToken: response.data['access_token'],
          refreshToken: response.data['refresh_token']
        );

        // Retry original request
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${response.data['access_token']}';
        final retryResponse = await _dio.fetch(opts);
        handler.resolve(retryResponse);
      } catch (e) {
        await _tokenRepo.clearTokens();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
```

---

## 2. Dio Error Handling & Retry Logic

### RetryInterceptor with Exponential Backoff

```dart
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({this.maxRetries = 3, this.initialDelay = const Duration(seconds: 1)});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retry_count'] == null) {
      err.requestOptions.extra['retry_count'] = 0;
    }

    final retryCount = err.requestOptions.extra['retry_count'] ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      err.requestOptions.extra['retry_count'] = retryCount + 1;
      final delay = initialDelay * (1 << retryCount); // Exponential backoff

      await Future.delayed(delay);

      try {
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}
```

---

## 3. Hive Setup with Flutter

### Initialization & Box Management

```dart
// lib/core/storage/hive_config.dart
class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(VocabularyAdapter());

    // Open boxes
    await Hive.openBox<User>('users');
    await Hive.openBox<Vocabulary>('vocabulary');
    await Hive.openBox('cache');
    await Hive.openBox<PendingSync>('pending_sync');
  }

  static Future<void> close() async {
    await Hive.close();
  }
}

// Type-safe box access
class HiveBoxes {
  static Box<User> get users => Hive.box<User>('users');
  static Box<Vocabulary> get vocabulary => Hive.box<Vocabulary>('vocabulary');
  static Box get cache => Hive.box('cache');
  static Box<PendingSync> get pendingSync => Hive.box<PendingSync>('pending_sync');
}
```

---

## 4. Hive Cache Eviction Strategies

### LRU (Least Recently Used) Implementation

```dart
class LRUCache<T> {
  final Box<T> _box;
  final Box<int> _accessBox; // Stores last access timestamp
  final int maxSize;

  LRUCache(this._box, {required this.maxSize})
    : _accessBox = Hive.box<int>('${_box.name}_access');

  Future<void> put(String key, T value) async {
    await _evictIfNeeded();
    await _box.put(key, value);
    await _accessBox.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  T? get(String key) {
    final value = _box.get(key);
    if (value != null) {
      _accessBox.put(key, DateTime.now().millisecondsSinceEpoch);
    }
    return value;
  }

  Future<void> _evictIfNeeded() async {
    if (_box.length >= maxSize) {
      final sortedKeys = _accessBox.keys.toList()
        ..sort((a, b) => (_accessBox.get(a) ?? 0).compareTo(_accessBox.get(b) ?? 0));

      final keysToRemove = sortedKeys.take(_box.length - maxSize + 1);
      for (final key in keysToRemove) {
        await _box.delete(key);
        await _accessBox.delete(key);
      }
    }
  }
}
```

### Size-Based Eviction

```dart
class SizeLimitedCache {
  final Box _box;
  final int maxSizeBytes;

  int _currentSize = 0;

  Future<void> put(String key, dynamic value) async {
    final valueSize = _estimateSize(value);

    while (_currentSize + valueSize > maxSizeBytes && _box.isNotEmpty) {
      final firstKey = _box.keyAt(0);
      _currentSize -= _estimateSize(_box.get(firstKey));
      await _box.deleteAt(0);
    }

    await _box.put(key, value);
    _currentSize += valueSize;
  }

  int _estimateSize(dynamic value) {
    // Rough estimation; adjust based on data type
    return value.toString().length * 2; // UTF-16 approximation
  }
}
```

---

## 5. Offline-First Pattern with Hive Queue

### Pending Sync Queue

```dart
@HiveType(typeId: 1)
class PendingSync extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String endpoint;

  @HiveField(2)
  final String method; // GET, POST, PUT, DELETE

  @HiveField(3)
  final Map<String, dynamic>? data;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  PendingSync({
    required this.id,
    required this.endpoint,
    required this.method,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
  });
}

class SyncQueue {
  final Box<PendingSync> _box = HiveBoxes.pendingSync;
  final Dio _dio;

  Future<void> enqueue(String endpoint, String method, {Map<String, dynamic>? data}) async {
    final sync = PendingSync(
      id: const Uuid().v4(),
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: DateTime.now(),
    );
    await _box.add(sync);
  }

  Future<void> processQueue() async {
    final pending = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final sync in pending) {
      try {
        await _sendRequest(sync);
        await sync.delete();
      } catch (e) {
        sync.retryCount++;
        if (sync.retryCount > 5) {
          await sync.delete(); // Give up after 5 retries
        } else {
          await sync.save();
        }
      }
    }
  }

  Future<void> _sendRequest(PendingSync sync) async {
    switch (sync.method) {
      case 'POST':
        await _dio.post(sync.endpoint, data: sync.data);
        break;
      case 'PUT':
        await _dio.put(sync.endpoint, data: sync.data);
        break;
      case 'DELETE':
        await _dio.delete(sync.endpoint);
        break;
      default:
        throw UnsupportedError('Method ${sync.method} not supported');
    }
  }
}
```

### Offline-First Repository Pattern

```dart
class VocabularyRepository {
  final Dio _dio;
  final Box<Vocabulary> _cacheBox = HiveBoxes.vocabulary;
  final SyncQueue _syncQueue;

  Future<List<Vocabulary>> getVocabulary({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheBox.isNotEmpty) {
      return _cacheBox.values.toList();
    }

    try {
      final response = await _dio.get('/vocabulary');
      final items = (response.data as List)
        .map((json) => Vocabulary.fromJson(json))
        .toList();

      await _cacheBox.clear();
      await _cacheBox.addAll(items);
      return items;
    } catch (e) {
      // Return cached data on error
      return _cacheBox.values.toList();
    }
  }

  Future<void> addVocabulary(Vocabulary vocab) async {
    // Save locally first
    await _cacheBox.put(vocab.id, vocab);

    // Queue for sync
    await _syncQueue.enqueue('/vocabulary', 'POST', data: vocab.toJson());
  }
}
```

---

## Summary

**Dio:**
- Use `QueuedInterceptor` for auth to prevent concurrent refresh
- Implement exponential backoff for retries
- Handle 401/5xx separately

**Hive:**
- Initialize once at app startup with `initFlutter()`
- Use type-safe box access with generics
- Implement LRU or size-based eviction for cache
- Close all boxes on app termination

**Offline-First:**
- Queue mutations in Hive when offline
- Process queue when connectivity restored
- Cache GET responses for offline access
- Prioritize local-first UX

---

## Unresolved Questions

- Encryption strategy for sensitive cache data?
- Conflict resolution when syncing after long offline period?
- Migration strategy when Hive schema changes?
