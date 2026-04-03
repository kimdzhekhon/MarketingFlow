#!/bin/bash
set -e

# ============================================================
# MarketingFlow - 완전 추출 + 로고 + README + PR 셸 스크립트
# 소스: https://github.com/ericosiu/ai-marketing-skills (MIT)
# 대상: https://github.com/kimdzhekhon/MarketingFlow.git
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/ai-marketing-skills-full"
ASSETS_DIR="$PROJECT_DIR/assets"
SCRIPTS_DIR="$PROJECT_DIR/scripts"

echo "========================================"
echo "  MarketingFlow 완전 추출 시작"
echo "========================================"

# ─── 1단계: 소스 리포 클론 ───
echo ""
echo "[1/8] 소스 리포지토리 전체 클론 중..."
rm -rf "$TEMP_DIR"
git clone https://github.com/ericosiu/ai-marketing-skills.git "$TEMP_DIR" 2>&1 | tail -1

echo "  소스 파일 통계:"
echo "    .md 파일: $(find "$TEMP_DIR" -name '*.md' -not -path '*/.git/*' | wc -l | tr -d ' ')개"
echo "    .py 파일: $(find "$TEMP_DIR" -name '*.py' -not -path '*/.git/*' | wc -l | tr -d ' ')개"
echo "    설정 파일: $(find "$TEMP_DIR" \( -name '*.json' -o -name '*.env.example' -o -name '*.txt' \) -not -path '*/.git/*' | wc -l | tr -d ' ')개"

# ─── 2단계: 완전 추출 Python 스크립트 ───
echo ""
echo "[2/8] 완전 추출 스크립트 생성 및 실행 중..."

mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/extract_knowledge.py" << 'PYTHON_EOF'
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
PYTHON_EOF

chmod +x "$SCRIPTS_DIR/extract_knowledge.py"

# 추출 실행
python3 "$SCRIPTS_DIR/extract_knowledge.py" "$TEMP_DIR" "$ASSETS_DIR/marketing_knowledge_base.json"

# ─── 3단계: 모델 업데이트 (type 필드 추가) ───
echo ""
echo "[3/8] Flutter 모델 업데이트 중..."

cat > "$PROJECT_DIR/lib/models/marketing_skill.dart" << 'DART_MODEL'
import 'dart:convert';
import 'package:flutter/services.dart';

class MarketingSkill {
  final String id;
  final String category;
  final String type;
  final String title;
  final String description;
  final String systemPrompt;
  final List<String> variables;
  final String originPath;
  final String fileName;

  const MarketingSkill({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.variables,
    required this.originPath,
    required this.fileName,
  });

  factory MarketingSkill.fromJson(Map<String, dynamic> json) {
    return MarketingSkill(
      id: json['id'] as String,
      category: json['category'] as String,
      type: json['type'] as String? ?? 'skill_definition',
      title: json['title'] as String,
      description: json['description'] as String,
      systemPrompt: json['system_prompt'] as String,
      variables: List<String>.from(json['variables'] as List),
      originPath: json['origin_path'] as String,
      fileName: json['file_name'] as String? ?? '',
    );
  }

  bool get isSkillDefinition => type == 'skill_definition';
  bool get isExpert => type == 'expert_persona';
  bool get isScript => type == 'automation_script';
  bool get isReference => type == 'reference';
  bool get isRubric => type == 'scoring_rubric';
  bool get isDoc => type == 'documentation';

  String get typeLabel {
    switch (type) {
      case 'skill_definition':
        return '스킬 정의';
      case 'expert_persona':
        return '전문가 페르소나';
      case 'automation_script':
        return '자동화 스크립트';
      case 'reference':
        return '참고자료';
      case 'scoring_rubric':
        return '평가 루브릭';
      case 'documentation':
        return '문서';
      case 'config_template':
        return '설정 템플릿';
      case 'config':
        return '설정';
      case 'requirements':
        return '의존성';
      default:
        return type;
    }
  }

