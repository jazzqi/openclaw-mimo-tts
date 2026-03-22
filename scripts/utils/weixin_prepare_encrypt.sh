#!/bin/bash
# Prepare file encryption for Weixin CDN upload
# Usage: weixin_prepare_encrypt.sh input_file output_enc_file

set -euo pipefail
INPUT="$1"
OUTPUT_ENC="${2:-${INPUT}.enc}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 input_file [output_enc_file]" >&2
  exit 2
fi

# generate random 16-byte AES key (hex)
HEXKEY=$(openssl rand -hex 16)
# binary key base64
AES_KEY_B64=$(echo "$HEXKEY" | xxd -r -p | base64)

# encrypt with AES-128-ECB (no salt)
openssl enc -aes-128-ecb -nosalt -K "$HEXKEY" -in "$INPUT" -out "$OUTPUT_ENC"

# compute sizes and md5s
# plaintext size & md5
PLAIN_SIZE=$(wc -c < "$INPUT" | tr -d '[:space:]')
PLAIN_MD5=$(python3 - <<PY
import sys,hashlib
fn=sys.argv[1]
with open(fn,'rb') as f:
    d=f.read()
print(hashlib.md5(d).hexdigest())
PY
"$INPUT")
# ciphertext size
CIPHER_SIZE=$(wc -c < "$OUTPUT_ENC" | tr -d '[:space:]')

# output JSON with values (do not print AES key raw hex)
cat <<JSON
{
  "plain_file": "${INPUT}",
  "enc_file": "${OUTPUT_ENC}",
  "plain_size": ${PLAIN_SIZE},
  "plain_md5": "${PLAIN_MD5}",
  "cipher_size": ${CIPHER_SIZE},
  "aes_key_b64": "${AES_KEY_B64}"
}
JSON

exit 0
