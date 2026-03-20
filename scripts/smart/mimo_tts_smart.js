#!/usr/bin/env node
/**
 * MiMo TTS 智能版 - 自动分析文本情感和风格
 */

const fs = require('fs');
const { execSync } = require('child_process');

const API_BASE = 'https://api.xiaomimimo.com/v1';

// 情感关键词映射
const EMOTION_PATTERNS = {
  happy: ['开心', '高兴', '快乐', '哈哈', '嘻嘻', '太棒', '好棒', '太好了', '厉害', '赞'],
  sad: ['伤心', '难过', '悲伤', '痛苦', '眼泪', '哭', '遗憾', '想念', '怀念'],
  nervous: ['紧张', '焦虑', '担心', '害怕', '恐惧', '不安', '慌', '急'],
  angry: ['生气', '愤怒', '气死', '烦死', '讨厌', '可恶'],
  surprised: ['哇', '天哪', '什么', '不会吧', '真的吗', '难以置信'],
  gentle: ['亲爱的', '宝贝', '爱你', '喜欢', '温柔', '甜蜜', '幸福'],
};

// 方言关键词（仅在明显方言特征时检测）
const DIALECT_PATTERNS = {
  '东北话': ['咋整', '干哈', '瞅啥', '老铁', '没毛病', '杠杠的', '必须的', '埋汰', '嗷嗷的', '整挺好', '贼拉'],
  '四川话': ['巴适', '安逸', '晓得嘛', '莫得事', '雄起', '瓜娃子', '要得', '不得行', '瓜兮兮', '哈戳戳', '神戳戳', '撇脱', '巴心巴肝', '龙门阵'],
'台湾闽南话': ['呷饱没', '金价', '揪', '水', '赞', '哩厚', '多谢', '拍谢', '甲霸没', '厚', '呷霸没', '呷奔', '麦安捏', '安抓', '歹势', '搁来', '卡紧', '金厚', '足水', '有够赞', '讲袂懂', '讲袂会'],
  '台湾腔': ['真的假的', '好喔', '是喔', '安捏', '齁', '超', '屁啦', '酱紫', '森77', '484', '母汤', '太扯', '甘安捏', '就酱', '不造', '佛系', '傻眼猫咪', '塑胶', '业配', '森气气', '窝不知道', '矮油', '揪咪', '好der', '好la', '好ne', '好喔', '好捏', '矮油', '窝不知道', '傻眼猫咪'],
  '粤语': ['唔系', '系唔系', '边度', '点样', '冇', '唔', '睇', '食', '嘅', '咗', '咁', '乜嘢', '做乜', '幾多', '點解', '好正', '好掂'],
  '山东话': ['俺那娘嘞', '俺滴个娘', '俺滴乖乖', '杠赛来', '熊样', '杠赛', '山东话', '山东人', '山东滴', '济宁', '枣庄', '鲁中'],
  '河南话': ['中', '得劲', '得劲儿', '咋着', '恁', '俺', '弄啥嘞', '不老盖', '夜儿个', '前儿个', '晌午', '喝汤', '可中', '美得很', '中不中', '嘞很', '恁弄啥'],
  '上海话': ['侬', '阿拉', '勿', '老好', '覅', '嗲', '老克勒', '伐', '个么', '帮帮忙', '十三点', '捣糨糊', '有腔调', '勿来三', '覅忒', '老卵'],
  '陕西话': ['嫽咋咧', '美滴很', '咥', '谝', '咥饭', '嫽', '忒', '嘹咋咧', '嘹滴很', '么嘛达', '嘹太太'],
};

// 特殊效果
const EFFECT_PATTERNS = {
  '悄悄话': ['悄悄', '小声', '秘密', '嘘'],
  '夹子音': ['喵', '主人', '～'],
  '唱歌': ['唱', '歌', '♪', '🎵'],
};

function analyzeText(text) {
  const result = { emotions: [], dialect: null, effect: null, speed: 'normal' };

  // 检测情感
  for (const [emotion, keywords] of Object.entries(EMOTION_PATTERNS)) {
    if (keywords.some(k => text.includes(k))) {
      result.emotions.push(emotion);
    }
  }

  // 检测方言
  for (const [dialect, keywords] of Object.entries(DIALECT_PATTERNS)) {
    if (keywords.some(k => text.includes(k))) {
      result.dialect = dialect;
      break;
    }
  }

  // 检测效果
  for (const [effect, keywords] of Object.entries(EFFECT_PATTERNS)) {
    if (keywords.some(k => text.includes(k))) {
      result.effect = effect;
      break;
    }
  }

  // 检测诗词（短句多）
  const lines = text.split('\n').filter(l => l.trim());
  if (lines.length >= 2 && lines.every(l => l.length <= 30)) {
    result.isPoetry = true;
  }

  return result;
}

function generateStyleTag(analysis) {
  const tags = [];
  if (analysis.dialect) tags.push(analysis.dialect);
  if (analysis.effect) tags.push(analysis.effect);
  if (analysis.isPoetry) tags.push('温柔');
  if (tags.length === 0) return null;
  return `<style>${tags.join(' ')}</style>`;
}

async function synthesizeSmart(text, output = 'output.wav') {
  console.log('📝 分析文本...');
  const analysis = analyzeText(text);
  
  console.log('📊 检测结果:');
  if (analysis.emotions.length > 0) console.log(`   情感: ${analysis.emotions.join(', ')}`);
  if (analysis.dialect) console.log(`   方言: ${analysis.dialect}`);
  if (analysis.effect) console.log(`   效果: ${analysis.effect}`);
  if (analysis.isPoetry) console.log(`   类型: 诗词`);
  
  const styleTag = generateStyleTag(analysis);
  const processedText = styleTag ? styleTag + text : text;
  
  if (styleTag) console.log(`🏷️ 风格: ${styleTag}`);
  console.log(`🎤 合成中...`);

  const apiKey = process.env.MIMO_API_KEY;
  if (!apiKey) {
    console.error('错误: 请设置 MIMO_API_KEY');
    process.exit(1);
  }

  const response = await fetch(`${API_BASE}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'mimo-v2-tts',
      messages: [
        { role: 'user', content: '你好' },
        { role: 'assistant', content: processedText }
      ],
      audio: { format: 'wav', voice: 'default_zh' }
    })
  });

  const data = await response.json();
  const audioBuffer = Buffer.from(data.choices[0].message.audio.data, 'base64');

  const wavPath = output.endsWith('.wav') ? output : `${output}.wav`;
  fs.writeFileSync(wavPath, audioBuffer);
  
  if (output.endsWith('.ogg')) {
    execSync(`ffmpeg -y -i ${wavPath} -acodec libopus -b:a 128k ${output} 2>/dev/null`);
    fs.unlinkSync(wavPath);
  }
  
  console.log(`✓ 已保存: ${output}`);
  return output;
}

// CLI
const args = process.argv.slice(2);
if (args.length < 1) {
  console.log('用法: node mimo_tts_smart.js "文本" [输出文件]');
  console.log('');
  console.log('✨ 智能分析:');
  console.log('  - 自动检测情感（开心、悲伤、紧张等）');
  console.log('  - 自动识别方言（东北话、四川话、台湾腔等）');
  console.log('  - 自动判断内容类型（诗词、故事等）');
  process.exit(0);
}

const text = args[0];
const output = args[1] || 'output.ogg';

synthesizeSmart(text, output).catch(console.error);
