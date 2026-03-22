#!/bin/bash
# Upload encrypted file to Weixin CDN and send as voice message via openclaw-weixin backend
# Usage: weixin_upload_and_send.sh enc_file aes_key_b64 to_user_id filekey

set -euo pipefail
ENC_FILE="$1"
AES_KEY_B64="$2"
TO_USER_ID="$3"
# optional param: original plaintext filename (for filekey or naming)
PLAIN_FILEPATH="${4:-}"
AES_HEX_PARAM="${5:-}"
FILEKEY="${6:-file-$(date +%s)}"

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

PLAYTIME_MS="${7:-}"

REQ=$(python3 - <<PY
import json,os
body={
  'filekey': '$FILEKEY',
  'media_type': 4,
  'to_user_id': '$TO_USER_ID',
  'rawsize': int(os.getenv('RAWSIZE', '0')),
  'rawfilemd5': os.getenv('RAWMD5', ''),
  'filesize': $CIPHER_SIZE,
  'thumb_rawsize': 0,
  'thumb_rawfilemd5': '',
  'thumb_filesize': 0,
  'base_info': {}
}
# include aeskey if provided
if os.getenv('AES_HEX_PARAM'):
    body['aeskey']=os.getenv('AES_HEX_PARAM')
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

# The upload_param may be a URL or JSON; try to use as URL directly if it looks like one
if echo "$UPLOAD_PARAM" | grep -qE '^https?://'; then
  UPLOAD_URL="$UPLOAD_PARAM"
else
  # if upload_param is encrypted params, attempt to POST to BASEURL/upload with params
  UPLOAD_URL="$BASEURL/upload?param=$UPLOAD_PARAM"
fi

# PUT encrypted content to CDN
HTTP_RESP=$(curl -s -X PUT "$UPLOAD_URL" \
  -H "AuthorizationType: ilink_bot_token" \
  -H "Authorization: Bearer $TOKEN" \
  --data-binary "@$ENC_FILE")

# prepare voice_item (CDNMedia) and voice metadata
CDN_MEDIA_JSON=$(python3 - <<PY
import json
media={'encrypt_query_param': '$UPLOAD_PARAM', 'aes_key': '$AES_KEY_B64'}
print(json.dumps(media))
PY
)

# Construct sendMessage body with voice metadata if playtime provided
SENDBODY=$(python3 - <<PY
import json,sys
media=json.loads('''$CDN_MEDIA_JSON''')
voice_item={'media': media}
# include encode/sample/playtime if provided
play_ms = int('$PLAYTIME_MS') if '$PLAYTIME_MS' else None
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
echo "upload put response: $HTTP_RESP"
echo "sendMessage response: $SEND_RESP"

exit 0
