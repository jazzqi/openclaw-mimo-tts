#!/usr/bin/env python3
"""Minimal Python base implementation for xiaomi-mimo-tts
Usage: python3 mimo_tts.py "文本" [output.ogg] [--voice VOICE] [--style STYLE]
"""
import sys,os,subprocess
if len(sys.argv)<2:
    print('Usage: python3 mimo_tts.py "TEXT" [OUTPUT] [--voice VOICE] [--style STYLE]')
    sys.exit(2)
text=sys.argv[1]
output=sys.argv[2] if len(sys.argv)>2 and not sys.argv[2].startswith('--') else os.path.join(os.getcwd(),'output.mock.ogg')
voice='mimo_default'
style=''
args=sys.argv[2:]
for i,a in enumerate(args):
    if a=='--voice' and i+1<len(args): voice=args[i+1]
    if a=='--style' and i+1<len(args): style=args[i+1]

XIAOMI_API_KEY=os.environ.get('XIAOMI_API_KEY') or os.environ.get('MIMO_API_KEY')
MOCK = not XIAOMI_API_KEY
if MOCK:
    # try ffmpeg
    try:
        subprocess.run(['ffmpeg','-f','lavfi','-i','anullsrc=r=16000:cl=mono','-t','0.5','-q:a','9','-acodec','libopus',output,'-y'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    except Exception:
        open(output,'wb').close()
    print(output)
    sys.exit(0)

# Real implementation: call Xiaomi MiMo API and decode returned base64 audio
import json, base64, urllib.request

# Build request body: assistant message contains the target text
body = {
    "model": "mimo-v2-tts",
    "messages": [
        {"role": "user", "content": "请朗读"},
        {"role": "assistant", "content": text}
    ],
    "audio": {"format": "wav", "voice": voice}
}

req = urllib.request.Request(
    'https://api.xiaomimimo.com/v1/chat/completions',
    data=json.dumps(body).encode('utf-8'),
    headers={
        'Authorization': f'Bearer {XIAOMI_API_KEY}',
        'Content-Type': 'application/json'
    }
)
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        resp_text = resp.read().decode('utf-8')
except Exception as e:
    print('API request failed:', e)
    sys.exit(1)

try:
    data = json.loads(resp_text)
    audio_b64 = data['choices'][0]['message']['audio']['data']
except Exception as e:
    print('Failed to parse audio from response:', e)
    print(resp_text)
    sys.exit(1)

wav = base64.b64decode(audio_b64)
wav_path = output + '.wav'
with open(wav_path, 'wb') as f:
    f.write(wav)

# convert wav to ogg if ffmpeg exists
try:
    subprocess.run(['ffmpeg','-y','-i',wav_path,'-acodec','libopus','-b:a','128k',output], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(wav_path)
except Exception:
    # if conversion fails, leave wav as output
    os.rename(wav_path, output)

print(output)
sys.exit(0)
