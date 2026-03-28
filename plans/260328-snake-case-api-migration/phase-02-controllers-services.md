# Phase 2: Controllers & Services - Request Payload Migration

## Overview
- **Priority:** P1
- **Status:** pending
- Update all outbound request body keys from camelCase to snake_case.

---

## File-by-file changes

### 1. `lib/features/auth/controllers/auth_controller.dart`

**register() payload (line 71-75):**
```
'fullName'     -> 'name' (API uses 'name', not 'full_name')
'sessionToken' -> 'session_token'
```

**login() payload (line 101-104):**
```
'sessionToken' -> 'session_token'
```

---

### 2. `lib/features/auth/controllers/forgot_password_controller.dart`

**verifyOtp() response parsing (line 120):**
```
response.data!['resetToken'] -> response.data!['reset_token']
```

**resetPassword() payload (line 142-143):**
```
'resetToken'   -> 'reset_token'
'newPassword'  -> 'new_password'
```

---

### 3. `lib/features/chat/controllers/ai_chat_controller.dart`

**_startSession() payload (line 57-59):**
```
'nativeLanguage' -> 'native_language'
'targetLanguage' -> 'target_language'
```

**sendMessage() payload (line 105):**
```
'sessionToken' -> 'session_id'
```

**toggleTranslation() payload (line 148-152):**
```
'messageId'    -> 'message_id'
'sourceLang'   -> 'source_lang'
'targetLang'   -> 'target_lang'
'sessionToken' -> 'session_token'
```

**_checkGrammar() payload (line 255-258):**
```
'previousAiMessage' -> 'previous_ai_message'
'userMessage'       -> 'user_message'
'targetLanguage'    -> 'target_language'
```

**_checkGrammar() response parsing (line 262):**
```
response.data!['correctedText'] -> response.data!['corrected_text']
```

**_completeOnboarding() payload (line 283):**
```
'sessionToken' -> 'session_id'
```

---

### 4. `lib/core/services/translation-service.dart`

**translateWord() payload (line 28-32):**
```
'sourceLang'   -> 'source_lang'
'targetLang'   -> 'target_lang'
'sessionToken' -> 'session_token'
```

**translateSentence() payload (line 63-66):**
```
'messageId'    -> 'message_id'
'sourceLang'   -> 'source_lang'
'targetLang'   -> 'target_lang'
'sessionToken' -> 'session_token'
```

---

## Todo

- [ ] Update AuthController register() payload
- [ ] Update AuthController login() payload
- [ ] Update ForgotPasswordController verifyOtp() response parsing
- [ ] Update ForgotPasswordController resetPassword() payload
- [ ] Update AiChatController _startSession() payload
- [ ] Update AiChatController sendMessage() payload
- [ ] Update AiChatController toggleTranslation() payload
- [ ] Update AiChatController _checkGrammar() payload + response
- [ ] Update AiChatController _completeOnboarding() payload
- [ ] Update TranslationService translateWord() payload
- [ ] Update TranslationService translateSentence() payload
