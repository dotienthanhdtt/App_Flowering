# Phase 1: Models - fromJson/toJson Migration

## Overview
- **Priority:** P1
- **Status:** pending
- Update all JSON key strings in model `fromJson` factories and `toJson` methods.

## Key Insight: API structural changes beyond casing

The new API doc reveals some fields were **renamed**, not just re-cased. These need special attention:

| Old key (Flutter) | New API key | File | Notes |
|---|---|---|---|
| `displayName` | `name` | UserModel | Field name change, not just casing |
| `avatarUrl` | `profile_picture` | UserModel | Complete rename |
| `nativeLanguageId/Code/Name` | - | UserModel | Not in new API user response; may be removed |
| `createdAt` | `created_at` | UserModel | Simple re-case |
| `accessToken` | `access_token` | AuthResponse | Simple re-case |
| `refreshToken` | `refresh_token` | AuthResponse | Simple re-case |
| `nativeName` | `native_name` | OnboardingLanguage | Simple re-case |
| `flagUrl` | `flag_url` | OnboardingLanguage | Simple re-case |
| `isNativeAvailable` | `is_active` | OnboardingLanguage | Rename + semantic change |
| `isLearningAvailable` | `is_active` | OnboardingLanguage | Rename + semantic change |
| `isEnabled` | `is_active` | OnboardingLanguage | Rename (cache format) |
| `accentColor` | `accent_color` | Scenario | Simple re-case |
| `imageUrl` | `image_url` | Scenario | Simple re-case |
| `expiresAt` | - | SubscriptionModel | Not in new API; replaced by `current_period_end` |
| `isActive` | `is_active` | SubscriptionModel | Simple re-case |
| `cancelAtPeriodEnd` | `cancel_at_period_end` | SubscriptionModel | Simple re-case |
| `partOfSpeech` | - | WordTranslationModel | Not in new API translate response |
| `vocabularyId` | - | WordTranslationModel | Not in new API translate response |
| `messageId` | `message_id` | SentenceTranslationModel | Simple re-case |
| `sessionToken` | `session_id` | OnboardingSession | Rename |
| `messageId` | - | OnboardingSession | Not in new API |
| `turnNumber` | `turn_count` | OnboardingSession | Rename |
| `isLastTurn` | - | OnboardingSession | Not in new API; derive from `turn_count >= max_turns` |
| `reply` / `floraMessage` | `response` | OnboardingSession | Rename |
| `quickReplies` | - | OnboardingSession | Not in new API |
| `userId` | - | OnboardingProfile | Replaced by `extracted_profile` |

---

## File-by-file changes

### 1. `lib/shared/models/user_model.dart`

**fromJson changes:**
```
json['displayName']        -> json['name']
json['avatarUrl']          -> json['profile_picture']
json['nativeLanguageId']   -> REMOVE (not in API response)
json['nativeLanguageCode'] -> REMOVE
json['nativeLanguageName'] -> REMOVE
json['createdAt']          -> json['created_at']
```
Add new fields from API: `email_verified`, `updated_at`

**toJson changes:** Mirror the fromJson key changes.

**DECISION NEEDED:** The `nativeLanguageId/Code/Name` fields are not in the new `/users/me` response. They may come from a different endpoint or be removed. Keep Dart properties if used elsewhere but remove from fromJson/toJson, or add fallback.

---

### 2. `lib/features/auth/models/auth_response_model.dart`

**fromJson changes:**
```
json['accessToken']  -> json['access_token']
json['refreshToken'] -> json['refresh_token']
```

---

### 3. `lib/features/onboarding/models/onboarding_language_model.dart`

**fromJson changes:**
```
json['isNativeAvailable']  -> json['is_active'] (when type == 'native')
json['isLearningAvailable'] -> json['is_active'] (when type == 'learning')
json['isEnabled']          -> json['is_active'] (cache format)
json['flagUrl']            -> json['flag_url']
json['nativeName']         -> json['native_name']
```

**toJson changes:**
```
'flagUrl'    -> 'flag_url'
'isEnabled'  -> 'is_active'
```
Keep `subtitle` as local cache field (mapped from `native_name`).

---

### 4. `lib/features/onboarding/models/onboarding_session_model.dart`

