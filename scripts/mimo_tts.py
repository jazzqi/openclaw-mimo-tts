#!/usr/bin/env python3
"""MiMo TTS 工具 - pip install openai 即可使用"""

import os
import argparse
import base64
from openai import OpenAI

DEFAULT_API_KEY = os.environ.get("MIMO_API_KEY", "")
BASE_URL = "https://api.xiaomimimo.com/v1"

VOICES = {
    "mimo_default": "默认音色（中英混合）",
    "default_zh":  "中文普通话",
    "default_en":  "英文",
}

STYLES = {
    "河南话": "河南方言",
    "东北话": "东北方言",
    "四川话": "四川方言",
    "台湾腔": "台湾口音",
    "粤语":   "广东话",
    "夹子音": "萝莉音/夹子音",
    "悄悄话": "耳语模式",
    "大声":   "大声播报",
}

EMOTION_PATTERNS = {
    "开心": "开心", "快乐": "开心", "高兴": "开心", "兴奋": "开心", "笑": "开心",
    "悲伤": "悲伤", "难过": "悲伤", "伤心": "悲伤", "痛哭": "悲伤",
    "紧张": "紧张", "害怕": "紧张", "恐惧": "紧张", "发抖": "紧张",
    "愤怒": "愤怒", "生气": "愤怒", "大火": "愤怒", "气愤": "愤怒",
    "惊讶": "惊讶", "震惊": "惊讶", "意外": "惊讶",
    "温柔": "温柔", "柔情": "温柔", "温暖": "温柔", "轻柔": "温柔",
    "哭": "哭泣", "流泪": "哭泣",
}

EFFECT_PATTERNS = {
    "悄悄话": "悄悄话", "耳语": "悄悄话", "低声": "悄悄话",
    "夹子音": "夹子音", "萝莉": "夹子音", "可爱": "夹子音",
    "唱歌": "唱歌", "吟唱": "唱歌", "歌": "唱歌",
}

SPEED_PATTERNS = {
    "变快": "变快", "加快": "变快", "快速": "变快", "飞速": "变快", "超快": "变快",
    "变慢": "变慢", "减速": "变慢", "慢速": "变慢", "缓慢": "变慢", "超慢": "变慢",
}

DIALECT_PATTERNS = {
    "河南话": "河南话", "河南": "河南话", "俺": "河南话", "中": "河南话", "信阳": "河南话", "郑州": "河南话",
    "东北话": "东北话", "东北": "东北话", "嘎哈": "东北话", "咋": "东北话", "啥": "东北话", "干哈": "东北话",
    "四川话": "四川话", "四川": "四川话", "锤子": "四川话", "啥子": "四川话", "瓜娃子": "四川话",
    "台湾腔": "台湾腔", "台湾": "台湾腔", "那边": "台湾腔", "真的": "台湾腔", "超酷": "台湾腔",
    "粤语": "粤语", "广东话": "粤语", "白话": "粤语", "广州": "粤语", "深圳": "粤语",
}


def detect_style(text: str):
    """检测文本中的方言/情感/效果/语速，返回 (styles, speed)"""
    detected_styles = []
    detected_speed = None

    for kw, style in DIALECT_PATTERNS.items():
        if kw in text:
            detected_styles.append(style)
            break

    for kw, style in EMOTION_PATTERNS.items():
        if kw in text:
            detected_styles.append(style)
            break

    for kw, effect in EFFECT_PATTERNS.items():
        if kw in text:
            detected_styles.append(effect)
            break

    for kw, speed in SPEED_PATTERNS.items():
        if kw in text:
            detected_speed = speed
            break

    lines = text.split('\n')
    if len(lines) >= 2 and all(len(l.strip()) < 15 for l in lines if l.strip()):
        detected_styles.append("温柔")

    return detected_styles, detected_speed


def synthesize(text: str, voice: str = "default_zh", output_file: str = "output.wav",
               api_key: str = None, style: str = None, speed: str = None,
               auto_detect: bool = False) -> str:
    key = api_key or DEFAULT_API_KEY
    if not key:
        raise ValueError("请设置环境变量 MIMO_API_KEY")

    if auto_detect:
        styles, detected_speed = detect_style(text)
        if styles:
            style = styles[0]
        if detected_speed:
            speed = detected_speed

    style_parts = []
    if style:
        style_parts.append(style)
    if speed:
        style_parts.append(speed)
    style_tag = "<style>" + " ".join(style_parts) + "</style>" if style_parts else ""
    if style_tag:
        text = style_tag + text

    client = OpenAI(api_key=key, base_url=BASE_URL)
    completion = client.chat.completions.create(
        model="mimo-v2-tts",
        messages=[
            {"role": "user", "content": "你好"},
            {"role": "assistant", "content": text},
        ],
        audio={"format": "wav", "voice": voice},
    )

    audio_bytes = base64.b64decode(completion.choices[0].message.audio.data)
    with open(output_file, "wb") as f:
        f.write(audio_bytes)

    print(f"✅ 已保存至 {output_file} ({len(audio_bytes)} bytes)")
    return output_file


def main():
    parser = argparse.ArgumentParser(description="MiMo TTS - 小米语音合成工具")
    parser.add_argument("-t", "--text",   help="要转语音的文本")
    parser.add_argument("-o", "--output", default="output.wav", help="输出文件路径")
    parser.add_argument("-v", "--voice",  default="default_zh", choices=list(VOICES.keys()), help="音色选择")
    parser.add_argument("--style",        default=None, choices=list(STYLES.keys()), help="风格/方言")
    parser.add_argument("--api-key",     default=None, help="API Key（环境变量 MIMO_API_KEY）")
    parser.add_argument("--auto",       action="store_true", help="自动检测风格/方言")
    parser.add_argument("--speed",       default=None, choices=["变快", "变慢", "加快", "减速"], help="语速")

    args = parser.parse_args()

    if args.text:
        synthesize(args.text, args.voice, args.output, args.api_key, args.style, args.speed, args.auto)
    else:
        print("=== MiMo TTS 工具 ===")
        print("可用音色:")
        for v, d in VOICES.items():
            print(f"  {v:20s} - {d}")
        print("\n可用风格/方言:")
        for s, d in STYLES.items():
            print(f"  {s:10s} - {d}")
        print()
        text = input("输入要转语音的文本: ").strip()
        if not text:
            return
        voice = input("选择音色 (默认 default_zh): ").strip() or "default_zh"
        voice = voice if voice in VOICES else "default_zh"
        style = input("选择风格/方言 (直接回车跳过): ").strip()
        style = style if style in STYLES else None
        out = input("输出文件 (默认 output.wav): ").strip() or "output.wav"
        synthesize(text, voice, out, args.api_key, style)


if __name__ == "__main__":
    main()
