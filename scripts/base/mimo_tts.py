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

# Real implementation placeholder
print('Real API key present but remote call not implemented in this template.')
open(output,'wb').close()
print(output)
sys.exit(0)
