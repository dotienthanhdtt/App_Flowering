# Authentication & User API

Base path: `/auth` for authentication, `/users` for user profile
Auth: Auth endpoints are **public** except `POST /auth/logout`. User endpoints require Bearer JWT.

---

## POST /auth/register

Register a new user with email and password.

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "displayName": "John Doe",
  "sessionToken": "uuid-onboarding-session-token"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | string | yes | Valid email address |
| `password` | string | yes | Min 8 characters |
| `displayName` | string | no | User display name |
| `sessionToken` | UUID | no | Onboarding session to link to this account |

**Response 201**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "uuid-tokenId:hex-secret",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "displayName": "John Doe",
      "avatarUrl": null
    }
  }
}
```

**Errors**
- `409` — Email already registered

**curl**
```bash
curl -X POST https://api.example.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"SecurePass123!","displayName":"John Doe"}'
```

---

## POST /auth/login

Login with email and password.

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "sessionToken": "uuid-onboarding-session-token"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | string | yes | Registered email |
| `password` | string | yes | Account password |
| `sessionToken` | UUID | no | Onboarding session to link to this account |

**Response 200** — Same as `/auth/register` response

**Errors**
- `401` — Invalid credentials

**curl**
```bash
curl -X POST https://api.example.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"SecurePass123!"}'
```

---

## POST /auth/google

Sign in with Google ID token (mobile-compatible, no redirect flow).

**Request Body**
```json
{
  "idToken": "google-id-token-from-sdk",
  "displayName": "John Doe",
  "sessionToken": "uuid-onboarding-session-token"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `idToken` | string | yes | Google ID token from Sign in with Google SDK |
| `displayName` | string | no | Override display name |
| `sessionToken` | UUID | no | Onboarding session to link to this account |

**Behavior**
- Validates Google ID token server-side
- If email matches an existing account → auto-links Google provider to it
- If no existing account → creates new user
- Returns JWT tokens

**Response 200** — Same as `/auth/register` response

**Errors**
- `401` — Invalid Google ID token

**curl**
```bash
curl -X POST https://api.example.com/auth/google \
  -H "Content-Type: application/json" \
  -d '{"idToken":"eyJhbGci..."}'
```

---

## POST /auth/apple

Sign in with Apple ID token.

**Request Body**
```json
{
  "idToken": "apple-id-token-from-sdk",
  "displayName": "John Doe",
  "sessionToken": "uuid-onboarding-session-token"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `idToken` | string | yes | Apple ID token from Sign in with Apple |
| `displayName` | string | no | Only available on first Apple sign-in |
| `sessionToken` | UUID | no | Onboarding session to link to this account |

**Behavior** — Same as Google: auto-links on email match, creates if new.

**Response 200** — Same as `/auth/register` response

**Errors**
- `401` — Invalid Apple ID token

**curl**
```bash
curl -X POST https://api.example.com/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"idToken":"eyJhbGci...","displayName":"John Doe"}'
```

---

## POST /auth/refresh

Exchange a refresh token for new access + refresh tokens. Previous refresh token is revoked (rotation).

**Request Body**
```json
{
  "refreshToken": "uuid-tokenId:hex-secret"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `refreshToken` | string | yes | Composite refresh token from a previous auth response |

**Token format:** `{tokenId}:{secret}` — tokenId is a UUID, secret is 64-char hex.

**Response 200** — Same as `/auth/register` response (new tokens issued)

**Errors**
- `401` — Invalid or expired refresh token (90-day expiry)

**curl**
```bash
curl -X POST https://api.example.com/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"550e8400-e29b-41d4-a716-446655440000:abc123..."}'
```

---

## POST /auth/logout

Revoke all refresh tokens for the authenticated user.

**Auth:** Bearer JWT required

**Response 204** — No content

**curl**
```bash
curl -X POST https://api.example.com/auth/logout \
  -H "Authorization: Bearer eyJhbGci..."
```

---

## GET /users/me

Get the authenticated user's profile.

**Auth:** Bearer JWT required

**Response 200**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "displayName": "John Doe",
    "avatarUrl": "https://example.com/avatar.jpg",
    "nativeLanguageId": "uuid",
    "nativeLanguageCode": "en",
    "nativeLanguageName": "English",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

| Field | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID | no | User ID |
| `email` | string | no | User email |
| `displayName` | string | yes | Display name |
| `avatarUrl` | string | yes | Avatar URL |
| `nativeLanguageId` | UUID | yes | Native language ID |
| `nativeLanguageCode` | string | yes | Language code (e.g., "en") |
| `nativeLanguageName` | string | yes | Language name (e.g., "English") |
| `createdAt` | Date | no | Account creation timestamp |

**Errors**
- `404` — User not found

**curl**
```bash
curl https://api.example.com/users/me \
  -H "Authorization: Bearer eyJhbGci..."
```

---

## PATCH /users/me

Update the authenticated user's profile. Only provided fields are updated.

**Auth:** Bearer JWT required

**Request Body**
```json
{
  "displayName": "New Name",
  "avatarUrl": "https://example.com/new-avatar.jpg",
  "nativeLanguageId": "uuid"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `displayName` | string | no | Max 100 characters |
| `avatarUrl` | string | no | New avatar URL |
| `nativeLanguageId` | UUID | no | Valid language UUID |

**Response 200** — Same as `GET /users/me` response (updated profile)

**Errors**
- `404` — User not found

**curl**
```bash
curl -X PATCH https://api.example.com/users/me \
  -H "Authorization: Bearer eyJhbGci..." \
  -H "Content-Type: application/json" \
  -d '{"displayName":"New Name"}'
```

---

## Onboarding Session Linking

When `sessionToken` is passed to any auth endpoint (register, login, google, apple), the anonymous onboarding conversation is linked to the new/existing user account. The session is converted from `ANONYMOUS` to `AUTHENTICATED` type. This is best-effort — failure does not block authentication.
