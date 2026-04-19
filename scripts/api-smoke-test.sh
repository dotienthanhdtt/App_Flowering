#!/usr/bin/env bash
# API smoke test — hits endpoints that Flutter client consumes.
# Usage: BASE_URL=https://api.flowering.app ACCESS_TOKEN=xxx ./scripts/api-smoke-test.sh [--include-ai]
#
# Tiers:
#   1 Public (no auth)
#   2 Authed read-only (Bearer)
#   3 Authed content (Bearer + X-Learning-Language)
#   4 AI endpoints (cost $ — gated by --include-ai)
#
# Pass = HTTP 2xx AND body.code == 1. No writes to user data.

BASE_URL="${BASE_URL:?BASE_URL env var required}"
ACCESS_TOKEN="${ACCESS_TOKEN:-}"
LEARNING_LANG="${LEARNING_LANG:-en}"
INCLUDE_AI=0
[[ "${1:-}" == "--include-ai" ]] && INCLUDE_AI=1

PASS=0
FAIL=0
SKIP=0
FAIL_DETAILS=()

C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_DIM="\033[2m"
C_RESET="\033[0m"

# hit <tier> <method> <path> <needs_auth> <needs_lang> [body]
hit() {
  local tier="$1" method="$2" path="$3" auth="$4" lang="$5" body="${6:-}"
  local url="${BASE_URL}${path}"
  local auth_hdr=() lang_hdr=() body_arg=()

  if [[ "$auth" == "1" ]]; then
    if [[ -z "$ACCESS_TOKEN" ]]; then
      SKIP=$((SKIP+1))
      printf "  ${C_YELLOW}SKIP${C_RESET} [%s] %-6s %s ${C_DIM}(no ACCESS_TOKEN)${C_RESET}\n" "$tier" "$method" "$path"
      return
    fi
    auth_hdr=(-H "Authorization: Bearer ${ACCESS_TOKEN}")
  fi
  [[ "$lang" == "1" ]] && lang_hdr=(-H "X-Learning-Language: ${LEARNING_LANG}")
  [[ -n "$body" ]] && body_arg=(-H "Content-Type: application/json" --data "$body")

  local tmp; tmp=$(mktemp)
  local start=$(python3 -c 'import time;print(int(time.time()*1000))')
  local http_code
  http_code=$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
    -H "Accept: application/json" \
    "${auth_hdr[@]}" "${lang_hdr[@]}" "${body_arg[@]}" \
    --max-time 30 2>/dev/null || echo "000")
  local end=$(python3 -c 'import time;print(int(time.time()*1000))')
  local elapsed=$((end-start))

  local body_code
  body_code=$(jq -r '.code // empty' < "$tmp" 2>/dev/null || echo "")
  local body_msg
  body_msg=$(jq -r '.message // empty' < "$tmp" 2>/dev/null || echo "")

  if [[ "$http_code" =~ ^2 ]] && [[ "$body_code" == "1" ]]; then
    PASS=$((PASS+1))
    printf "  ${C_GREEN}PASS${C_RESET} [%s] %-6s %-50s ${C_DIM}%sms%s${C_RESET}\n" "$tier" "$method" "$path" "$elapsed" ""
  else
    FAIL=$((FAIL+1))
    local snippet
    snippet=$(head -c 200 "$tmp" | tr '\n' ' ')
    printf "  ${C_RED}FAIL${C_RESET} [%s] %-6s %-50s ${C_DIM}http=%s code=%s %sms${C_RESET}\n" \
      "$tier" "$method" "$path" "$http_code" "${body_code:-∅}" "$elapsed"
    printf "       ${C_DIM}msg: %s${C_RESET}\n" "${body_msg:-$snippet}"
    FAIL_DETAILS+=("$method $path → http=$http_code code=${body_code:-∅} msg=${body_msg:-$snippet}")
  fi
  rm -f "$tmp"
}

echo "================================================================"
echo "API smoke — ${BASE_URL}"
echo "Auth: $([[ -n "$ACCESS_TOKEN" ]] && echo "YES (${#ACCESS_TOKEN} chars)" || echo "NONE")"
echo "Learning lang: ${LEARNING_LANG}  |  Include AI: $([[ $INCLUDE_AI == 1 ]] && echo yes || echo no)"
echo "================================================================"

echo
echo "── Tier 1: Public ──────────────────────────────────────────────"
hit T1 GET  "/languages?type=native"   0 0
hit T1 GET  "/languages?type=learning" 0 0
hit T1 GET  "/languages"               0 0
hit T1 POST "/onboarding/chat"         0 0 '{"nativeLanguage":"vi","targetLanguage":"en"}'

echo
echo "── Tier 2: Authed read-only ────────────────────────────────────"
hit T2 GET  "/users/me"          1 0
hit T2 GET  "/languages/user"    1 0
hit T2 GET  "/subscriptions/me"  1 0

echo
echo "── Tier 3: Authed content ──────────────────────────────────────"
if [[ -n "$ACCESS_TOKEN" ]]; then
  enrolled=$(curl -sS -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "${BASE_URL}/languages/user" 2>/dev/null \
    | jq -r '(.data // []) | map(.language_code // .code // .language.code // empty) | .[0] // empty')
  if [[ -n "$enrolled" ]]; then
    LEARNING_LANG="$enrolled"
    echo "  ${C_DIM}using enrolled language: ${LEARNING_LANG}${C_RESET}"
    hit T3 GET "/lessons" 1 1
  else
    SKIP=$((SKIP+1))
    printf "  ${C_YELLOW}SKIP${C_RESET} [T3] GET    /lessons %s${C_DIM}(no enrolled languages for this user)${C_RESET}\n" "                                             "
  fi
else
  SKIP=$((SKIP+1))
  printf "  ${C_YELLOW}SKIP${C_RESET} [T3] GET    /lessons ${C_DIM}(no ACCESS_TOKEN)${C_RESET}\n"
fi

if [[ $INCLUDE_AI == 1 ]]; then
  echo
  echo "── Tier 4: AI (real cost) ──────────────────────────────────────"
  hit T4 POST "/ai/translate"    1 1 '{"type":"word","text":"hello","sourceLang":"en","targetLang":"vi"}'
  hit T4 POST "/ai/chat/correct" 1 1 '{"previousAiMessage":"How are you today?","userMessage":"I is fine","targetLanguage":"en"}'
else
  echo
  echo "── Tier 4: AI ─ ${C_YELLOW}skipped${C_RESET} (pass --include-ai to enable)"
fi

echo
echo "================================================================"
TOTAL=$((PASS+FAIL))
if [[ $FAIL -eq 0 ]]; then
  printf "${C_GREEN}ALL PASS${C_RESET}  %d/%d (skipped: %d)\n" "$PASS" "$TOTAL" "$SKIP"
  exit 0
else
  printf "${C_RED}FAILED${C_RESET}  pass=%d fail=%d skip=%d\n" "$PASS" "$FAIL" "$SKIP"
  echo
  echo "Failures:"
  for d in "${FAIL_DETAILS[@]}"; do echo "  - $d"; done
  exit 1
fi
