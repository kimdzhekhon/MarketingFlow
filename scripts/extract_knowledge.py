#!/usr/bin/env python3
"""
MarketingFlow Knowledge Base Extractor
소스: ericosiu/ai-marketing-skills (MIT License)
마케팅 SKILL.md 파일들을 파싱하여 Flutter 앱용 JSON 데이터셋으로 변환합니다.
"""

import os
import re
import json
import hashlib
from datetime import date
from pathlib import Path

def extract_variables(content):
    """시스템 프롬프트에서 사용자 입력 변수를 추출합니다."""
    variables = set()
    # {variable} 패턴
    for m in re.finditer(r'\{(\w[\w\s]*?\w)\}', content):
        var = m.group(1).strip()
        if len(var) < 50 and var.lower() not in ('e.g', 'etc', 'i.e', 'note'):
            variables.add(var)
    # [VARIABLE] 패턴
    for m in re.finditer(r'\[([A-Z][A-Z_\s]+)\]', content):
        variables.add(m.group(1).strip())
    # {{variable}} 패턴
    for m in re.finditer(r'\{\{(\w[\w\s]*?\w)\}\}', content):
        variables.add(m.group(1).strip())
    return sorted(variables)

def extract_title(content, filename):
    """파일에서 제목을 추출합니다."""
    lines = content.strip().split('\n')
    for line in lines:
        line = line.strip()
        if line.startswith('# '):
            return line[2:].strip()
    return filename.replace('.md', '').replace('-', ' ').replace('_', ' ').title()

def extract_description(content):
    """파일에서 설명을 추출합니다."""
    lines = content.strip().split('\n')
    in_desc = False
    desc_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('# '):
            in_desc = True
            continue
        if in_desc and stripped and not stripped.startswith('#'):
            desc_lines.append(stripped)
            if len(desc_lines) >= 3:
                break
        elif in_desc and stripped.startswith('#'):
            break
    return ' '.join(desc_lines)[:300] if desc_lines else ''

CATEGORY_MAP = {
    'content-ops': '콘텐츠 운영',
    'conversion-ops': '전환 최적화',
    'finance-ops': '재무 운영',
    'growth-engine': '성장 엔진',
    'outbound-engine': '아웃바운드 엔진',
    'podcast-ops': '팟캐스트 운영',
    'revenue-intelligence': '매출 인텔리전스',
    'sales-pipeline': '세일즈 파이프라인',
    'sales-playbook': '세일즈 플레이북',
    'seo-ops': 'SEO 운영',
    'team-ops': '팀 운영',
}

def generate_id(category, title):
    raw = f"{category}_{title}".lower()
    return hashlib.md5(raw.encode()).hexdigest()[:12]

