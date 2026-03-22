#!/bin/bash
# High-level: synthesize text -> encode -> encrypt -> upload via weixin plugin -> send as voice bubble
# Usage: mimo_send_weixin_voice.sh "文本内容" [to_user_id]

set -euo pipefail
TEXT="$1"
TO_USER_ID="${2:-}"

if [ -z "$TEXT" ]; then
  echo "Usage: $0 \"文本内容\" [to_user_id]"
  exit 2
fi

# default to current account userId
if [ -z "$TO_USER_ID" ]; then
  TO_USER_ID=$(python3 - <<PY
import json
ac='~/.openclaw/openclaw-weixin/accounts/e182ae9e613f-im-bot.json'
print(json.load(open(ac))['userId'])
PY
)
fi

OUT_OGG="/tmp/mimo_send_weixin_$(date +%s).ogg"
OUT_AMR="${OUT_OGG%.ogg}.amr"
OUT_ENC="${OUT_AMR}.enc"

# synthesize using smart entry
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo-tts-smart.sh "<style>普通话 朗读</style>$TEXT" "$OUT_OGG"

# convert to AMR NB 8k
ffmpeg -y -i "$OUT_OGG" -ac 1 -ar 8000 -c:a libopencore_amrnb "$OUT_AMR" 2>/dev/null

# prepare encryption
PREP_JSON=$(~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_prepare_encrypt.sh "$OUT_AMR" "$OUT_ENC")
AES_KEY_B64=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_b64'])")

# upload and send
~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_upload_and_send.sh "$OUT_ENC" "$AES_KEY_B64" "$TO_USER_ID"

# cleanup sensitive files
shred -u "$OUT_ENC" || rm -f "$OUT_ENC"
rm -f "$OUT_AMR" "$OUT_OGG"

exit 0
