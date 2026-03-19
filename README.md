# Xiaomi MiMo TTS Skill

小米 MiMo TTS 语音合成 OpenClaw Skill。

## ✨ 核心亮点：智能风格检测

**自动分析文本，智能选择最合适的情感、方言、语速！**

```bash
# 智能版自动检测（推荐）
node scripts/mimo_tts_smart.js "今天太开心了，哈哈！" output.ogg
# 输出: 📊 检测结果: 情感: happy
#       🏷️ 风格: <style>开心</style>
```

### 智能检测能力

| 类型 | 检测内容 |
|-----|---------|
| 情感 | 开心、悲伤、紧张、愤怒、惊讶、温柔 |
| 方言 | 东北话、四川话、台湾腔、粤语 |
| 效果 | 悄悄话、夹子音、唱歌 |
| 内容 | 诗词、新闻、故事自动适配 |

## 安装

```bash
clawhub install xiaomi-mimo-tts
```

## 配置

设置环境变量：

```bash
export MIMO_API_KEY=your-api-key
```

获取 API Key: https://platform.xiaomimimo.com/

## 使用

### 命令行

```bash
# 基本用法
~/.openclaw/skills/mimo-tts/scripts/mimo-tts.sh "你好世界"

# 指定输出文件
~/.openclaw/skills/mimo-tts/scripts/mimo-tts.sh "你好世界" output.ogg

# 使用 Python 脚本（更多功能）
pip install openai
python3 ~/.openclaw/skills/mimo-tts/scripts/mimo_tts.py "你好" \
  --voice default_zh --style "夹子音" --output output.wav
```

### 可用语音

- `mimo_default` - 默认
- `default_zh` - 中文女声
- `default_eh` - 英文女声

### 风格控制

```bash
# 夹子音
python3 scripts/mimo_tts.py "<style>夹子音</style>主人～我来啦！" --voice default_zh

# 悄悄话
python3 scripts/mimo_tts.py "<style>悄悄话</style>这是秘密" --voice default_zh

# 方言
python3 scripts/mimo_tts.py "<style>东北话</style>你瞅啥" --voice default_zh
```

### 情感标签

```bash
# 在文本中使用 () 标注情感
python3 scripts/mimo_tts.py "（紧张，深呼吸）呼……冷静，冷静"
```

## 测试

```bash
~/.openclaw/skills/mimo-tts/scripts/test.sh
```

## 脚本版本

- `mimo-tts.sh` - Shell 脚本（最简单）
- `mimo_tts.js` - Node.js 脚本（推荐，兼容性好）
- `mimo_tts.py` - Python 脚本（需要 openai 包）

## 依赖

- curl
- node (Node.js >= 18，内置 fetch)
- python3（可选）
- ffmpeg

## License

MIT