  IconLabel get typeIcon {
    switch (type) {
      case 'skill_definition':
        return IconLabel(0xe1b0, 'purple');      // auto_awesome
      case 'expert_persona':
        return IconLabel(0xe7fd, 'blue');         // person
      case 'automation_script':
        return IconLabel(0xe86f, 'green');        // code
      case 'reference':
        return IconLabel(0xe873, 'orange');       // description
      case 'scoring_rubric':
        return IconLabel(0xef6e, 'red');          // grading
      case 'documentation':
        return IconLabel(0xe865, 'teal');         // article
      default:
        return IconLabel(0xe2c7, 'grey');         // settings
    }
  }
}

class IconLabel {
  final int codePoint;
  final String color;
  const IconLabel(this.codePoint, this.color);
}

class KnowledgeBase {
  final String version;
  final String lastUpdated;
  final int totalItems;
  final List<String> categoryList;
  final List<MarketingSkill> skills;

  const KnowledgeBase({
    required this.version,
    required this.lastUpdated,
    required this.totalItems,
    required this.categoryList,
    required this.skills,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      version: json['version'] as String,
      lastUpdated: json['last_updated'] as String,
      totalItems: json['total_items'] as int? ?? 0,
      categoryList: List<String>.from(json['categories'] as List? ?? []),
      skills: (json['skills'] as List)
          .map((e) => MarketingSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<KnowledgeBase> load() async {
    final jsonString =
        await rootBundle.loadString('assets/marketing_knowledge_base.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return KnowledgeBase.fromJson(jsonData);
  }

  List<String> get categories =>
      skills.map((s) => s.category).toSet().toList()..sort();

  List<String> get types =>
      skills.map((s) => s.type).toSet().toList()..sort();

  List<MarketingSkill> byCategory(String category) =>
      skills.where((s) => s.category == category).toList();

  List<MarketingSkill> byType(String type) =>
      skills.where((s) => s.type == type).toList();

  List<MarketingSkill> search(String query) {
    final q = query.toLowerCase();
    return skills
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q) ||
            s.type.toLowerCase().contains(q) ||
            s.fileName.toLowerCase().contains(q))
        .toList();
  }
}
DART_MODEL

# ─── 4단계: HomeScreen 업데이트 (타입 필터 추가) ───
echo "[4/8] HomeScreen 업데이트 중..."

cat > "$PROJECT_DIR/lib/screens/home_screen.dart" << 'DART_HOME'
import 'package:flutter/material.dart';
import '../models/marketing_skill.dart';
import 'skill_detail_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KnowledgeBase? _knowledgeBase;
  String? _selectedCategory;
  String? _selectedType;
  String _searchQuery = '';
  bool _isLoading = true;

  static const _categoryIcons = <String, IconData>{
    '콘텐츠 운영': Icons.edit_note,
    '전환 최적화': Icons.trending_up,
    '재무 운영': Icons.account_balance,
    '성장 엔진': Icons.rocket_launch,
    '아웃바운드 엔진': Icons.send,
    '팟캐스트 운영': Icons.podcasts,
    '매출 인텔리전스': Icons.insights,
    '세일즈 파이프라인': Icons.filter_alt,
    '세일즈 플레이북': Icons.menu_book,
    'SEO 운영': Icons.search,
    '팀 운영': Icons.groups,
    '보안': Icons.security,
    '텔레메트리': Icons.analytics,
  };

  static const _typeLabels = <String, String>{
    'skill_definition': '스킬 정의',
    'expert_persona': '전문가',
    'automation_script': '스크립트',
    'reference': '참고자료',
    'scoring_rubric': '루브릭',
    'documentation': '문서',
    'config_template': '설정',
    'config': '설정',
    'requirements': '의존성',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final kb = await KnowledgeBase.load();
      setState(() {
        _knowledgeBase = kb;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩 실패: $e')),
        );
      }
    }
  }

  List<MarketingSkill> get _filteredSkills {
    if (_knowledgeBase == null) return [];

    var skills = _knowledgeBase!.skills;

    if (_selectedCategory != null) {
      skills = skills.where((s) => s.category == _selectedCategory).toList();
    }

    if (_selectedType != null) {
      skills = skills.where((s) => s.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      skills = skills
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q) ||
              s.fileName.toLowerCase().contains(q))
          .toList();
    }