**Major restructure needed.** New API contract:
- `/onboarding/start` returns: `{ "session_id": "token", "expires_at": "..." }`
- `/onboarding/chat` returns: `{ "response": "...", "turn_count": 2, "max_turns": 10 }`
- `/onboarding/complete` returns: `{ "extracted_profile": { ... } }`

**fromJson changes:**
```
json['sessionToken']  -> json['session_id']
json['messageId']     -> REMOVE
json['turnNumber']    -> json['turn_count']
json['isLastTurn']    -> derive: json['turn_count'] >= json['max_turns']
json['reply']         -> json['response']
json['floraMessage']  -> REMOVE
json['quickReplies']  -> REMOVE (not in new API)
```

Add new field: `maxTurns` (from `max_turns`), `expiresAt` (from `expires_at`)

---

### 5. `lib/features/onboarding/models/onboarding_profile_model.dart`

**fromJson changes:**
```
json['userId']     -> REMOVE
json['scenarios']  -> json['extracted_profile'] (structure changed)
json['preferences'] -> REMOVE
```

New API returns `extracted_profile` with `languages`, `interests`, `level`. This is a structural change -- the model needs redesign to match.

---

### 6. `lib/features/onboarding/models/scenario_model.dart`

**fromJson changes:**
```
json['accentColor'] -> json['accent_color']
json['imageUrl']    -> json['image_url']
```

**Note:** Scenarios are not in the new API's `/onboarding/complete` response. They may come from a different endpoint. Verify before removing.

---

### 7. `lib/features/subscription/models/subscription-model.dart`

**fromJson changes:**
```
json['expiresAt']          -> json['current_period_end'] (also add 'current_period_start')
json['isActive']           -> json['is_active']
json['cancelAtPeriodEnd']  -> json['cancel_at_period_end']
```

**toJson changes:**
```
'expiresAt'          -> 'current_period_end'
'isActive'           -> 'is_active'
'cancelAtPeriodEnd'  -> 'cancel_at_period_end'
```

Add new field: `currentPeriodStart` from `current_period_start`.

---

### 8. `lib/shared/models/word-translation-model.dart`

**fromJson changes:**
```
json['partOfSpeech']  -> json['part_of_speech'] (keep if backend still sends it)
json['vocabularyId']  -> json['vocabulary_id'] (keep if backend still sends it)
```

New API translate response for words: `{ "translation", "word", "pronunciation" }`. Field `original` maps to `word`. Fields `definition`, `examples` not in new API doc.

---

### 9. `lib/shared/models/sentence-translation-model.dart`

**fromJson changes:**
```
json['messageId'] -> json['message_id']
```

New API returns `translated_content` instead of `translation`:
```
json['translation'] -> json['translated_content']
```

---

## Cache Migration Strategy

For Hive-cached models (OnboardingLanguage, SubscriptionModel), add backward-compatible fallback reads:

```dart
// Example: read new key, fall back to old key
isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? false,
```

This allows the app to read old cached data without crashing during the transition period. Optionally clear cache on first launch after update.

---

## Todo

- [ ] Update UserModel fromJson/toJson
- [ ] Update AuthResponse fromJson
- [ ] Update OnboardingLanguage fromJson/toJson
- [ ] Update OnboardingSession fromJson (major restructure)
- [ ] Update OnboardingProfile fromJson (major restructure)
- [ ] Update Scenario fromJson
- [ ] Update SubscriptionModel fromJson/toJson
- [ ] Update WordTranslationModel fromJson
- [ ] Update SentenceTranslationModel fromJson
- [ ] Add backward-compat fallbacks for cached models
- [ ] Verify: are `nativeLanguageId/Code/Name` still needed in UserModel?
- [ ] Verify: are `scenarios` still returned from onboarding/complete?
- [ ] Verify: does translate endpoint still return `partOfSpeech`, `definition`, `examples`?

## Unresolved Questions

1. **UserModel native language fields** -- not in `/users/me` API response. Are they fetched from a different endpoint now? Or removed?
2. **OnboardingProfile restructure** -- old model had `scenarios` list; new API returns `extracted_profile` with different shape. Is the Scenario model still used elsewhere?
3. **WordTranslation missing fields** -- `partOfSpeech`, `definition`, `examples` not documented in new API. Removed or just undocumented?
4. **QuickReplies** -- removed from onboarding chat response. Is this intentional? UI currently shows quick reply chips.
