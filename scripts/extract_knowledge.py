#!/usr/bin/env python3
"""
MarketingFlow - 완전 지식 베이스 추출기
소스: ericosiu/ai-marketing-skills (MIT License, Copyright 2026 Single Grain)

모든 .md, .py, .json, .env.example 파일을 파싱하여
Flutter 앱용 통합 JSON 데이터셋으로 변환합니다.
"""

import os
import re
import json
import hashlib
from datetime import date
from pathlib import Path

# ── 카테고리 한글 매핑 ──
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

# ── 영어→한글 제목 번역 맵 ──
TITLE_KO_MAP = {
    'content ops': '콘텐츠 운영',
    'ai content ops': '콘텐츠 운영',
    'conversion ops': '전환 최적화',
    'finance ops': '재무 운영',
    'growth engine': '성장 엔진',
    'outbound engine': '아웃바운드 엔진',
    'podcast ops': '팟캐스트 운영',
    'revenue intelligence': '매출 인텔리전스',
    'sales pipeline': '세일즈 파이프라인',
    'sales playbook': '세일즈 플레이북',
    'seo ops': 'SEO 운영',
    'ai seo ops': 'SEO 운영',
    'team ops': '팀 운영',
    'expert assembly guide': '전문가 패널 구성 가이드',
    'linkedin': 'LinkedIn 콘텐츠 전문가',
    'instagram': 'Instagram 콘텐츠 전문가',
    'newsletter': '뉴스레터 전문가',
    'humanizer': '휴머나이저',
    'podcast quotes': '팟캐스트 인용구 전문가',
    'recruiting': '채용 콘텐츠 전문가',
    'seo strategy': 'SEO 전략가',
    'x articles': 'X(트위터) 아티클 전문가',
    'youtube shorts': 'YouTube Shorts 전문가',
    'content quality': '콘텐츠 품질 평가',
    'conversion quality': '전환 품질 평가',
    'evaluation quality': '평가 품질',
    'strategic quality': '전략적 품질',
    'visual quality': '비주얼 품질',
    'patterns': '패턴 라이브러리',
    'skill': '스킬 정의',
    'cro audit': 'CRO 감사',
    'survey lead magnet': '설문 리드 마그넷',
    'cfo analyzer': 'CFO 분석기',
    'scenario modeler': '시나리오 모델러',
    'experiment engine': '실험 엔진',
    'autogrowth weekly scorecard': '주간 성장 스코어카드',
    'pacing alert': '페이싱 알림',
    'cold outbound sender': '콜드 아웃바운드 발송',
    'competitive monitor': '경쟁사 모니터링',
    'cross signal detector': '크로스 시그널 감지기',
    'instantly audit': 'Instantly 감사',
    'lead pipeline': '리드 파이프라인',
    'podcast pipeline': '팟캐스트 파이프라인',
    'client report generator': '클라이언트 리포트 생성기',
    'gong insight pipeline': 'Gong 인사이트 파이프라인',
    'revenue attribution': '매출 어트리뷰션',
    'deal resurrector': '딜 부활기',
    'icp learning analyzer': 'ICP 학습 분석기',
    'trigger prospector': '트리거 프로스펙터',
    'call analyzer': '콜 분석기',
    'value pricing briefing': '밸류 프라이싱 브리핑',
    'value pricing packager': '밸류 프라이싱 패키저',
    'pricing pattern library': '가격 패턴 라이브러리',
    'content attack brief': '콘텐츠 공격 브리프',
    'gsc auth': 'Google Search Console 인증',
    'gsc client': 'Google Search Console 클라이언트',
    'trend scout': '트렌드 스카우트',
    'meeting action extractor': '미팅 액션 추출기',
    'team performance audit': '팀 성과 감사',
    'copy rules': '카피 규칙',
    'expert panel': '전문가 패널',
    'icp template': 'ICP 템플릿',
    'instantly rules': 'Instantly 규칙',
    'claude roi': 'Claude ROI 분석',
    'metrics guide': '지표 가이드',
    'org overhead': '조직 오버헤드',
    'output template': '출력 템플릿',
    'quickbooks formats': 'QuickBooks 형식',
    'rates': '요율표',
    'team cost': '팀 비용',
    'content quality gate': '콘텐츠 품질 게이트',
    'content quality scorer': '콘텐츠 품질 스코어러',
    'content transform': '콘텐츠 변환',
    'editorial brain': '편집 브레인',
    'quote mining engine': '인용구 마이닝 엔진',
    'rb2b instantly router': 'RB2B 라우터',
    'rb2b suppression pipeline': 'RB2B 억제 파이프라인',
    'rb2b webhook ingest': 'RB2B 웹훅 수집',
    'ai revenue intelligence': '매출 인텔리전스',
}

