#!/bin/bash
# Upload encrypted file to Weixin CDN and send as voice message via openclaw-weixin backend
# Usage: weixin_upload_and_send.sh enc_file aes_key_b64 to_user_id filekey [aes_hex] [filekey_override] [playtime_ms]

set -euo pipefail
ENC_FILE="$1"
AES_KEY_B64="$2"
TO_USER_ID="$3"
PLAIN_FILEPATH="${4:-}"
AES_HEX_PARAM="${5:-}"
FILEKEY="${6:-file-$(date +%s)}"
PLAY_MS="${7:-}"

# load account token and baseUrl
ACCT_JSON=$(python3 - <<PY
import os
print(os.path.expanduser('~/.openclaw/openclaw-weixin/accounts/e182ae9e613f-im-bot.json'))
PY
)
TOKEN=$(python3 - <<PY
import json
ac='$ACCT_JSON'
print(json.load(open(ac))['token'])
PY
)
BASEURL=$(python3 - <<PY
import json
ac='$ACCT_JSON'
print(json.load(open(ac))['baseUrl'])
PY
)
# try to read cdnBaseUrl from account file; fall back to known default
CDN_BASE_URL=$(python3 - <<PY
import json,os
ac='$ACCT_JSON'
try:
    j=json.load(open(ac))
    cb=j.get('cdnBaseUrl') or ''
    if cb:
        print(cb.rstrip('/'))
    else:
        print('https://novac2c.cdn.weixin.qq.com/c2c')
except Exception:
    print('https://novac2c.cdn.weixin.qq.com/c2c')
PY
)

# compute ciphertext size
CIPHER_SIZE=$(wc -c < "$ENC_FILE" | tr -d '[:space:]')

# prepare request body for getUploadUrl
# compute plaintext size and md5 if original path provided
RAWSIZE=0
RAWMD5=""
if [ -n "$PLAIN_FILEPATH" ] && [ -f "$PLAIN_FILEPATH" ]; then
  RAWSIZE=$(wc -c < "$PLAIN_FILEPATH" | tr -d '[:space:]')
  RAWMD5=$(python3 -c "import hashlib,sys;print(hashlib.md5(open(sys.argv[1],'rb').read()).hexdigest())" "$PLAIN_FILEPATH")
fi

# Build JSON body for getUploadUrl — use environment variables to avoid shell formatting issues
export RAWSIZE="$RAWSIZE"
export RAWMD5="$RAWMD5"
export FILESIZE="$CIPHER_SIZE"
export AES_HEX="$AES_HEX_PARAM"

REQ=$(python3 - <<PY
import json,os
body={
  'filekey': os.getenv('FILEKEY') or '',
  'media_type': 4,
  'to_user_id': os.getenv('TO_USER_ID') or '',
  'rawsize': int(os.getenv('RAWSIZE','0')),
  'rawfilemd5': os.getenv('RAWMD5',''),
  'filesize': int(os.getenv('FILESIZE','0')),
  'thumb_rawsize': 0,
  'thumb_rawfilemd5': '',
  'thumb_filesize': 0,
  'base_info': {}
}
# include aeskey if provided (hex string)
AES_HEX = os.getenv('AES_HEX','')
if AES_HEX:
    body['aeskey']=AES_HEX
print(json.dumps(body))
PY
)

# call getUploadUrl
GETURL_RESP=$(curl -s -X POST "$BASEURL/ilink/bot/getuploadurl" \
  -H "Content-Type: application/json" \
  -H "AuthorizationType: ilink_bot_token" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$REQ")

# Extract upload_param from response
UPLOAD_PARAM=$(echo "$GETURL_RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('upload_param',''))")
if [ -z "$UPLOAD_PARAM" ]; then
  echo "Failed to get upload_param: $GETURL_RESP" >&2
  exit 3
fi

# The upload_param may be a full URL (rare) or an encrypted param. Construct CDN upload URL using cdnBaseUrl.
if echo "$UPLOAD_PARAM" | grep -qE '^https?://'; then
  UPLOAD_URL="$UPLOAD_PARAM"
else
  UPLOAD_URL="$CDN_BASE_URL/upload?encrypted_query_param=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$UPLOAD_PARAM")&filekey=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$FILEKEY")"
