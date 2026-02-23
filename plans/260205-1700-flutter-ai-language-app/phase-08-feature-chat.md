---
phase: 8
title: "Feature - Chat"
status: pending
effort: 2.5h
depends_on: [7]
---

# Phase 8: Feature - Chat

## Context Links

- [Main Plan](./plan.md)
- [Audio Service](./phase-03-core-services.md)
- Depends on: [Phase 7](./phase-07-feature-home.md)

## Overview

**Priority:** P1 - Core Feature
**Status:** pending
**Description:** Implement AI chat feature with text and voice messaging.

## Key Insights

- Separate controllers for chat logic and voice recording
- Messages cached locally with FIFO eviction
- Voice requires microphone permission
- Offline: queue messages, disable voice

## Requirements

### Functional
- Text chat with AI
- Voice message recording and sending
- Message history display
- Real-time message updates
- Offline message queueing

### Non-Functional
- Messages appear instantly (optimistic UI)
- Audio recording with visual feedback
- Maximum recording time: 60 seconds

## Architecture

```
features/chat/
├── bindings/
│   └── chat_binding.dart
├── controllers/
│   ├── chat_controller.dart
│   └── voice_chat_controller.dart
├── views/
│   └── chat_screen.dart
└── widgets/
    ├── message_bubble.dart
    ├── voice_recorder.dart
    └── chat_input.dart
```

## Related Code Files

### Files to Create
- `lib/features/chat/bindings/chat_binding.dart`
- `lib/features/chat/controllers/chat_controller.dart`
- `lib/features/chat/controllers/voice_chat_controller.dart`
- `lib/features/chat/views/chat_screen.dart`
- `lib/features/chat/widgets/message_bubble.dart`
- `lib/features/chat/widgets/voice_recorder.dart`
- `lib/features/chat/widgets/chat_input.dart`
- `lib/features/chat/models/message_model.dart`

## Implementation Steps

### Step 1: Create message_model.dart

```dart
// lib/features/chat/models/message_model.dart
enum MessageType { text, voice }
enum MessageStatus { sending, sent, failed }
enum MessageSender { user, ai }

class MessageModel {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final MessageStatus status;
  final String? audioUrl;
  final int? audioDuration; // in seconds
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.status,
    this.audioUrl,
    this.audioDuration,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      type: json['type'] == 'voice' ? MessageType.voice : MessageType.text,
      sender: json['sender'] == 'ai' ? MessageSender.ai : MessageSender.user,
      status: MessageStatus.sent,
      audioUrl: json['audio_url'] as String?,
      audioDuration: json['audio_duration'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type == MessageType.voice ? 'voice' : 'text',
      'sender': sender == MessageSender.ai ? 'ai' : 'user',
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    MessageStatus? status,
    String? audioUrl,
    int? audioDuration,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### Step 2: Create chat_binding.dart

```dart
// lib/features/chat/bindings/chat_binding.dart
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/voice_chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<VoiceChatController>(() => VoiceChatController());
  }
}
```

### Step 3: Create chat_controller.dart

```dart
// lib/features/chat/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/message_model.dart';
import 'dart:convert';

class ChatController extends BaseController {
  final ApiClient _api = Get.find();
  final StorageService _storage = Get.find();
  final ConnectivityService _connectivity = Get.find();

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  final messages = <MessageModel>[].obs;
  final isSending = false.obs;

  static const String _cacheKeyPrefix = 'chat_';

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Load messages from cache and server
  Future<void> loadMessages() async {
    await apiCall(
      () async {
        // Load from cache first
        _loadFromCache();

        // Then fetch from server
        if (_connectivity.isOnline) {
          final response = await _api.get<List<dynamic>>(
            ApiEndpoints.chatMessages,
            fromJson: (data) => data as List<dynamic>,
          );

          if (response.isSuccess && response.data != null) {
            messages.value = response.data!
                .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
                .toList();
            _saveToCache();
          }
        }

        return messages;
      },
      showLoading: messages.isEmpty,
    );
  }

