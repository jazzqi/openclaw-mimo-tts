# Xiaomi MiMo TTS Skill

小米 MiMo TTS 语音合成 OpenClaw Skill。

## ✨ 核心亮点：多语言智能版本支持

**自动分析文本，智能选择最合适的情感、方言、语速，多语言实现支持！**

### 🎯 智能版本支持

| 版本 | 文件 | 特点 | 推荐度 |
|------|------|------|--------|
| **统一入口** | `mimo-tts-smart.sh` | 自动选择最佳实现 | ★★★★★ |
| **NodeJS 版** | `mimo_tts_smart.js` | 功能最完善 | ★★★★★ |
| **Python 版** | `mimo_tts_smart.py` | 功能完整，备用方案 | ★★★★☆ |
| **Shell 版** | `mimo_tts_smart.sh` | 简化版，兼容性好 | ★★★☆☆ |

```bash
# 推荐：统一入口（自动选择最佳实现）
scripts/mimo-tts-smart.sh "今天太开心了，哈哈！" output.ogg

# 直接调用 NodeJS 版（功能最完整）
node scripts/mimo_tts_smart.js "今天太开心了，哈哈！" output.ogg
# 输出: 📊 检测结果: 情感: happy
#       🏷️ 风格: <style>开心</style>

# Python 版
python3 scripts/mimo_tts_smart.py "宝宝晚安，爱你哦～" output.ogg
# 输出: 📊 检测结果: 情感: gentle
#       🏷️ 风格: <style>温柔</style>

# Shell 简化版
scripts/mimo_tts_smart.sh "老铁，咋整啊？" output.ogg
# 输出: 🏷️ 检测到风格: 东北话
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

推荐使用官方环境变量名（优先）：

```bash
export XIAOMI_API_KEY=your-api-key
```

为兼容历史配置，也支持旧名：

```bash
export MIMO_API_KEY=your-api-key  # 仍被接受，脚本会优先使用 XIAOMI_API_KEY
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

## 📁 目录结构

```
scripts/
├── mimo-tts.sh           # 基础版本统一入口
├── mimo-tts-smart.sh     # 智能版本统一入口
├── base/                 # 基础版本实现
│   ├── mimo-tts.sh       # Shell 基础版
│   ├── mimo_tts.js       # NodeJS 基础版
│   └── mimo_tts.py       # Python 基础版
├── smart/                # 智能版本实现
│   ├── mimo_tts_smart.js    # NodeJS 智能版
│   ├── mimo_tts_smart.py    # Python 智能版
│   └── mimo_tts_smart.sh    # Shell 智能版
├── utils/                # 工具脚本
│   └── test.sh           # 测试脚本
└── examples/             # 示例脚本
    └── demo.sh           # 演示脚本
```

## 脚本版本

### 统一入口（推荐）
- `mimo-tts.sh` - 基础版本统一入口
- `mimo-tts-smart.sh` - **智能版本统一入口（推荐）**

### 基础版本
- `base/mimo-tts.sh` - Shell 脚本（基础）
- `base/mimo_tts.js` - Node.js 脚本
- `base/mimo_tts.py` - Python 脚本

### 智能版本
- `smart/mimo_tts_smart.js` - NodeJS 智能版，功能最完善
- `smart/mimo_tts_smart.py` - Python 智能版，功能完整
- `smart/mimo_tts_smart.sh` - Shell 智能版，简化版

## 依赖

- curl
- node (Node.js >= 18，内置 fetch)
- python3（可选）
- ffmpeg

## License

MIT
