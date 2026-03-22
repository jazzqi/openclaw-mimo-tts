#!/bin/bash
# send_wechat_voice.sh
# 将输入音频转换为 WeChat 常用 AMR 格式并输出文件路径
# 用法: send_wechat_voice.sh input.ogg output.amr

INPUT="$1"
OUTPUT="${2:-/tmp/$(basename "$INPUT" .ogg).amr"}

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 input_file [output.amr]"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found"
  exit 2
fi

# 尝试使用 libopencore_amrnb 转为 amr
ffmpeg -y -i "$INPUT" -ac 1 -ar 8000 -c:a libopencore_amrnb "$OUTPUT"
ret=$?
if [ $ret -ne 0 ]; then
  echo "ffmpeg failed to convert to AMR (libopencore_amrnb). Ret code: $ret"
  exit $ret
fi

echo "$OUTPUT"