    return skills;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'skill_definition': return Colors.purple;
      case 'expert_persona': return Colors.blue;
      case 'automation_script': return Colors.green;
      case 'reference': return Colors.orange;
      case 'scoring_rubric': return Colors.red;
      case 'documentation': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _knowledgeBase?.categories ?? [];
    final types = _knowledgeBase?.types ?? [];
    final total = _knowledgeBase?.totalItems ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 24),
            const SizedBox(width: 8),
            const Text('MarketingFlow'),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text('$total'),
                backgroundColor: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '라이선스 및 정보',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 검색바
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SearchBar(
                    hintText: '마케팅 스킬 검색... ($total개 항목)',
                    leading: const Icon(Icons.search),
                    onChanged: (q) => setState(() => _searchQuery = q),
                    trailing: _searchQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            ),
                          ]
                        : null,
                  ),
                ),

                // 타입 필터
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('전체 타입'),
                          selected: _selectedType == null,
                          onSelected: (_) =>
                              setState(() => _selectedType = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ...types.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(_typeLabels[type] ?? type),
                              selected: _selectedType == type,
                              selectedColor: _typeColor(type).withValues(alpha: 0.2),
                              onSelected: (_) => setState(() =>
                                  _selectedType =
                                      _selectedType == type ? null : type),
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 카테고리 필터
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('전체'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Icon(
                                _categoryIcons[cat] ?? Icons.category,
                                size: 16,
                              ),
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == cat ? null : cat),
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                ),

                // 결과 카운트
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredSkills.length}개 결과',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (_selectedCategory != null || _selectedType != null) ...[
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('필터 초기화'),
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _selectedType = null;
                          }),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 스킬 목록
                Expanded(
                  child: _filteredSkills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('결과가 없습니다',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredSkills.length,
                          itemBuilder: (context, index) {
                            final skill = _filteredSkills[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _typeColor(skill.type).withValues(alpha: 0.15),
                                  child: Icon(
                                    _categoryIcons[skill.category] ?? Icons.category,
                                    color: _typeColor(skill.type),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  skill.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      skill.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _typeColor(skill.type).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            skill.typeLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _typeColor(skill.type),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            skill.originPath,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.outline,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 18),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SkillDetailScreen(skill: skill),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
DART_HOME

# ─── 5단계: 앱 로고 생성 (SVG → PNG 변환) ───
echo ""
echo "[5/8] 앱 로고 생성 중..."

mkdir -p "$ASSETS_DIR"

# Python으로 앱 아이콘 PNG 생성 (1024x1024)
python3 << 'LOGO_SCRIPT'
import struct
import zlib
import os

def create_png(width, height, pixels, filepath):
    """Raw RGBA pixels -> PNG 파일"""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack('>I', len(data)) + c + crc

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            idx = (y * width + x) * 4
            raw += bytes(pixels[idx:idx+4])

    idat = chunk(b'IDAT', zlib.compress(raw, 9))
    iend = chunk(b'IEND', b'')

    with open(filepath, 'wb') as f:
        f.write(header + ihdr + idat + iend)

def draw_logo(size):
    """MarketingFlow 로고 - 보라색 그라디언트 + M 레터 + 플로우 라인"""
    pixels = [0] * (size * size * 4)
    cx, cy = size // 2, size // 2
    r = size // 2

    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4
            dx = x - cx
            dy = y - cy
            dist = (dx*dx + dy*dy) ** 0.5

            # 둥근 사각형 배경 (radius = size * 0.22)
            corner_r = int(size * 0.22)
            margin = int(size * 0.02)
            in_rect = True

            # 모서리 체크
            if x < corner_r + margin and y < corner_r + margin:
                if ((x - corner_r - margin)**2 + (y - corner_r - margin)**2) > corner_r**2:
                    in_rect = False
            elif x > size - corner_r - margin - 1 and y < corner_r + margin:
                if ((x - (size - corner_r - margin - 1))**2 + (y - corner_r - margin)**2) > corner_r**2:
                    in_rect = False
            elif x < corner_r + margin and y > size - corner_r - margin - 1:
                if ((x - corner_r - margin)**2 + (y - (size - corner_r - margin - 1))**2) > corner_r**2:
                    in_rect = False
            elif x > size - corner_r - margin - 1 and y > size - corner_r - margin - 1:
                if ((x - (size - corner_r - margin - 1))**2 + (y - (size - corner_r - margin - 1))**2) > corner_r**2:
                    in_rect = False
            elif x < margin or x >= size - margin or y < margin or y >= size - margin:
                in_rect = False

            if not in_rect:
                pixels[idx:idx+4] = [0, 0, 0, 0]
                continue

            # 그라디언트 배경: 좌상→우하 (보라→인디고)
            t = (x + y) / (2 * size)
            bg_r = int(99 * (1-t) + 67 * t)    # #6366F1 → #4338CA
            bg_g = int(102 * (1-t) + 56 * t)
            bg_b = int(241 * (1-t) + 202 * t)

            # "M" 글자 그리기
            mx = (x - size * 0.18) / (size * 0.64)  # 0~1 normalized
            my = (y - size * 0.25) / (size * 0.50)   # 0~1 normalized

            is_letter = False
            line_w = 0.14

            if 0 <= mx <= 1 and 0 <= my <= 1:
                # M의 왼쪽 세로줄
                if mx < line_w:
                    is_letter = True
                # M의 오른쪽 세로줄
                elif mx > 1 - line_w:
                    is_letter = True
                # M의 왼쪽 대각선 (좌상→중앙하)
                elif my < 0.7:
                    target_x = line_w + my * (0.5 - line_w) / 0.7
                    if abs(mx - target_x) < line_w * 0.7:
                        is_letter = True
                    # M의 오른쪽 대각선 (우상→중앙하)
                    target_x2 = (1 - line_w) - my * (0.5 - line_w) / 0.7
                    if abs(mx - target_x2) < line_w * 0.7:
                        is_letter = True

            # 플로우 라인 (하단 곡선)
            flow_y_center = size * 0.82
            flow_amplitude = size * 0.04
            import math
            wave = flow_y_center + flow_amplitude * math.sin((x / size) * math.pi * 3)
            is_flow = abs(y - wave) < size * 0.018 and size * 0.15 < x < size * 0.85

            if is_letter:
                pixels[idx:idx+4] = [255, 255, 255, 255]
            elif is_flow:
                # 플로우 라인은 약간 투명한 흰색
                pixels[idx:idx+4] = [255, 255, 255, 200]
            else:
                pixels[idx:idx+4] = [bg_r, bg_g, bg_b, 255]

    return pixels

# 1024x1024 메인 로고
size = 192  # 192로 생성 (빠르게)
print("로고 생성 중... (%dx%d)" % (size, size))
pixels = draw_logo(size)

project = os.environ.get('PROJECT_DIR', '/Users/kimjaehyun/Desktop/marketing_flow')
assets = os.path.join(project, 'assets')
os.makedirs(assets, exist_ok=True)

create_png(size, size, pixels, os.path.join(assets, 'app_logo.png'))
print("app_logo.png 생성 완료")

# 작은 사이즈들도 생성
for s in [48, 96]:
    p = draw_logo(s)
    create_png(s, s, p, os.path.join(assets, 'app_logo_%d.png' % s))
    print("app_logo_%d.png 생성 완료" % s)

# Android 아이콘
android_res = os.path.join(project, 'android/app/src/main/res')
icon_sizes = {'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192}
for folder, sz in icon_sizes.items():
    p = draw_logo(sz)
    path = os.path.join(android_res, folder, 'ic_launcher.png')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    create_png(sz, sz, p, path)
print("Android 아이콘 생성 완료")

# Web 아이콘
web_dir = os.path.join(project, 'web/icons')
os.makedirs(web_dir, exist_ok=True)
for sz in [192, 192]:
    p = draw_logo(sz)
    create_png(sz, sz, p, os.path.join(web_dir, 'Icon-%d.png' % sz))
    create_png(sz, sz, p, os.path.join(web_dir, 'Icon-maskable-%d.png' % sz))

# 512 is too slow in pure python, use 192 as placeholder
p = draw_logo(192)
create_png(192, 192, p, os.path.join(web_dir, 'Icon-512.png'))
create_png(192, 192, p, os.path.join(web_dir, 'Icon-maskable-512.png'))
print("Web 아이콘 생성 완료")

LOGO_SCRIPT

# ─── 6단계: pubspec.yaml에 로고 에셋 추가 ───
echo ""
echo "[6/8] pubspec.yaml 업데이트 중..."

cat > "$PROJECT_DIR/pubspec.yaml" << 'PUBSPEC'
name: marketing_flow
description: "MarketingFlow - AI 기반 마케팅 자동화 플랫폼"
publish_to: 'none'
version: 2.0.0+2

environment:
  sdk: ^3.11.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.2.1
  flutter_markdown: ^0.7.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/marketing_knowledge_base.json
    - assets/app_logo.png
    - assets/app_logo_48.png
    - assets/app_logo_96.png
PUBSPEC

# ─── 7단계: README 작성 (영어 + 한글) ───
echo "[7/8] README 작성 중..."

cat > "$PROJECT_DIR/README.md" << 'README_EOF'
# MarketingFlow

**AI-Powered Marketing Automation Platform**

MarketingFlow transforms the [ai-marketing-skills](https://github.com/ericosiu/ai-marketing-skills) open-source knowledge base into an interactive Flutter application. It extracts marketing strategies, expert personas, automation scripts, and scoring rubrics — then lets you execute them with LLM-powered AI in real time.

## Features

- **Complete Knowledge Base**: 100+ marketing assets extracted from 13 categories
  - Skill Definitions (SKILL.md) — Core marketing workflows
  - Expert Personas — Specialized AI evaluator profiles
  - Automation Scripts — Python-based marketing automation
  - Scoring Rubrics — Content quality evaluation frameworks
  - Reference Materials — Templates, patterns, and guidelines
- **Dynamic Form Builder**: Automatically generates input forms from skill variables
- **AI Execution Engine**: Combines system prompts with user inputs via Anthropic Claude API
- **Markdown Viewer**: Rich rendering of AI-generated marketing strategies
- **License Compliance**: Full MIT license attribution to Eric Siu / Single Grain
- **Auto-Update Script**: Python extractor keeps the knowledge base in sync with upstream

## Categories

| Category | Description |
|----------|-------------|
| Content Ops | Expert panel content evaluation & repurposing |
| Conversion Ops | CRO audits, survey lead magnets |
| Finance Ops | CFO analyzer, scenario modeler, ROI analysis |
| Growth Engine | Experiment engine, weekly scorecard, pacing alerts |
| Outbound Engine | Cold outbound, competitive monitoring, lead pipeline |
| Podcast Ops | Full podcast pipeline management |
| Revenue Intelligence | Client reports, Gong insights, attribution |
| Sales Pipeline | Deal resurrector, ICP learning, trigger prospecting |
| Sales Playbook | Call analyzer, value pricing, pattern library |
| SEO Ops | Content attack briefs, GSC integration, trend scouting |
| Team Ops | Meeting action extraction, performance audits |
| Security | Pre-commit hooks, sanitizer |
| Telemetry | Logging, reporting, version tracking |

## Getting Started

### Prerequisites
- Flutter SDK 3.11+
- Dart 3.0+
- Anthropic API key (for AI execution)

### Installation

```bash
git clone https://github.com/kimdzhekhon/MarketingFlow.git
cd MarketingFlow
flutter pub get
flutter run
```

### Update Knowledge Base

When the upstream repository is updated:

```bash
python3 scripts/extract_knowledge.py /path/to/ai-marketing-skills assets/marketing_knowledge_base.json
```

## Architecture

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── marketing_skill.dart           # Data models & KnowledgeBase loader
├── screens/
│   ├── home_screen.dart               # Main screen with search & filters
│   ├── skill_detail_screen.dart       # Skill execution screen
│   ├── settings_screen.dart           # API key configuration
│   └── about_screen.dart              # License & attribution
├── services/
│   └── ai_response_service.dart       # Anthropic Claude API integration
└── widgets/
    ├── dynamic_form_builder.dart      # Auto-generated input forms
    └── markdown_viewer.dart           # Rich markdown rendering
```

## License

This project is licensed under the MIT License.

### Attribution

The marketing knowledge base is derived from **[ai-marketing-skills](https://github.com/ericosiu/ai-marketing-skills)** by **Eric Siu / Single Grain**, licensed under the MIT License.

```
MIT License
Copyright (c) 2026 Single Grain
```

See [About Screen](lib/screens/about_screen.dart) for full license text displayed in-app.

---

# MarketingFlow (한국어)

**AI 기반 마케팅 자동화 플랫폼**

MarketingFlow는 [ai-marketing-skills](https://github.com/ericosiu/ai-marketing-skills) 오픈소스 지식 베이스를 인터랙티브 Flutter 앱으로 변환합니다. 마케팅 전략, 전문가 페르소나, 자동화 스크립트, 평가 루브릭을 추출하고, LLM 기반 AI로 실시간 실행할 수 있습니다.

## 주요 기능

- **완전한 지식 베이스**: 13개 카테고리에서 100개 이상의 마케팅 자산 추출
  - 스킬 정의 (SKILL.md) — 핵심 마케팅 워크플로우
  - 전문가 페르소나 — 특화된 AI 평가자 프로필
  - 자동화 스크립트 — Python 기반 마케팅 자동화
  - 평가 루브릭 — 콘텐츠 품질 평가 프레임워크
  - 참고자료 — 템플릿, 패턴, 가이드라인
- **동적 폼 빌더**: 스킬 변수를 기반으로 입력 폼 자동 생성
- **AI 실행 엔진**: 시스템 프롬프트와 사용자 입력을 결합하여 Anthropic Claude API 호출
- **마크다운 뷰어**: AI 생성 마케팅 전략의 가독성 높은 렌더링
- **라이선스 준수**: Eric Siu / Single Grain에 대한 MIT 라이선스 전문 표시
- **자동 업데이트**: Python 추출 스크립트로 상위 리포 변경사항 동기화

## 카테고리

| 카테고리 | 설명 |
|----------|------|
| 콘텐츠 운영 | 전문가 패널 콘텐츠 평가 및 재활용 |
| 전환 최적화 | CRO 감사, 설문 리드 마그넷 |
| 재무 운영 | CFO 분석기, 시나리오 모델러, ROI 분석 |
| 성장 엔진 | 실험 엔진, 주간 스코어카드, 페이싱 알림 |
| 아웃바운드 엔진 | 콜드 아웃바운드, 경쟁 모니터링, 리드 파이프라인 |
| 팟캐스트 운영 | 팟캐스트 파이프라인 전체 관리 |
| 매출 인텔리전스 | 고객 리포트, Gong 인사이트, 어트리뷰션 |
| 세일즈 파이프라인 | 딜 부활, ICP 학습, 트리거 프로스펙팅 |
| 세일즈 플레이북 | 콜 분석기, 밸류 프라이싱, 패턴 라이브러리 |
| SEO 운영 | 콘텐츠 공격 브리프, GSC 연동, 트렌드 스카우팅 |
| 팀 운영 | 미팅 액션 추출, 팀 성과 감사 |
| 보안 | Pre-commit 훅, 새니타이저 |
| 텔레메트리 | 로깅, 리포팅, 버전 추적 |

## 시작하기

```bash
git clone https://github.com/kimdzhekhon/MarketingFlow.git
cd MarketingFlow
flutter pub get
flutter run
```

### 지식 베이스 업데이트

```bash
python3 scripts/extract_knowledge.py /path/to/ai-marketing-skills assets/marketing_knowledge_base.json
```

## 라이선스

MIT License — 원본 지식 베이스: **Eric Siu / Single Grain**
README_EOF

# ─── 8단계: Flutter 의존성 설치 ───
echo "[8/8] Flutter 의존성 설치 중..."
cd "$PROJECT_DIR"
flutter pub get 2>&1 | tail -5

# 임시 파일 정리
rm -rf "$TEMP_DIR"

echo ""
echo "========================================"
echo "  완전 추출 완료!"
echo "========================================"
echo ""
echo "추출 결과:"
TOTAL=$(python3 -c "import json; d=json.load(open('$ASSETS_DIR/marketing_knowledge_base.json')); print(d['total_items'])")
echo "  총 항목 수: $TOTAL 개"
echo "  JSON 크기: $(du -h "$ASSETS_DIR/marketing_knowledge_base.json" | cut -f1)"
echo ""
echo "생성된 로고:"
echo "  - assets/app_logo.png (192x192)"
echo "  - assets/app_logo_48.png"
echo "  - assets/app_logo_96.png"
echo "  - Android/Web 아이콘 업데이트됨"
echo ""
