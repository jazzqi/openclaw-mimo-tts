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

// Real implementation placeholder: call Xiaomi API (mocked)
console.log('Real API key present but remote call not implemented in this template.');
console.log('Would send text length', text.length, 'voice', voice, 'style', style);
// For safety, write mock output
try{
  fs.writeFileSync(output,'');
  console.log(output);
  process.exit(0);
}catch(e){
  console.error('Failed to write output', e);
  process.exit(1);
}
