#!/usr/bin/env bash
# Decrypt and import a GPG private key previously exported by gpg-export.sh.
# Retrieve the encrypted file from your private storage (1Password, USB,
# private cloud) before running.
#
# Usage:
#   ./scripts/gpg-import.sh [INPUT_PATH]
#     INPUT_PATH — path to the encrypted file. Defaults to ./secret.gpg.

set -euo pipefail

INPUT="${1:-$PWD/secret.gpg}"

if [[ ! -f "$INPUT" ]]; then
  echo "[FAIL] File not found: $INPUT" >&2
  echo "       Retrieve secret.gpg from your private storage and pass its path." >&2
  exit 1
fi

# Skip if a secret key is already in the keyring.
if gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -q "^sec"; then
  echo "[  OK] GPG secret key already in keyring — skipping import"
  exit 0
fi

echo "[INFO] Decrypting and importing: $INPUT"
echo "[INFO] You will be prompted for the passphrase used during export."
echo ""

if gpg --decrypt "$INPUT" 2>/dev/null | gpg --import; then
  echo ""
  echo "[  OK] GPG private key imported successfully"
  echo ""
  echo "Next steps:"
  echo "  1. Get the full fingerprint:"
  echo "       gpg --list-secret-keys --keyid-format LONG"
  echo "  2. Add it to ~/.gitconfig.local:"
  echo "       [user]"
  echo "           signingkey = <full-fingerprint>"
  echo "  3. Register the public key on GitHub:"
  echo "       gpg --armor --export <fingerprint> | gh gpg-key add -"
else
  echo "[FAIL] Import failed (wrong passphrase or corrupt file)" >&2
  exit 1
fi
