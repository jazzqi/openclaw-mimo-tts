#!/bin/bash
# High-level: synthesize text OR send existing audio file -> encode -> encrypt -> upload via weixin plugin -> send as voice bubble
# Usage:
#   mimo_send_weixin_voice.sh "文本内容" [to_user_id]
#   mimo_send_weixin_voice.sh /path/to/input.wav [to_user_id]

set -euo pipefail
ARG1="${1:-}"
TO_USER_ID="${2:-}"

if [ -z "$ARG1" ]; then
  echo "Usage: $0 \"文本内容\" | /path/to/input.wav [to_user_id]"
  exit 2
fi

# default to current account userId
if [ -z "$TO_USER_ID" ]; then
  TO_USER_ID=$(python3 - <<PY
import json,os
ac=os.path.expanduser('~/.openclaw/openclaw-weixin/accounts/e182ae9e613f-im-bot.json')
print(json.load(open(ac))['userId'])
PY
)
fi

WORKDIR="/tmp"
TIMESTAMP=$(date +%s)

# Helper: cleanup sensitive files
cleanup() {
  [ -n "${OUT_ENC:-}" ] && (shred -u "$OUT_ENC" || rm -f "$OUT_ENC") || true
}
trap cleanup EXIT

if [ -f "$ARG1" ]; then
  # Input is a file. Prefer WAV -> PCM -> SILK path.
  INFILE="$ARG1"
  IN_LC=$(echo "$INFILE" | tr '[:upper:]' '[:lower:]')
  BASENAME="mimo_send_weixin_${TIMESTAMP}"
  if [[ "$IN_LC" == *.wav ]]; then
    PCM="$WORKDIR/${BASENAME}.s16"
    SILK="$WORKDIR/${BASENAME}.silk"
    ENC="$SILK.enc"
    # extract PCM 16k mono s16le
    ffmpeg -y -i "$INFILE" -ar 16000 -ac 1 -f s16le "$PCM"
    # encode to SILK using pysilk cython backend
    ~/.openclaw/venvs/silk-venv/bin/python - <<PY
from pysilk.backends.cython import encode
with open('$PCM','rb') as fin, open('$SILK','wb') as fout:
    encode(fin,fout,16000,24000)
print('OK')
PY
    # prepare encryption
    PREP_JSON=$(. ~/.profile 2>/dev/null; ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_prepare_encrypt.sh "$SILK" "${SILK}.enc")
    AES_KEY_B64=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_b64'])")
    AES_KEY_HEX=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_hex'])")
    OUT_ENC="${SILK}.enc"
    # compute playtime (ms) from PCM
    PLAY_MS=$(python3 - <<PY
import os
s=os.path.getsize('$PCM')
print(int(s / (16000 * 1 * 2) * 1000))
PY
)
    # upload and send (pass plaintext path and playtime)
    ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_upload_and_send.sh "$OUT_ENC" "$AES_KEY_B64" "$TO_USER_ID" "$PCM" "$AES_KEY_HEX" "file_${TIMESTAMP}" "$PLAY_MS"
    # cleanup
    rm -f "$SILK" "$PCM"
  else
    # fallback: for other file types (ogg/amr) use existing flow: convert to AMR-NB 8k
    OUT_OGG="$WORKDIR/${BASENAME}.ogg"
    OUT_AMR="$WORKDIR/${BASENAME}.amr"
    OUT_ENC="$OUT_AMR.enc"
    # copy/convert input to ogg if needed
    ffmpeg -y -i "$INFILE" -ac 1 -ar 48000 -c:a libopus "$OUT_OGG"
    ffmpeg -y -i "$OUT_OGG" -ac 1 -ar 8000 -c:a libopencore_amrnb "$OUT_AMR" 2>/dev/null
    PREP_JSON=$(. ~/.profile 2>/dev/null; ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_prepare_encrypt.sh "$OUT_AMR" "$OUT_ENC")
    AES_KEY_B64=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_b64'])")
    AES_KEY_HEX=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_hex'])")
    PLAY_MS=$(python3 - <<PY
import os
s=os.path.getsize('$OUT_AMR')
# AMR NB at 8000 Hz, 1 channel, 16-bit samples packed differently; approximate duration via file size/bytes_per_second
# For AMR, estimate using original source duration via ffprobe
import subprocess,sys
try:
    p=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1','$OUT_OGG'], capture_output=True, text=True)
    dur=float(p.stdout.strip())
    print(int(dur*1000))
except:
    print(0)
PY
)
    ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_upload_and_send.sh "$OUT_ENC" "$AES_KEY_B64" "$TO_USER_ID" "$OUT_AMR" "$AES_KEY_HEX" "file_${TIMESTAMP}" "$PLAY_MS"
    rm -f "$OUT_OGG" "$OUT_AMR"
  fi
else
  # ARG1 is text: synthesize then follow original path (OGG -> AMR -> encrypt -> upload)
  TEXT="$ARG1"
  BASENAME="mimo_send_weixin_${TIMESTAMP}"
  OUT_OGG="$WORKDIR/${BASENAME}.ogg"
  OUT_AMR="$WORKDIR/${BASENAME}.amr"
  OUT_ENC="$OUT_AMR.enc"

  # synthesize using Python smart implementation (avoid NodeJS DRY bug)
  python3 ~/.openclaw/skills/xiaomi-mimo-tts/scripts/smart/mimo_tts_smart.py "<style>普通话 朗读</style>$TEXT" "$OUT_OGG"

  # convert to AMR NB 8k
  ffmpeg -y -i "$OUT_OGG" -ac 1 -ar 8000 -c:a libopencore_amrnb "$OUT_AMR" 2>/dev/null

  # prepare encryption
  PREP_JSON=$(. ~/.profile 2>/dev/null; ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_prepare_encrypt.sh "$OUT_AMR" "$OUT_ENC")
  AES_KEY_B64=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_b64'])")
  AES_KEY_HEX=$(echo "$PREP_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin)['aes_key_hex'])")

  # compute playtime using ffprobe
  PLAY_MS=$(python3 - <<PY
import subprocess
try:
    p=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1', '$OUT_OGG'], capture_output=True, text=True)
    dur=float(p.stdout.strip())
    print(int(dur*1000))
except:
    print(0)
PY
)

  # upload and send
  ~/.openclaw/skills/xiaomi-mimo-tts/scripts/utils/weixin_upload_and_send.sh "$OUT_ENC" "$AES_KEY_B64" "$TO_USER_ID" "$OUT_AMR" "$AES_KEY_HEX" "file_${TIMESTAMP}" "$PLAY_MS"

  # cleanup
  rm -f "$OUT_AMR" "$OUT_OGG"
fi

exit 0