def parse_skill_file(filepath, rel_path):
    """SKILL.md 또는 기타 마크다운 파일을 파싱합니다."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return None

    if len(content.strip()) < 50:
        return None

    parts = Path(rel_path).parts
    category_key = parts[0] if parts else 'general'
    category = CATEGORY_MAP.get(category_key, category_key.replace('-', ' ').title())

    title = extract_title(content, Path(filepath).stem)
    description = extract_description(content)
    variables = extract_variables(content)

    return {
        'id': generate_id(category_key, title),
        'category': category,
        'title': title,
        'description': description if description else f'{category} - {title}',
        'system_prompt': content,
        'variables': variables if variables else ['주제', '목표', '대상 고객'],
        'origin_path': rel_path,
    }

def scan_repository(source_dir):
    """리포지토리를 스캔하여 모든 마케팅 스킬을 추출합니다."""
    skills = []
    source_path = Path(source_dir)

    if not source_path.exists():
        print(f"소스 디렉토리를 찾을 수 없습니다: {source_dir}")
        return get_fallback_skills()

    skill_dirs = [
        'content-ops', 'conversion-ops', 'finance-ops',
        'growth-engine', 'outbound-engine', 'podcast-ops',
        'revenue-intelligence', 'sales-pipeline', 'sales-playbook',
        'seo-ops', 'team-ops',
    ]

    for skill_dir in skill_dirs:
        dir_path = source_path / skill_dir
        if not dir_path.exists():
            continue

        # SKILL.md 파일 우선 처리
        skill_md = dir_path / 'SKILL.md'
        if skill_md.exists():
            rel = str(skill_md.relative_to(source_path))
            parsed = parse_skill_file(str(skill_md), rel)
            if parsed:
                skills.append(parsed)

        # 하위 마크다운 파일 (experts, references, scoring-rubrics)
        for sub_dir in ['experts', 'references', 'scoring-rubrics']:
            sub_path = dir_path / sub_dir
            if not sub_path.exists():
                continue
            for md_file in sorted(sub_path.glob('*.md')):
                rel = str(md_file.relative_to(source_path))
                parsed = parse_skill_file(str(md_file), rel)
                if parsed:
                    skills.append(parsed)

    if not skills:
        return get_fallback_skills()

    return skills

def get_fallback_skills():
    """소스 리포를 사용할 수 없을 때 기본 스킬셋을 반환합니다."""
    return [
        {
            'id': 'fb_content_01',
            'category': '콘텐츠 운영',
            'title': 'LinkedIn 콘텐츠 전략가',
            'description': 'LinkedIn 포스트를 작성하고 최적화하는 AI 마케팅 전문가',
            'system_prompt': 'You are an expert LinkedIn content strategist. Your role is to help create engaging, professional LinkedIn posts that drive engagement and build thought leadership.\n\nGiven the following inputs:\n- Topic: {topic}\n- Target Audience: {target_audience}\n- Goal: {goal}\n- Tone: {tone}\n\nCreate a compelling LinkedIn post that:\n1. Opens with a strong hook (first 2 lines are critical)\n2. Provides actionable value\n3. Uses appropriate formatting (line breaks, emojis if suitable)\n4. Ends with a clear call-to-action\n5. Includes relevant hashtags',
            'variables': ['topic', 'target_audience', 'goal', 'tone'],
            'origin_path': 'content-ops/experts/linkedin.md',
        },
        {
            'id': 'fb_seo_01',
            'category': 'SEO 운영',
            'title': 'SEO 콘텐츠 공격 브리프',
            'description': '경쟁사 분석 기반 SEO 콘텐츠 전략 수립',
            'system_prompt': 'You are an expert SEO strategist specializing in content attack briefs. Analyze the competitive landscape and create a detailed content strategy.\n\nInputs:\n- Target Keyword: {keyword}\n- Industry: {industry}\n- Current Domain Authority: {domain_authority}\n- Top Competitors: {competitors}\n\nDeliver:\n1. Keyword cluster analysis\n2. Content gap identification\n3. Recommended content calendar (12 weeks)\n4. On-page optimization checklist\n5. Internal linking strategy\n6. Expected traffic projections',
            'variables': ['keyword', 'industry', 'domain_authority', 'competitors'],
            'origin_path': 'seo-ops/SKILL.md',
        },
        {
            'id': 'fb_growth_01',
            'category': '성장 엔진',
            'title': '그로스 실험 엔진',
            'description': '데이터 기반 성장 실험 설계 및 실행 프레임워크',
            'system_prompt': 'You are a growth experiment engine. Design and prioritize growth experiments using the ICE scoring framework.\n\nInputs:\n- Product/Service: {product}\n- Current Metrics: {metrics}\n- Growth Goal: {growth_goal}\n- Budget: {budget}\n- Timeline: {timeline}\n\nProcess:\n1. Identify top 10 growth levers\n2. Score each using ICE (Impact, Confidence, Ease)\n3. Design top 3 experiments with hypothesis, metrics, and success criteria\n4. Create weekly sprint plan\n5. Define rollback criteria',
            'variables': ['product', 'metrics', 'growth_goal', 'budget', 'timeline'],
            'origin_path': 'growth-engine/SKILL.md',
        },
        {
            'id': 'fb_sales_01',
            'category': '세일즈 파이프라인',
            'title': 'ICP 학습 엔진',
            'description': '이상적 고객 프로필(ICP) 분석 및 타겟팅 최적화',
            'system_prompt': 'You are an ICP (Ideal Customer Profile) learning engine. Analyze customer data to refine targeting.\n\nInputs:\n- Industry: {industry}\n- Product: {product}\n- Current Customers: {customer_data}\n- Revenue Range: {revenue_range}\n\nDeliver:\n1. ICP scoring matrix\n2. Firmographic analysis\n3. Behavioral signals identification\n4. Recommended outreach sequences\n5. Disqualification criteria',
            'variables': ['industry', 'product', 'customer_data', 'revenue_range'],
            'origin_path': 'sales-pipeline/SKILL.md',
        },
        {
            'id': 'fb_outbound_01',
            'category': '아웃바운드 엔진',
            'title': '콜드 아웃바운드 시퀀스',
            'description': '개인화된 콜드 이메일 시퀀스 자동 생성',
            'system_prompt': 'You are a cold outbound specialist. Create personalized email sequences that get responses.\n\nInputs:\n- Target ICP: {icp}\n- Value Proposition: {value_prop}\n- Pain Points: {pain_points}\n- Social Proof: {social_proof}\n\nCreate a 5-email sequence:\n1. Pattern interrupt opener\n2. Value-add follow-up\n3. Case study / social proof\n4. Breakup email with urgency\n5. Final value offer\n\nEach email should be under 100 words with personalization tokens.',
            'variables': ['icp', 'value_prop', 'pain_points', 'social_proof'],
            'origin_path': 'outbound-engine/SKILL.md',
        },
        {
            'id': 'fb_conversion_01',
            'category': '전환 최적화',
            'title': 'CRO 감사 프레임워크',
            'description': '랜딩 페이지 및 퍼널 전환율 최적화 감사',
            'system_prompt': 'You are a CRO (Conversion Rate Optimization) auditor. Perform comprehensive audits of landing pages and funnels.\n\nInputs:\n- Landing Page URL: {url}\n- Current Conversion Rate: {conversion_rate}\n- Traffic Volume: {traffic}\n- Industry Benchmark: {benchmark}\n\nAudit Areas:\n1. Above-the-fold analysis\n2. Value proposition clarity\n3. Trust signals inventory\n4. Form friction assessment\n5. Mobile experience review\n6. Page speed impact\n7. A/B test recommendations (prioritized)',
            'variables': ['url', 'conversion_rate', 'traffic', 'benchmark'],
            'origin_path': 'conversion-ops/SKILL.md',
        },
        {
            'id': 'fb_revenue_01',
            'category': '매출 인텔리전스',
            'title': '매출 어트리뷰션 분석기',
            'description': '마케팅 채널별 매출 기여도 분석 및 최적화',
            'system_prompt': 'You are a revenue attribution analyst. Map marketing efforts to revenue impact.\n\nInputs:\n- Channels: {channels}\n- Revenue Data: {revenue_data}\n- Time Period: {time_period}\n- Attribution Model: {attribution_model}\n\nDeliver:\n1. Multi-touch attribution analysis\n2. Channel ROI comparison\n3. Customer journey mapping\n4. Budget reallocation recommendations\n5. Predictive revenue modeling',
            'variables': ['channels', 'revenue_data', 'time_period', 'attribution_model'],
            'origin_path': 'revenue-intelligence/SKILL.md',
        },
        {
            'id': 'fb_finance_01',
            'category': '재무 운영',
            'title': 'CFO 분석기',
            'description': '마케팅 투자 대비 수익 분석 및 시나리오 모델링',
            'system_prompt': 'You are a CFO-level financial analyzer for marketing operations. Evaluate marketing spend efficiency.\n\nInputs:\n- Monthly Budget: {budget}\n- Channel Spend: {channel_spend}\n- Revenue by Channel: {revenue_by_channel}\n- Target ROAS: {target_roas}\n\nDeliver:\n1. Current ROAS by channel\n2. CAC analysis\n3. LTV:CAC ratio evaluation\n4. Budget optimization model\n5. 3-month scenario projections (conservative/moderate/aggressive)',
            'variables': ['budget', 'channel_spend', 'revenue_by_channel', 'target_roas'],
            'origin_path': 'finance-ops/SKILL.md',
        },
        {
            'id': 'fb_podcast_01',
            'category': '팟캐스트 운영',
            'title': '팟캐스트 파이프라인',
            'description': '팟캐스트 기획부터 배포까지 전체 워크플로우 관리',
            'system_prompt': 'You are a podcast operations manager. Manage the full podcast pipeline from ideation to distribution.\n\nInputs:\n- Show Theme: {theme}\n- Target Audience: {audience}\n- Episode Frequency: {frequency}\n- Guest Info: {guest_info}\n\nDeliver:\n1. Episode brief with talking points\n2. Pre-interview research summary\n3. Show notes template\n4. Social media clip suggestions (with timestamps)\n5. SEO-optimized episode description\n6. Cross-promotion strategy',
            'variables': ['theme', 'audience', 'frequency', 'guest_info'],
            'origin_path': 'podcast-ops/SKILL.md',
        },
        {
            'id': 'fb_team_01',
            'category': '팀 운영',
            'title': '팀 성과 분석기',
            'description': '마케팅 팀 생산성 및 성과 지표 분석',
            'system_prompt': 'You are a team performance analyst. Evaluate marketing team productivity and effectiveness.\n\nInputs:\n- Team Size: {team_size}\n- Current KPIs: {kpis}\n- Sprint Data: {sprint_data}\n- Goals: {goals}\n\nDeliver:\n1. Individual performance scorecard\n2. Team velocity analysis\n3. Bottleneck identification\n4. Skill gap assessment\n5. Recommended process improvements\n6. Resource allocation optimization',
            'variables': ['team_size', 'kpis', 'sprint_data', 'goals'],
            'origin_path': 'team-ops/SKILL.md',
        },
    ]

def main():
    import sys
    source_dir = sys.argv[1] if len(sys.argv) > 1 else '.tmp_source'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'assets/marketing_knowledge_base.json'

    print(f"소스 디렉토리 스캔 중: {source_dir}")
    skills = scan_repository(source_dir)
    print(f"총 {len(skills)}개 스킬 추출 완료")

    # 카테고리별 통계
    categories = {}
    for s in skills:
        cat = s['category']
        categories[cat] = categories.get(cat, 0) + 1
    for cat, count in sorted(categories.items()):
        print(f"  - {cat}: {count}개")

    output = {
        'version': '1.0.0',
        'last_updated': str(date.today()),
        'license': {
            'type': 'MIT',
            'copyright': 'Copyright (c) 2026 Single Grain',
            'author': 'Eric Siu / Single Grain',
            'source': 'https://github.com/ericosiu/ai-marketing-skills',
        },
        'skills': skills,
    }

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"JSON 저장 완료: {output_file}")

if __name__ == '__main__':
    main()
