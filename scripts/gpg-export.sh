#!/usr/bin/env bash
# Export and symmetrically encrypt your GPG private key for OFFLINE backup.
# Run this on a machine that already holds the key, then store the output
# somewhere private (1Password, encrypted USB, private cloud — NOT this repo).
#
# Usage:
#   ./scripts/gpg-export.sh [KEY_ID] [OUTPUT_PATH]
#     KEY_ID      — key ID/fingerprint/email. Defaults to the first secret key.
#     OUTPUT_PATH — where to write the encrypted file. Defaults to ./secret.gpg.
#                   The output path MUST NOT be inside this dotfiles repo.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

KEY_ID="${1:-}"
OUTPUT="${2:-$PWD/secret.gpg}"

# Refuse to write the encrypted key back into the public dotfiles repo.
output_abs="$(cd "$(dirname "$OUTPUT")" 2>/dev/null && pwd)/$(basename "$OUTPUT")"
if [[ "$output_abs" == "$DOTFILES_DIR"* ]]; then
  echo "[FAIL] Refusing to write encrypted secret into the dotfiles repo." >&2
  echo "       Pass an OUTPUT_PATH outside $DOTFILES_DIR." >&2
  exit 1
fi

if [[ -z "$KEY_ID" ]]; then
  KEY_ID="$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null \
    | awk '/^sec/{split($2,a,"/"); print a[2]; exit}')"
  if [[ -z "$KEY_ID" ]]; then
    echo "[FAIL] No GPG secret keys found in keyring." >&2
    exit 1
  fi
fi

echo "[INFO] Exporting GPG key: $KEY_ID"
echo "[INFO] Output: $OUTPUT"
echo ""
echo "You will be prompted for a strong passphrase (twice) for AES256 encryption."
echo ""

gpg --export-secret-keys --armor "$KEY_ID" \
  | gpg --symmetric \
        --cipher-algo AES256 \
        --s2k-mode 3 --s2k-count 65011712 \
        --armor \
        --output "$OUTPUT"

echo ""
echo "[  OK] Encrypted key written to: $OUTPUT"
echo ""
echo "Store this file in a PRIVATE location (1Password / encrypted USB / private cloud)."
echo "On a new machine, retrieve it and run:"
echo "  ./scripts/gpg-import.sh /path/to/secret.gpg"
