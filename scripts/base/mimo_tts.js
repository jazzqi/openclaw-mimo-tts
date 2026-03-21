#!/usr/bin/env node
// Minimal Node.js base implementation for xiaomi-mimo-tts
// Usage: node mimo_tts.js "文本" [output.ogg] [--voice voice] [--style style]

const fs = require('fs');
const { spawnSync } = require('child_process');

const args = process.argv.slice(2);
if (!args[0]) {
  console.error('Usage: node mimo_tts.js "TEXT" [OUTPUT] [--voice VOICE] [--style STYLE]');
  process.exit(2);
}
let text = args[0];
let output = args[1] && !args[1].startsWith('--') ? args[1] : `${process.cwd()}/output.mock.ogg`;
let voice = 'mimo_default';
let style = '';
for (let i=2;i<args.length;i++){
  if (args[i]==='--voice') voice = args[i+1]||voice, i++;
  if (args[i]==='--style') style = args[i+1]||style, i++;
}

const XIAOMI_API_KEY = process.env.XIAOMI_API_KEY || process.env.MIMO_API_KEY || '';
const MOCK = !XIAOMI_API_KEY;

if (MOCK) {
  // generate mock silent ogg using ffmpeg if available
  const ff = spawnSync('ffmpeg',['-f','lavfi','-i','anullsrc=r=16000:cl=mono','-t','0.5','-q:a','9','-acodec','libopus',output,'-y']);
  if (ff.error) fs.writeFileSync(output,'');
  console.log(output);
  process.exit(0);
}

// Real implementation: call Xiaomi MiMo API and decode returned base64 audio
const https = require('https');

const body = JSON.stringify({
  model: 'mimo-v2-tts',
  messages: [
    {role: 'user', content: '请朗读'},
    {role: 'assistant', content: text}
  ],
  audio: {format: 'wav', voice}
});

const options = {
  hostname: 'api.xiaomimimo.com',
  port: 443,
  path: '/v1/chat/completions',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${XIAOMI_API_KEY}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body)
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    try {
      const j = JSON.parse(data);
      const audio_b64 = j.choices[0].message.audio.data;
      const wav = Buffer.from(audio_b64, 'base64');
      const wavPath = output + '.wav';
      fs.writeFileSync(wavPath, wav);
      // convert to ogg
      const ff = spawnSync('ffmpeg', ['-y','-i',wavPath,'-acodec','libopus','-b:a','128k',output]);
      try{ fs.unlinkSync(wavPath);}catch(e){}
      console.log(output);
    } catch (e) {
      console.error('Failed to parse response or extract audio', e);
      console.error(data);
      process.exit(1);
    }
  });
});

req.on('error', (e) => { console.error('Request error', e); process.exit(1); });
req.write(body);
req.end();