  /// Send text message
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    // Create optimistic message
    final userMessage = MessageModel(
      id: const Uuid().v4(),
      content: text,
      type: MessageType.text,
      sender: MessageSender.user,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    messages.add(userMessage);
    _scrollToBottom();

    // Send to server
    isSending.value = true;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: {'message': text},
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Update user message status
        final index = messages.indexWhere((m) => m.id == userMessage.id);
        if (index != -1) {
          messages[index] = userMessage.copyWith(status: MessageStatus.sent);
        }

        // Add AI response
        final aiMessage = MessageModel.fromJson(response.data!);
        messages.add(aiMessage);
        _scrollToBottom();
        _saveToCache();
      } else {
        _markMessageFailed(userMessage.id);
      }
    } catch (e) {
      _markMessageFailed(userMessage.id);
    } finally {
      isSending.value = false;
    }
  }

  /// Send voice message
  Future<void> sendVoiceMessage(String filePath, int duration) async {
    // Create optimistic message
    final userMessage = MessageModel(
      id: const Uuid().v4(),
      content: 'Voice message',
      type: MessageType.voice,
      sender: MessageSender.user,
      status: MessageStatus.sending,
      audioDuration: duration,
      createdAt: DateTime.now(),
    );

    messages.add(userMessage);
    _scrollToBottom();

    isSending.value = true;

    try {
      final response = await _api.uploadFile<Map<String, dynamic>>(
        ApiEndpoints.chatVoice,
        filePath: filePath,
        fieldName: 'audio',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Update user message
        final index = messages.indexWhere((m) => m.id == userMessage.id);
        if (index != -1) {
          messages[index] = userMessage.copyWith(
            status: MessageStatus.sent,
            audioUrl: response.data!['user_audio_url'] as String?,
          );
        }

        // Add AI response
        final aiMessage = MessageModel.fromJson(response.data!['ai_response'] as Map<String, dynamic>);
        messages.add(aiMessage);
        _scrollToBottom();
        _saveToCache();
      } else {
        _markMessageFailed(userMessage.id);
      }
    } catch (e) {
      _markMessageFailed(userMessage.id);
    } finally {
      isSending.value = false;
    }
  }

  /// Retry failed message
  Future<void> retryMessage(String messageId) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];
    messages[index] = message.copyWith(status: MessageStatus.sending);

    if (message.type == MessageType.text) {
      messageController.text = message.content;
      messages.removeAt(index);
      await sendMessage();
    }
  }

  /// Delete message
  void deleteMessage(String messageId) {
    messages.removeWhere((m) => m.id == messageId);
    _saveToCache();
  }

  void _markMessageFailed(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(status: MessageStatus.failed);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadFromCache() {
    final cached = _storage.getChatMessages(_cacheKeyPrefix);
    if (cached.isNotEmpty) {
      try {
        messages.value = cached
            .map((json) => MessageModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  void _saveToCache() {
    for (final message in messages) {
      _storage.saveChatMessage(
        '$_cacheKeyPrefix${message.id}',
        jsonEncode(message.toJson()),
      );
    }
  }
}
```

### Step 4: Create voice_chat_controller.dart

```dart
// lib/features/chat/controllers/voice_chat_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/audio_service.dart';
import 'chat_controller.dart';

class VoiceChatController extends GetxController {
  final AudioService _audioService = Get.find();
  late final ChatController _chatController;

  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  final hasPermission = false.obs;

  Timer? _recordingTimer;
  String? _currentRecordingPath;

  static const int maxRecordingSeconds = 60;

  @override
  void onInit() {
    super.onInit();
    _chatController = Get.find<ChatController>();
    _checkPermission();
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    super.onClose();
  }

  Future<void> _checkPermission() async {
    hasPermission.value = await _audioService.hasRecordPermission();
  }

  /// Start voice recording
  Future<void> startRecording() async {
    if (isRecording.value) return;

    if (!hasPermission.value) {
      hasPermission.value = await _audioService.hasRecordPermission();
      if (!hasPermission.value) {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is needed for voice messages',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    _currentRecordingPath = await _audioService.startRecording();
    if (_currentRecordingPath == null) return;

    isRecording.value = true;
    recordingDuration.value = 0;

    // Start duration timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingDuration.value++;
      if (recordingDuration.value >= maxRecordingSeconds) {
        stopRecording();
      }
    });
  }

  /// Stop recording and send
  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final path = await _audioService.stopRecording();
    isRecording.value = false;

    if (path != null && recordingDuration.value >= 1) {
      await _chatController.sendVoiceMessage(path, recordingDuration.value);
    }

    recordingDuration.value = 0;
  }

  /// Cancel recording without sending
  Future<void> cancelRecording() async {
    if (!isRecording.value) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    await _audioService.cancelRecording();
    isRecording.value = false;
    recordingDuration.value = 0;
  }

  /// Play voice message
  Future<void> playVoiceMessage(String url) async {
    await _audioService.playUrl(url);
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    await _audioService.stop();
  }
}
```

### Step 5: Create chat_screen.dart

```dart
// lib/features/chat/views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../controllers/voice_chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceController = Get.find<VoiceChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('chat'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start a conversation!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return MessageBubble(
                    message: message,
                    onRetry: () => controller.retryMessage(message.id),
                    onPlay: () => voiceController.playVoiceMessage(message.audioUrl!),
                  );
                },
              );
            }),
          ),

          // Input area
          ChatInput(
            controller: controller.messageController,
            onSend: controller.sendMessage,
            onStartRecording: voiceController.startRecording,
            onStopRecording: voiceController.stopRecording,
            onCancelRecording: voiceController.cancelRecording,
            isRecording: voiceController.isRecording,
            recordingDuration: voiceController.recordingDuration,
            isSending: controller.isSending,
          ),
        ],
      ),
    );
  }
}
```

### Step 6: Create message_bubble.dart

```dart
// lib/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onRetry;
  final VoidCallback? onPlay;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onPlay,
  });

  bool get isUser => message.sender == MessageSender.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(),
                const SizedBox(height: 4),
                _buildMeta(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildStatusIcon(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
      child: const Icon(
        Icons.smart_toy,
        size: 18,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.userBubble : AppColors.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: message.type == MessageType.voice
          ? _buildVoiceContent()
          : _buildTextContent(),
    );
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: TextStyle(
        color: isUser ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
      ),
    );
  }

  Widget _buildVoiceContent() {
    return GestureDetector(
      onTap: onPlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color: isUser ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 24,
            decoration: BoxDecoration(
              color: (isUser ? Colors.white : AppColors.primary)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Duration(seconds: message.audioDuration ?? 0).formatted,
            style: TextStyle(
              color: isUser ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta() {
    return Text(
      message.createdAt.timeAgo,
      style: TextStyle(
        color: AppColors.textHint,
        fontSize: 11,
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.done,
          size: 14,
          color: AppColors.success,
        );
      case MessageStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(
            Icons.error,
            size: 14,
            color: AppColors.error,
          ),
        );
    }
  }
}
```

### Step 7: Create chat_input.dart and voice_recorder.dart

```dart
// lib/features/chat/widgets/chat_input.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final RxBool isRecording;
  final RxInt recordingDuration;
  final RxBool isSending;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.isRecording,
    required this.recordingDuration,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          if (isRecording.value) {
            return _buildRecordingUI();
          }
          return _buildInputUI();
        }),
      ),
    );
  }

  Widget _buildInputUI() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'type_message'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 8),
        _buildVoiceButton(),
        const SizedBox(width: 8),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          onPressed: onCancelRecording,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'recording'.tr,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                    Duration(seconds: recordingDuration.value).formatted,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: AppColors.primary),
          onPressed: onStopRecording,
        ),
      ],
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: onStartRecording,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(() => GestureDetector(
          onTap: isSending.value ? null : onSend,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: isSending.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ));
  }
}
```

```dart
// lib/features/chat/widgets/voice_recorder.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';