def get_title_ko(title, file_name='', category='', file_type=''):
    """영어 제목을 한글로 변환"""
    key = title.lower().strip()
    if key in TITLE_KO_MAP:
        return TITLE_KO_MAP[key]
    # 파일명 기반 변환 시도
    normalized = key.replace('-', ' ').replace('_', ' ')
    if normalized in TITLE_KO_MAP:
        return TITLE_KO_MAP[normalized]
    # 파일명 자체로 시도
    fn = file_name.lower().replace('.md','').replace('.py','').replace('.json','').replace('.txt','').replace('.example','').replace('.env','').replace('-',' ').replace('_',' ').strip()
    if fn in TITLE_KO_MAP:
        return TITLE_KO_MAP[fn]
    # 설정/의존성/환경 파일은 카테고리 + 파일타입으로
    if file_type in ('config_template', 'config', 'requirements'):
        type_labels = {
            'config_template': '환경 설정',
            'config': '설정 파일',
            'requirements': '의존성 목록',
        }
        return '%s %s' % (category, type_labels.get(file_type, ''))
    # 문서(README)는 카테고리 + 가이드
    if file_type == 'documentation':
        return '%s 가이드' % category
    return ''

# ── 파일 타입별 분류 ──
FILE_TYPE_MAP = {
    'SKILL.md': 'skill',
    'README.md': 'readme',
}

def generate_id(category, title, filepath):
    raw = "%s_%s_%s" % (category, title, filepath)
    return hashlib.md5(raw.encode()).hexdigest()[:12]

def extract_variables_from_text(content):
    """텍스트에서 사용자 입력 변수를 추출"""
    variables = set()
    # {variable} 패턴
    for m in re.finditer(r'\{(\w[\w\s]{0,48}\w)\}', content):
        var = m.group(1).strip()
        if var.lower() not in ('e.g', 'etc', 'i.e', 'note', 'json', 'text', 'html', 'http', 'https'):
            variables.add(var)
    # [VARIABLE] 패턴
    for m in re.finditer(r'\[([A-Z][A-Z_\s]{1,40})\]', content):
        variables.add(m.group(1).strip())
    # {{variable}} 패턴
    for m in re.finditer(r'\{\{(\w[\w\s]{0,48}\w)\}\}', content):
        variables.add(m.group(1).strip())
    return sorted(variables)

def extract_variables_from_python(content):
    """Python 파일에서 argparse 인자, 환경변수 등을 추출"""
    variables = set()
    # argparse arguments: add_argument('--name')
    for m in re.finditer(r'add_argument\([\'"]--?([\w-]+)[\'"]', content):
        variables.add(m.group(1).replace('-', '_'))
    # os.environ.get('NAME') or os.getenv('NAME')
    for m in re.finditer(r'(?:environ\.get|getenv)\([\'"](\w+)[\'"]', content):
        var = m.group(1)
        if not var.startswith(('PATH', 'HOME', 'USER', 'LANG')):
            variables.add(var)
    # input() calls
    for m in re.finditer(r'input\([\'"]([^"\']+)[\'"]', content):
        variables.add(m.group(1)[:50])
    return sorted(variables) if variables else ['입력 데이터']

def extract_title_from_md(content, filename):
    """마크다운에서 제목 추출"""
    for line in content.strip().split('\n')[:10]:
        line = line.strip()
        if line.startswith('# '):
            return line[2:].strip()
    return filename.replace('.md', '').replace('-', ' ').replace('_', ' ').title()

def extract_title_from_py(content, filename):
    """Python 파일에서 제목 추출 (docstring 첫 줄)"""
    m = re.search(r'"""(.+?)(?:\n|""")', content)
    if m:
        title = m.group(1).strip()
        if len(title) > 5:
            return title[:80]
    return filename.replace('.py', '').replace('-', ' ').replace('_', ' ').title()

def extract_description(content, max_len=500):
    """파일에서 설명 추출"""
    lines = content.strip().split('\n')
    desc_lines = []
    started = False
    for line in lines:
        stripped = line.strip()
        if not started:
            if stripped.startswith('# ') or stripped.startswith('"""'):
                started = True
                # docstring 첫줄 건너뛰기
                if stripped.startswith('"""') and len(stripped) > 3:
                    rest = stripped[3:].strip()
                    if rest and not rest.endswith('"""'):
                        continue
                continue
        elif started:
            if stripped.startswith('#') or stripped == '"""' or stripped == '---':
                break
            if stripped:
                desc_lines.append(stripped)
            if len(desc_lines) >= 5:
                break
    return ' '.join(desc_lines)[:max_len] if desc_lines else ''