fi

# Upload ciphertext to CDN. Use POST as the plugin implementation expects POST, not PUT. No Authorization header required for CDN.
TS=$(date +%s)
HDRFILE="/tmp/cdn_headers_${TS}.txt"
BODYFILE="/tmp/cdn_body_${TS}.bin"
HTTP_STATUS=$(curl -s -w "%{http_code}" -D "$HDRFILE" -o "$BODYFILE" -X POST "$UPLOAD_URL" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$ENC_FILE")

# extract x-encrypted-param from headers if present
X_ENC_PARAM=$(grep -i '^x-encrypted-param:' "$HDRFILE" | sed -E 's/^[^:]+:[[:space:]]*//' | tr -d '\r' || true)
if [ -n "$X_ENC_PARAM" ]; then
  ENCRYPT_QUERY_PARAM="$X_ENC_PARAM"
else
  ENCRYPT_QUERY_PARAM="$UPLOAD_PARAM"
fi

# prepare voice_item (CDNMedia) and voice metadata using CDN's x-encrypted-param when available
CDN_MEDIA_JSON=$(python3 - <<PY
import json
media={'encrypt_query_param': '%s', 'aes_key': '%s'}
print(json.dumps(media))
PY
"$ENCRYPT_QUERY_PARAM" "$AES_KEY_B64")

# create sanitized debug artifacts (redact sensitive values)
SAN_GET="/tmp/weixin_getupload_sanitized_${TS}.json"
python3 - <<PY > "$SAN_GET"
import json,sys
try:
    d=json.loads('''$GETURL_RESP''')
    if 'upload_param' in d:
        d['upload_param']='<REDACTED>'
    if 'thumb_upload_param' in d:
        d['thumb_upload_param']='<REDACTED>'
    print(json.dumps(d))
except Exception as e:
    print('{}')
PY

SAN_SEND="/tmp/weixin_sendmessage_sanitized_${TS}.json"
python3 - <<PY > "$SAN_SEND"
import json
body={
  'msg':{
    'to_user_id':'%s',
    'item_list':[{
      'type':3,
      'voice_item':{
        'media':{
          'encrypt_query_param':'<REDACTED>' ,
          'aes_key':'<REDACTED>'
        },
        'encode_type':6,
        'sample_rate':16000,
        'playtime': %s
      }
    }]
  }
}
print(json.dumps(body))
PY
"$TO_USER_ID" "$PLAY_MS"

# Construct sendMessage body with voice metadata if playtime provided
SENDBODY=$(python3 - <<PY
import json
media=json.loads('''$CDN_MEDIA_JSON''')
voice_item={'media': media}
try:
    play_ms = int('%s') if '%s' else None
except:
    play_ms = None
if play_ms:
    voice_item.update({'encode_type':6,'sample_rate':16000,'playtime':play_ms})
body={'msg':{
  'to_user_id':'$TO_USER_ID',
  'context_token':'',
  'item_list':[
    {'type':3,'voice_item': voice_item}
  ]
}}
print(json.dumps(body))
PY
)

# Call sendMessage
SEND_RESP=$(curl -s -X POST "$BASEURL/ilink/bot/sendmessage" \
  -H "Content-Type: application/json" \
  -H "AuthorizationType: ilink_bot_token" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$SENDBODY")

# output minimal success/failure
echo "getUploadUrl response: $(echo $GETURL_RESP | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("ret",""))')"
echo "cdn upload http status: $HTTP_STATUS"
echo "cdn headers file: $HDRFILE"
echo "upload put response body: $(xxd -l 256 -p "$BODYFILE" 2>/dev/null || true)"
echo "sendMessage response: $SEND_RESP"

echo "sanitized_get: $SAN_GET"
echo "sanitized_send: $SAN_SEND"

exit 0
