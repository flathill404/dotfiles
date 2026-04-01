#!/usr/bin/env bash
# Export and symmetrically encrypt your GPG private key for storage in dotfiles.
# Run this once on a machine that already has the key, then commit the output.
#
# Usage:
#   ./scripts/gpg-export.sh [KEY_ID]
#   KEY_ID — GPG key ID, fingerprint, or email. Defaults to the first secret key.
#
# Output:
#   gnupg/private-key.gpg.asc  (symmetrically AES256-encrypted, ASCII-armored)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$DOTFILES_DIR/gnupg/private-key.gpg.asc"

# ── Determine key to export ──────────────────────────────────────────────────

KEY_ID="${1:-}"

if [[ -z "$KEY_ID" ]]; then
  # Pick the first available secret key
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
echo "You will be prompted twice:"
echo "  1. Passphrase for the symmetric encryption (choose a strong one)"
echo "  2. Confirmation of that passphrase"
echo ""

mkdir -p "$DOTFILES_DIR/gnupg"

gpg --export-secret-keys --armor "$KEY_ID" \
  | gpg --symmetric \
        --cipher-algo AES256 \
        --armor \
        --output "$OUTPUT"

echo ""
echo "[  OK] Encrypted key written to gnupg/private-key.gpg.asc"
echo ""
echo "Next steps:"
echo "  git add gnupg/private-key.gpg.asc"
echo "  git commit -m 'feat(gnupg): add encrypted GPG private key'"
