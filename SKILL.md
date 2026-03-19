---
name: xiaomi-mimo-tts
description: |
  使用小米 MiMo TTS (mimo-v2-tts) 生成语音。
  支持中文语音合成、多种音色、风格控制和情感标签。
  需要 MIMO_API_KEY。
---

# Xiaomi MiMo TTS

## ✨ 核心特点：智能风格检测

**自动分析文本，智能选择最合适的情感、方言、语速！**

- 🎭 **情感识别**：开心、悲伤、紧张、愤怒、惊讶、温柔
- 🗣️ **方言检测**：东北话、四川话、台湾腔、粤语
- 🎨 **效果识别**：悄悄话、夹子音、唱歌
- 📜 **内容分析**：诗词、新闻、故事自动适配

## 快速使用

直接说 "发语音" + 你想说的内容，或描述你想要的语音风格。

## 默认配置

- **默认语音**: `default_zh`（中文女声）
- **默认风格**: `<style>夹子音</style>`（可爱夹子音，未指定风格时使用）

## 可用语音

| 语音名称 | voice 参数 |
|---------|-----------|
| MiMo-Default | `mimo_default` |
| MiMo-Chinese-Female | `default_zh` |
| MiMo-English-Female | `default_eh` |

## 风格控制

### 整体风格（文本开头）

| 风格类型 | 示例 |
|---------|------|
| 语速控制 | 变快 / 变慢 |
| 情感 | 开心 / 悲伤 / 生气 |
| 角色 | 孙悟空 / 林黛玉 |
| 风格变化 | 悄悄话 / 夹子音 / 台湾腔 |
| 方言 | 东北话 / 四川话 / 河南话 / 粤语 |

**格式**: `<style>风格1 风格2</style>要合成的文本`

### 音频标签（细粒度控制）

使用 `()` 标注情感、语速、停顿、呼吸等：

| 标签 | 描述 | 示例 |
|-----|------|------|
| `（紧张，深呼吸）` | 多情感组合 | `（紧张，深呼吸）呼……冷静，冷静` |
| `（语速加快）` | 语速变化 | `（语速加快，碎碎念）` |
| `（小声）` | 音量控制 | `（小声）哎呀，领带歪没歪？` |
| `（长叹一口气）` | 叹气 | `（长叹一口气）` |
| `（咳嗽）` | 咳嗽 | `（咳嗽）简直能把人骨头冻透了` |
| `（沉默片刻）` | 停顿 | `（沉默片刻）` |
| `（苦笑）` | 苦笑 | `（苦笑）呵，没如果了` |
| `（提高音量喊话）` | 大声喊话 | `（提高音量喊话）大姐！这鱼新鲜着呢！` |
| `（极其疲惫）` | 疲惫 | `师傅……到地方了叫我一声……` |

## 脚本使用

```bash
# 基本用法
~/.openclaw/skills/mimo-tts/scripts/mimo-tts.sh "你好世界"

# 指定语音
MIMO_VOICE=default_zh ~/.openclaw/skills/mimo-tts/scripts/mimo-tts.sh "你好"

# 带风格
~/.openclaw/skills/mimo-tts/scripts/mimo-tts.sh "<style>夹子音</style>主人～我来啦！"
```

## Python 脚本

```bash
MIMO_API_KEY=your_key python3 scripts/mimo_tts.py "text" \
  --voice default_zh \
  --style "夹子音" \
  --output output.wav
```

## 注意事项

- 目标文本必须在 `assistant` 角色的消息中，不在 `user`
- `<style>` 标签必须在目标文本开头
- 唱歌使用: `<style>唱歌</style>目标文本`
- 返回 base64 编码的 WAV 音频

## 配置

设置环境变量：
```bash
export MIMO_API_KEY=your-api-key
```

获取 API Key: https://platform.xiaomimimo.com/

## 测试

```bash
~/.openclaw/skills/mimo-tts/scripts/test.sh
```

## 依赖

- curl
- python3
- ffmpeg
