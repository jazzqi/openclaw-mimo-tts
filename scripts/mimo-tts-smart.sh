#!/bin/bash
# MiMo TTS 智能版包装脚本
# 自动分析文本情感和风格，生成语音

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEXT="$1"
OUTPUT="${2:-/tmp/mimo-tts-smart-$(date +%s).ogg}"

if [ -z "$TEXT" ]; then
    echo "用法: mimo-tts-smart.sh \"文本内容\" [输出文件]"
    echo ""
    echo "✨ 智能特性:"
    echo "  - 自动检测情感（开心、悲伤、紧张等）"
    echo "  - 自动识别方言（东北话、四川话等）"
    echo "  - 自动判断内容类型（诗词、故事等）"
    echo "  - 无需手动指定风格标签"
    echo ""
    echo "示例:"
    echo "  mimo-tts-smart.sh \"宝宝晚安，爱你哦～\""
    echo "  mimo-tts-smart.sh \"唱首歌给我听吧\""
    echo "  mimo-tts-smart.sh \"老铁，咋整啊？\" output.ogg"
    exit 1
fi

if [ -z "$MIMO_API_KEY" ]; then
    echo "错误: 请设置 MIMO_API_KEY 环境变量"
    echo "  export MIMO_API_KEY=your-api-key"
    exit 1
fi

echo "🧠 智能分析文本中..."
node "$SCRIPT_DIR/mimo_tts_smart.js" "$TEXT" "$OUTPUT"

if [ $? -eq 0 ]; then
    echo "✅ 语音生成完成: $OUTPUT"
    echo "$OUTPUT"
else
    echo "❌ 语音生成失败"
    exit 1
fi