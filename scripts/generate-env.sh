#!/usr/bin/env bash
# Render .env from .env.template.
#
# Template value directives:
#   @uuid    -> random UUIDv4            (connector IDs, admin token)
#   @hex32   -> 64 hex chars             (shared secrets)
#   @pass    -> 24 hex chars             (service passwords)
#   @base64  -> 32 random bytes, base64  (encryption keys)
#   <empty>  -> left empty               (API-key placeholders you fill in)
#   other    -> copied literally
#
# Idempotent: variables that already have a non-empty value in .env are kept,
# so re-running only adds new variables (e.g. after adding a connector).
#
# Usage: scripts/generate-env.sh [--force]    (--force regenerates everything)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${ROOT}/.env.template"
TARGET="${ROOT}/.env"
FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

[[ -f "$TEMPLATE" ]] || { echo "missing ${TEMPLATE}" >&2; exit 1; }

gen_uuid() { uuidgen | tr '[:upper:]' '[:lower:]'; }
gen_hex32() { openssl rand -hex 32; }
gen_base64() { openssl rand -base64 32; }
gen_pass() { openssl rand -hex 12; }  # 24 hex chars, URL/shell safe

# Value currently set in .env for a key (empty if absent).
existing() {
  [[ -f "$TARGET" ]] || return 0
  grep -E "^${1}=" "$TARGET" | tail -n1 | cut -d= -f2- || true
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
created=0 kept=0

while IFS= read -r line || [[ -n "$line" ]]; do
  # Pass through comments and blank lines untouched.
  if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
    printf '%s\n' "$line" >> "$tmp"; continue
  fi

  key="${line%%=*}"
  tpl="${line#*=}"
  cur="$(existing "$key")"

  if ! $FORCE && [[ -n "$cur" ]]; then
    printf '%s=%s\n' "$key" "$cur" >> "$tmp"; kept=$((kept + 1)); continue
  fi

  case "$tpl" in
    @uuid)   val="$(gen_uuid)" ;;
    @hex32)  val="$(gen_hex32)" ;;
    @pass)   val="$(gen_pass)" ;;
    @base64) val="$(gen_base64)" ;;
    *)       val="$tpl" ;;
  esac
  printf '%s=%s\n' "$key" "$val" >> "$tmp"; created=$((created + 1))
done < "$TEMPLATE"

install -m 600 "$tmp" "$TARGET"
echo "wrote ${TARGET} (${created} generated/set, ${kept} kept)"

# Report API-key placeholders still empty.
missing="$(grep -E '^[A-Z0-9_]*(API_KEY|TOKEN|AUTH_KEY|KEY_ID|KEY_SECRET)=$' "$TARGET" || true)"
if [[ -n "$missing" ]]; then
  echo
  echo "Fill in these API credentials in .env before enabling the matching connector:"
  sed 's/=$//; s/^/  - /' <<< "$missing"
fi
