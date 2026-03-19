#!/bin/bash
# MiMo TTS - 使用小米米萌 API 生成语音
# 支持风格控制、音频标签、多种语音

TEXT="$1"
API_KEY="${MIMO_API_KEY}"
VOICE="${MIMO_VOICE:-default_zh}"
STYLE="${MIMO_STYLE:-}"
OUTPUT="${2:-/tmp/mimo-tts-$(date +%s).ogg}"

if [ -z "$TEXT" ]; then
    echo "用法: mimo-tts.sh \"文本\" [输出文件]"
    echo ""
    echo "选项:"
    echo "  MIMO_API_KEY  API密钥 (必需)"
    echo "  MIMO_VOICE    语音类型 (default: default_zh)"
    echo "  MIMO_STYLE    风格 (如: 夹子音, 开心, 悲伤)"
    echo ""
    echo "语音类型:"
    echo "  mimo_default  - MiMo默认"
    echo "  default_zh    - 中文女声 (默认)"
    echo "  default_eh    - 英文女声"
    echo ""
    echo "示例:"
    echo "  mimo-tts.sh \"你好世界\""
    echo "  MIMO_STYLE=夹子音 mimo-tts.sh \"主人～我来啦！\""
    echo "  mimo-tts.sh \"<style>夹子音</style>主人～我来啦！\""
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "错误: 请设置 MIMO_API_KEY 环境变量"
    exit 1
fi

# 如果设置了 MIMO_STYLE，自动添加 style 标签
if [ -n "$STYLE" ] && [[ "$TEXT" != \<style\>* ]]; then
    TEXT="<style>$STYLE</style>$TEXT"
fi

# 调用 API
RESPONSE=$(curl -s -X POST "https://api.xiaomimimo.com/v1/chat/completions" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"mimo-v2-tts\",
        \"messages\": [
            {\"role\": \"user\", \"content\": \"请朗读\"},
            {\"role\": \"assistant\", \"content\": \"$TEXT\"}
        ],
        \"audio\": {
            \"format\": \"wav\",
            \"voice\": \"$VOICE\"
        }
    }")

# 使用 Python 提取音频数据
AUDIO_DATA=$(echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
try:
    print(data['choices'][0]['message']['audio']['data'])
except (KeyError, IndexError, TypeError):
    print('null')
")

if [ -z "$AUDIO_DATA" ] || [ "$AUDIO_DATA" = "null" ]; then
    echo "错误: API 调用失败"
    echo "$RESPONSE"
    exit 1
fi

# 解码并保存
echo "$AUDIO_DATA" | base64 -d > "$OUTPUT.wav"

# 转换为 OGG
ffmpeg -y -i "$OUTPUT.wav" -acodec libopus -b:a 128k "$OUTPUT" 2>/dev/null
rm -f "$OUTPUT.wav"

echo "$OUTPUT"
