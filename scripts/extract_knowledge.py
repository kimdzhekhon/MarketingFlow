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
    'security': '보안',
    'telemetry': '텔레메트리',
}

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

    return {
        'id': generate_id(category_key, title, rel_path),
        'category': category,
        'type': file_type,
        'title': title,
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
        'seo-ops', 'team-ops', 'security', 'telemetry',
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
