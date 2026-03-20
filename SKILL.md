---
name: xiaomi-mimo-tts
description: |
  使用小米 MiMo TTS (mimo-v2-tts) 生成语音。
  支持多种音色、风格控制、情感标签和方言。
  需要 MIMO_API_KEY。
---

# Xiaomi MiMo TTS

## ✨ 核心能力

**根据对话场景，智能选择最合适的语音风格！**

作为 Agent，你应该主动理解对话内容，选择合适的：
- **情感**：开心、悲伤、紧张、愤怒、惊讶、温柔...
- **方言**：东北话、四川话、台湾腔、粤语...
- **效果**：悄悄话、夹子音、唱歌...
- **语速**：快、慢、正常

## 使用方式

### 基础用法
```bash
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo-tts.sh "文本" [输出文件]
```

### 带风格标签
```bash
# 在文本前加 <style> 标签
"<style>开心</style>今天真是太棒了！"
"<style>东北话</style>老铁，咋整啊？"
"<style>悄悄话</style>这是秘密哦..."
```

### 可用风格

| 类型 | 示例 |
|-----|------|
| 情感 | 开心、悲伤、紧张、愤怒、惊讶、温柔 |
| 方言 | 东北话、四川话、台湾腔、粤语、河南话 |
| 效果 | 悄悄话、夹子音、唱歌 |
| 语速 | 变快、变慢 |

### 情感标签（细粒度控制）

在文本中使用 `()` 添加情感：
```
"（紧张，深呼吸）呼……冷静，冷静"
"（咳嗽）咳咳，不好意思"
"（沉默片刻）……然后呢？"
```

## Agent 职责

**你应该主动判断对话场景，选择合适的风格！**

### 判断原则

1. **默认使用普通话**，除非用户明显使用方言或有特别要求
2. **根据内容选择情感**：
   - 好消息 → 开心
   - 坏消息/安慰 → 温柔、悲伤
   - 紧急情况 → 紧张、急促
   - 正式通知 → 严肃
3. **根据场景选择效果**：
   - 私密内容 → 悄悄话
   - 朗读诗词 → 温柔、慢
   - 讲故事 → 根据角色变化

### 示例

用户说："给我读首李白的诗"
→ 判断：诗词应温柔、舒缓
→ 生成：`"<style>温柔</style>床前明月光..."`

用户说："用东北话给我讲个笑话"
→ 判断：明确要求方言
→ 生成：`"<style>东北话</style>那个啥..."`

用户说："宝宝晚安"
→ 判断：亲密、温柔场景
→ 生成：`"<style>温柔</style>晚安，好梦哦～"`

## 可用语音

| 语音 | 参数 |
|-----|------|
| 默认 | `mimo_default` |
| 中文女声 | `default_zh` |
| 英文女声 | `default_eh` |

## 🤖 智能版本 (mimo_tts_smart.js)

我们提供了一个智能脚本，可以自动分析文本内容并选择合适的风格：

### 功能特点

**自动分析**：
- 检测情感关键词（开心、悲伤、紧张、愤怒、惊讶、温柔）
- 识别方言特征（东北话、四川话、台湾腔、粤语）
- 判断特殊效果（悄悄话、夹子音、唱歌）
- 检测诗词格式（多行短句自动识别）

### 使用方式

```bash
# 智能版 - 自动分析
node ~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo_tts_smart.js "文本内容" [输出文件]

# 示例
node scripts/mimo_tts_smart.js "宝宝晚安，爱你哦～" output.ogg
# 会自动添加 <style>温柔</style> 标签

node scripts/mimo_tts_smart.js "唱首歌给我听吧" output.ogg
# 会自动添加 <style>唱歌</style> 标签
```

### Agent 使用建议

Agent 可以直接调用智能版脚本，无需手动判断风格：

```bash
# 使用智能版（推荐）
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo-tts-smart.sh "$TEXT" "$OUTPUT_FILE"

# 或直接调用 Node 版本
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo_tts_smart.js "$TEXT" "$OUTPUT_FILE"
```

**推荐使用 `mimo-tts-smart.sh`**，因为它有更好的错误处理和输出反馈。

脚本会自动分析：
1. 根据情感关键词选择相应风格
2. 根据方言特征选择方言
3. 根据内容类型调整语速和效果
4. 诗词内容自动使用温柔风格

### 手动覆盖

如果需要强制使用特定风格，可以继续使用基础版本的 style 标签：

```bash
# 手动指定风格（覆盖智能分析）
MIMO_STYLE="夹子音" ~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo-tts.sh "文本"
```

## 配置

```bash
export MIMO_API_KEY=your-api-key
```

获取 API Key: https://platform.xiaomimimo.com/
