#!/usr/bin/env python3
"""
MiMo TTS - 小米 MiMo 语音合成脚本

用法:
    MIMO_API_KEY=your_key python3 mimo_tts.py "text" --voice default_zh --style "夹子音" --output output.wav
"""

import os
import sys
import argparse
import base64
import subprocess

API_BASE = "https://api.xiaomimimo.com/v1"

def synthesize(text, voice="default_zh", style=None, output="output.wav"):
    """合成语音"""
    try:
        from openai import OpenAI
    except ImportError:
        print("错误: 需要安装 openai 包")
        print("运行: pip install openai")
        sys.exit(1)
    
    api_key = os.environ.get("MIMO_API_KEY")
    if not api_key:
        print("错误: 请设置 MIMO_API_KEY 环境变量")
        sys.exit(1)
    
    client = OpenAI(
        api_key=api_key,
        base_url=API_BASE
    )
    
    # 添加风格标签
    target_text = f"<style>{style}</style>{text}" if style else text
    
    print(f"合成中: {text[:50]}{'...' if len(text) > 50 else ''}")
    print(f"语音: {voice}")
    if style:
        print(f"风格: {style}")
    
    completion = client.chat.completions.create(
        model="mimo-v2-tts",
        messages=[
            {"role": "user", "content": "你好"},
            {"role": "assistant", "content": target_text}
        ],
        audio={"format": "wav", "voice": voice}
    )
    
    audio_bytes = base64.b64decode(completion.choices[0].message.audio.data)
    
    # 保存 WAV
    wav_path = output if output.endswith('.wav') else f"{output}.wav"
    with open(wav_path, "wb") as f:
        f.write(audio_bytes)
    
    print(f"✓ 音频已保存: {wav_path}")
    
    # 转换为 OGG（如果需要）
    if output.endswith('.ogg'):
        subprocess.run([
            "ffmpeg", "-y", "-i", wav_path,
            "-acodec", "libopus", "-b:a", "128k",
            output
        ], capture_output=True)
        os.remove(wav_path)
        print(f"✓ 已转换为 OGG: {output}")
    
    return output

def main():
    parser = argparse.ArgumentParser(description="MiMo TTS 语音合成")
    parser.add_argument("text", help="要合成的文本")
    parser.add_argument("--voice", "-v", default="default_zh",
                       choices=["mimo_default", "default_zh", "default_eh"],
                       help="语音类型")
    parser.add_argument("--style", "-s", help="风格标签（如：夹子音、悄悄话）")
    parser.add_argument("--output", "-o", default="output.wav", help="输出文件")
    
    args = parser.parse_args()
    synthesize(args.text, args.voice, args.style, args.output)

if __name__ == "__main__":
    main()