class VoiceRecorder extends StatelessWidget {
  final RxBool isRecording;
  final RxInt duration;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const VoiceRecorder({
    super.key,
    required this.isRecording,
    required this.duration,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!isRecording.value) {
        return _buildIdleState();
      }
      return _buildRecordingState();
    });
  }

  Widget _buildIdleState() {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic,
          color: AppColors.secondary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildRecordingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          _buildWaveform(),
          const SizedBox(width: 12),
          Obx(() => Text(
                Duration(seconds: duration.value).formatted,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onStop,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      children: List.generate(
        8,
        (index) => Container(
          width: 3,
          height: 8 + (index % 3) * 6.0,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
```

## Todo List

- [ ] Create message_model.dart
- [ ] Create chat_binding.dart
- [ ] Create chat_controller.dart with messaging logic
- [ ] Create voice_chat_controller.dart
- [ ] Create chat_screen.dart
- [ ] Create message_bubble.dart
- [ ] Create chat_input.dart
- [ ] Create voice_recorder.dart
- [ ] Update app_pages.dart
- [ ] Test text messaging
- [ ] Test voice recording
- [ ] Test offline queueing

## Success Criteria

- Text messages send and display correctly
- AI responses appear after user message
- Voice recording with visual feedback
- Failed messages show retry option
- Messages persist across sessions
- Scroll to bottom on new message

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Audio permission denied | Medium | Show permission dialog, fallback to text |
| Large voice files | Medium | Limit to 60 seconds, compress |
| Message order issues | Low | Sort by createdAt |

## Security Considerations

- Audio files deleted after upload
- Messages cached locally only
- No sensitive data in message content

## Next Steps

After completion, proceed to [Phase 9: Lessons Feature](./phase-09-feature-lessons.md).