def detect_file_type(rel_path):
    """파일 경로로부터 타입 결정"""
    parts = Path(rel_path).parts
    name = Path(rel_path).name
    ext = Path(rel_path).suffix

    if name == 'SKILL.md':
        return 'skill_definition'
    elif name == 'README.md':
        return 'documentation'
    elif ext == '.md' and 'experts' in parts:
        return 'expert_persona'
    elif ext == '.md' and 'references' in parts:
        return 'reference'
    elif ext == '.md' and 'scoring-rubrics' in parts:
        return 'scoring_rubric'
    elif ext == '.py' and 'scripts' in parts:
        return 'automation_script'
    elif ext == '.py':
        return 'automation_script'
    elif name.endswith('.env.example'):
        return 'config_template'
    elif ext == '.json':
        return 'config'
    elif ext == '.txt':
        return 'requirements'
    else:
        return 'other'

def parse_file(filepath, rel_path):
    """모든 파일 타입을 파싱"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return None

    if len(content.strip()) < 10:
        return None

    parts = Path(rel_path).parts
    category_key = parts[0] if parts else 'general'
    category = CATEGORY_MAP.get(category_key, category_key.replace('-', ' ').title())

    ext = Path(filepath).suffix
    name = Path(filepath).name
    file_type = detect_file_type(rel_path)

    if ext == '.md':
        title = extract_title_from_md(content, Path(filepath).stem)
        variables = extract_variables_from_text(content)
    elif ext == '.py':
        title = extract_title_from_py(content, Path(filepath).stem)
        variables = extract_variables_from_python(content)
    else:
        title = name
        variables = []

    description = extract_description(content)
    if not description:
        description = '%s - %s' % (category, title)

    title_ko = get_title_ko(title, name, category, file_type)

    return {
        'id': generate_id(category_key, title, rel_path),
        'category': category,
        'type': file_type,
        'title': title,
        'title_ko': title_ko,
        'description': description,
        'system_prompt': content,
        'variables': variables if variables else ['주제', '목표', '대상 고객'],
        'origin_path': rel_path,
        'file_name': name,
    }

def scan_all(source_dir):
    """리포지토리 전체를 재귀적으로 스캔"""
    skills = []
    source_path = Path(source_dir)

    if not source_path.exists():
        print("소스 디렉토리 없음: %s" % source_dir)
        return skills

    # 스킬 디렉토리 목록
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

        # 해당 디렉토리의 모든 파일을 재귀적으로 탐색
        for root, dirs, files in os.walk(str(dir_path)):
            # .git, __pycache__, .env 등 제외
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']

            for filename in sorted(files):
                # 대상 확장자
                if not any(filename.endswith(ext) for ext in ['.md', '.py', '.json', '.env.example', '.txt']):
                    continue

                filepath = os.path.join(root, filename)
                rel_path = os.path.relpath(filepath, source_path)
                parsed = parse_file(filepath, rel_path)
                if parsed:
                    skills.append(parsed)

    return skills

def main():
    import sys
    source_dir = sys.argv[1] if len(sys.argv) > 1 else '.tmp_source'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'assets/marketing_knowledge_base.json'

    print("전체 스캔 중: %s" % source_dir)
    skills = scan_all(source_dir)
    print("총 %d개 항목 추출 완료" % len(skills))

    # 타입별 통계
    type_counts = {}
    for s in skills:
        t = s['type']
        type_counts[t] = type_counts.get(t, 0) + 1
    print("\n타입별 분포:")
    for t, c in sorted(type_counts.items()):
        print("  %-20s: %d개" % (t, c))

    # 카테고리별 통계
    cat_counts = {}
    for s in skills:
        cat = s['category']
        cat_counts[cat] = cat_counts.get(cat, 0) + 1
    print("\n카테고리별 분포:")
    for cat, c in sorted(cat_counts.items()):
        print("  %-20s: %d개" % (cat, c))

    output = {
        'version': '2.0.0',
        'last_updated': str(date.today()),
        'total_items': len(skills),
        'license': {
            'type': 'MIT',
            'copyright': 'Copyright (c) 2026 Single Grain',
            'author': 'Eric Siu / Single Grain',
            'source': 'https://github.com/ericosiu/ai-marketing-skills',
        },
        'categories': sorted(cat_counts.keys()),
        'type_summary': type_counts,
        'skills': skills,
    }

    os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print("\nJSON 저장 완료: %s" % output_file)
    print("파일 크기: %.1f KB" % (os.path.getsize(output_file) / 1024))

if __name__ == '__main__':
    main()
