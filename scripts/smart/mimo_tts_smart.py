#!/usr/bin/env python3
"""
MiMo TTS 智能版 - Python 实现
自动分析文本情感和风格，生成语音
"""

import os
import sys
import json
import re
import subprocess
import base64

# 情感关键词映射
EMOTION_PATTERNS = {
    '开心': ['开心', '高兴', '快乐', '哈哈', '嘻嘻', '太棒', '好棒', '太好了', '厉害', '赞'],
    '悲伤': ['伤心', '难过', '悲伤', '痛苦', '眼泪', '哭', '遗憾', '想念', '怀念'],
    '紧张': ['紧张', '焦虑', '担心', '害怕', '恐惧', '不安', '慌', '急'],
    '愤怒': ['生气', '愤怒', '气死', '烦死', '讨厌', '可恶'],
    '惊讶': ['哇', '天哪', '什么', '不会吧', '真的吗', '难以置信'],
    '温柔': ['亲爱的', '宝贝', '爱你', '喜欢', '温柔', '甜蜜', '幸福'],
}

# 方言关键词（仅在明显方言特征时检测）
DIALECT_PATTERNS = {
    '东北话': ['咋整', '干哈', '瞅啥', '老铁', '没毛病', '杠杠的', '必须的', '埋汰', '嗷嗷的', '整挺好', '贼拉'],
    '四川话': ['巴适', '安逸', '晓得嘛', '莫得事', '雄起', '瓜娃子', '要得', '不得行', '瓜兮兮', '哈戳戳', '神戳戳', '撇脱', '巴心巴肝', '龙门阵'],
    '台湾腔': ['真的假的', '好喔', '是喔', '安捏', '齁', '超', '屁啦', '酱紫', '森77', '484', '母汤', '太扯', '甘安捏', '就酱', '不造', '佛系', '傻眼猫咪', '塑胶', '业配', '森气气', '窝不知道', '矮油', '揪咪', '好der', '好la', '好ne', '好捏', '森77', '拍谢', '矮油', '窝不知道', '傻眼猫咪'],
'台湾闽南话': ['金价', '揪', '水', '赞', '哩厚', '多谢', '拍谢', '甲霸没', '厚', '呷霸没', '呷奔', '呷饱没', '麦安捏', '安抓', '歹势', '搁来', '卡紧', '金厚', '足水', '有够赞'],
    '粤语': ['唔系', '系唔系', '边度', '点样', '冇', '唔', '睇', '食', '嘅', '咗', '咁', '乜嘢', '做乜', '幾多', '點解', '好正', '好掂'],
    '河南话': ['中', '得劲', '得劲儿', '咋着', '恁', '俺', '弄啥嘞', '不老盖', '夜儿个', '前儿个', '晌午', '喝汤', '可中', '美得很', '中不中', '嘞很', '恁弄啥'],
    '上海话': ['侬', '阿拉', '勿', '老好', '覅', '嗲', '老克勒', '伐', '个么', '帮帮忙', '十三点', '捣糨糊', '有腔调', '勿来三', '覅忒', '老卵'],
    '陕西话': ['嫽咋咧', '美滴很', '咥', '谝', '咥饭', '嫽', '忒', '嘹咋咧', '嘹滴很', '么嘛达', '嘹太太'],
'山东话': ['俺那娘嘞', '俺滴个娘', '俺滴乖乖', '俺的娘来', '杠赛来', '熊样', '俺那娘', '恁', '咋', '木', '木有', '杠赛', '得劲', '得劲儿', '俺的天', '俺滴娘', '俺滴娘来', '俺滴娘嘞', '山东话', '山东人', '山东滴'],
}

# 特殊效果
EFFECT_PATTERNS = {
    '悄悄话': ['悄悄', '小声', '秘密', '嘘'],
    '夹子音': ['喵', '主人', '～'],
    '唱歌': ['唱', '歌', '♪', '🎵'],
}

def analyze_text(text):
    """分析文本情感和风格"""
    result = {
        'emotions': [],
        'dialect': None,
        'effect': None,
        'is_poetry': False
    }
    
    # 检测情感
    for emotion, keywords in EMOTION_PATTERNS.items():
        if any(keyword in text for keyword in keywords):
            result['emotions'].append(emotion)
    
    # 检测方言
    for dialect, keywords in DIALECT_PATTERNS.items():
        if any(keyword in text for keyword in keywords):
            result['dialect'] = dialect
            break
    
    # 检测效果
    for effect, keywords in EFFECT_PATTERNS.items():
        if any(keyword in text for keyword in keywords):
            result['effect'] = effect
            break
    
    # 检测诗词（多行短句）
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    if len(lines) >= 2 and all(len(line) <= 30 for line in lines):
        result['is_poetry'] = True
    
    return result

def generate_style_tag(analysis):
    """生成 style 标签"""
    tags = []
    
    if analysis['dialect']:
        tags.append(analysis['dialect'])
    
    if analysis['effect']:
        tags.append(analysis['effect'])
    
    # 优先使用检测到的情感，诗词自动用温柔风格
    if analysis['is_poetry']:
        tags.append('温柔')
    elif analysis['emotions']:
        # 取第一个检测到的情感
        tags.append(analysis['emotions'][0])
    
    if tags:
        return f"<style>{' '.join(tags)}</style>"
    return None

def synthesize_smart(text, output_file='output.wav'):
    """智能合成语音"""
    print("📝 分析文本...")
    analysis = analyze_text(text)
    
    print("📊 检测结果:")
    if analysis['emotions']:
        print(f"   情感: {', '.join(analysis['emotions'])}")
    if analysis['dialect']:
        print(f"   方言: {analysis['dialect']}")
    if analysis['effect']:
        print(f"   效果: {analysis['effect']}")
    if analysis['is_poetry']:
        print("   类型: 诗词")
    
    style_tag = generate_style_tag(analysis)
    processed_text = f"{style_tag}{text}" if style_tag else text
    
    if style_tag:
        print(f"🏷️ 风格: {style_tag}")
    
    print("🎤 合成中...")
    
    api_key = os.getenv('MIMO_API_KEY')
    if not api_key:
        print("错误: 请设置 MIMO_API_KEY 环境变量")
        sys.exit(1)
    
    # 调用基础脚本
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    base_script = os.path.join(script_dir, 'base', 'mimo-tts.sh')
    result = subprocess.run(
        [base_script, processed_text, output_file],
        env={**os.environ, 'MIMO_STYLE': ''},  # 清空 MIMO_STYLE 让脚本自动处理
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print(f"✅ 已保存: {output_file}")
        return output_file
    else:
        print(f"❌ 合成失败: {result.stderr}")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("用法: mimo_tts_smart.py \"文本内容\" [输出文件]")
        sys.exit(1)
    
    text = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'output.ogg'
    
    synthesize_smart(text, output_file)