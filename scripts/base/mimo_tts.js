#!/usr/bin/env node
/**
 * MiMo TTS - 小米 MiMo 语音合成脚本 (Node.js 版本)
 * 
 * 用法:
 *   MIMO_API_KEY=your_key node mimo_tts.js "text" --voice default_zh --style "夹子音" --output output.wav
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const API_BASE = 'https://api.xiaomimimo.com/v1';
const VOICES = ['mimo_default', 'default_zh', 'default_eh'];

async function synthesize(text, options = {}) {
  const {
    voice = 'default_zh',
    style = null,
    output = 'output.wav'
  } = options;

  const apiKey = process.env.XIAOMI_API_KEY || process.env.MIMO_API_KEY;
  if (!apiKey) {
    console.error('错误: 请设置 XIAOMI_API_KEY 或 MIMO_API_KEY (优先使用 XIAOMI_API_KEY)');
    process.exit(1);
  }

  if (!VOICES.includes(voice)) {
    console.error(`错误: 不支持的语音 "${voice}"，可用: ${VOICES.join(', ')}`);
    process.exit(1);
  }

  // 添加风格标签
  const targetText = style ? `<style>${style}</style>${text}` : text;

  console.log(`合成中: ${text.substring(0, 50)}${text.length > 50 ? '...' : ''}`);
  console.log(`语音: ${voice}`);
  if (style) console.log(`风格: ${style}`);

  try {
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
          { role: 'assistant', content: targetText }
        ],
        audio: { format: 'wav', voice: voice }
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API 错误: ${response.status} - ${error}`);
    }

    const data = await response.json();
    const audioData = data.choices[0].message.audio.data;
    const audioBuffer = Buffer.from(audioData, 'base64');

    // 保存 WAV
    const wavPath = output.endsWith('.wav') ? output : `${output}.wav`;
    fs.writeFileSync(wavPath, audioBuffer);
    console.log(`✓ 音频已保存: ${wavPath}`);

    // 转换为 OGG（如果需要）
    if (output.endsWith('.ogg')) {
      execSync(`ffmpeg -y -i ${wavPath} -acodec libopus -b:a 128k ${output} 2>/dev/null`);
      fs.unlinkSync(wavPath);
      console.log(`✓ 已转换为 OGG: ${output}`);
    }

    return output;
  } catch (error) {
    console.error('错误:', error.message);
    process.exit(1);
  }
}

// CLI 解析
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    voice: 'default_zh',
    style: null,
    output: 'output.wav'
  };

  let text = null;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--voice' || arg === '-v') {
      options.voice = args[++i];
    } else if (arg === '--style' || arg === '-s') {
      options.style = args[++i];
    } else if (arg === '--output' || arg === '-o') {
      options.output = args[++i];
    } else if (!arg.startsWith('-')) {
      text = arg;
    }
  }

  if (!text) {
    console.log('用法: node mimo_tts.js "文本" [选项]');
    console.log('');
    console.log('选项:');
    console.log('  --voice, -v <voice>  语音类型 (mimo_default, default_zh, default_eh)');
    console.log('  --style, -s <style>  风格标签 (夹子音, 悄悄话, 东北话 等)');
    console.log('  --output, -o <file>  输出文件 (默认 output.wav)');
    process.exit(1);
  }

  return { text, options };
}

// 主函数
async function main() {
  const { text, options } = parseArgs();
  await synthesize(text, options);
}

main().catch(console.error);
