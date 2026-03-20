---
name: xiaomi-mimo-tts
description: |
  使用小米 MiMo TTS (mimo-v2-tts) 生成语音。
  支持多种音色、风格控制、情感标签和方言。
  需要 MIMO_API_KEY。
---

# Xiaoma MiMo TTS

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

## 🤖 智能版本 (多语言支持)

我们提供了多种智能脚本实现，可以自动分析文本内容并选择合适的风格：

### 🎯 实现支持

| 版本 | 文件 | 特点 |
|------|------|------|
| **统一入口** | `mimo-tts-smart.sh` | 自动选择最佳实现，优先NodeJS→Python→Shell |
| **NodeJS 版** | `mimo_tts_smart.js` | 功能最完善，智能分析最准确 |
| **Python 版** | `mimo_tts_smart.py` | 功能完整，备用方案 |
| **Shell 版** | `mimo_tts_smart.sh` | 简化版，兼容性好 |

### 功能特点

**自动分析**：
- 检测情感关键词（开心、悲伤、紧张、愤怒、惊讶、温柔）
- 识别方言特征（东北话、四川话、台湾腔、粤语）
- 判断特殊效果（悄悄话、夹子音、唱歌）
- 检测诗词格式（多行短句自动识别）

### 使用方式

```bash
# 推荐：使用统一入口（自动选择最佳实现）
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo-tts-smart.sh "文本内容" [输出文件]

# 直接调用 NodeJS 版本（功能最完善）
node ~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo_tts_smart.js "文本内容" [输出文件]

# 直接调用 Python 版本
python3 ~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo_tts_smart.py "文本内容" [输出文件]

# 直接调用 Shell 版本（简化版）
~/.openclaw/skills/xiaomi-mimo-tts/scripts/mimo_tts_smart.sh "文本内容" [输出文件]

# 示例
mimo-tts-smart.sh "宝宝晚安，爱你哦～" output.ogg
# 会自动添加 <style>温柔</style> 标签

mimo-tts-smart.sh "唱首歌给我听吧" output.ogg
# 会自动添加 <style>唱歌</style> 标签

mimo-tts-smart.sh "老铁，咋整啊？" output.ogg
# 会自动添加 <style>东北话</style> 标签
```

### Agent 使用建议

**强烈推荐使用 `mimo-tts-smart.sh`**，它会：
1. 自动检测系统环境（NodeJS/Python/Shell 可用性）
2. 自动选择最佳实现版本
3. 提供更好的错误处理和输出反馈
4. 保证最大兼容性

脚本会自动分析：
1. 根据情感关键词选择相应风格
2. 根据方言特征选择方言
3. 根据内容类型调整语速和效果
4. 诗词内容自动使用温柔风格

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

推荐使用官方环境变量名（优先）：

```bash
export XIAOMI_API_KEY=your-api-key
```

为兼容历史配置，也支持旧名：

```bash
export MIMO_API_KEY=your-api-key  # 仍然被接受，但优先使用 XIAOMI_API_KEY
```

获取 API Key: https://platform.xiaomimimo.com/

## 🎯 实用示例

### 1. 俏皮话生成器

使用 `scripts/examples/tease-generator.sh` 为朋友创作有趣的俏皮话：

```bash
# 为赵冬生成上海话俏皮话
./scripts/examples/tease-generator.sh 赵冬 上海话

# 为张三生成四川话俏皮话  
./scripts/examples/tease-generator.sh 张三 四川话

# 为李四生成山东话俏皮话
./scripts/examples/tease-generator.sh 李四 山东话
```

### 2. 方言测试器

使用 `scripts/examples/dialect-tester.sh` 测试方言检测准确性：

```bash
# 测试所有方言检测
./scripts/examples/dialect-tester.sh
```

### 3. 实际应用场景

**给失联朋友的俏皮话**：
```bash
# 普通话版
mimo-tts-smart.sh "赵冬啊赵冬，你是被冬天冻傻了吗？咋跟个冰雕似的，动不动就玩消失？" output.ogg

# 上海话版  
mimo-tts-smart.sh "赵冬侬哪能意思啦？冬天到了侬也跟着冬眠了是伐？" output.ogg

# 四川话版
mimo-tts-smart.sh "哎呀，赵冬你这个四川话嘛...还算要得！" output.ogg
```

**方言评价回复**：
```bash
# 评价山东话水平
mimo-tts-smart.sh "徐锐你听！杠赛来你这个山东话！俺滴个娘嘞，恁这个话讲得！" output.ogg

# 评价四川话水平
mimo-tts-smart.sh "要得还算，你这个四川话嘛！安逸惨了，巴适得板！" output.ogg
```

## 🔧 维护和调试

### 方言检测调试
如果某个方言检测不准确，可以：

1. 检查方言关键词配置：
   - `scripts/smart/mimo_tts_smart.js` (NodeJS版)
   - `scripts/smart/mimo_tts_smart.py` (Python版)
   - `scripts/smart/mimo_tts_smart.sh` (Shell版)

2. 运行方言测试器：
   ```bash
   ./scripts/examples/dialect-tester.sh
   ```

### 添加新方言
1. 在三个智能脚本中添加新的方言关键词
2. 在俏皮话生成器中添加对应模板
3. 测试方言检测准确性
4. 提交更新到 GitHub
