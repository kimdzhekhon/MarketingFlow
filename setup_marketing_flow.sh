#!/bin/bash
set -e

# ============================================================
# MarketingFlow - 원스톱 설정 스크립트
# 소스: https://github.com/ericosiu/ai-marketing-skills (MIT)
# 대상: https://github.com/kimdzhekhon/MarketingFlow.git
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="$PROJECT_DIR/.tmp_source"
ASSETS_DIR="$PROJECT_DIR/assets"
LIB_DIR="$PROJECT_DIR/lib"
SCRIPTS_DIR="$PROJECT_DIR/scripts"

echo "========================================"
echo "  MarketingFlow 설정 시작"
echo "========================================"

# ─── 1단계: 소스 리포지토리 클론 ───
echo ""
echo "[1/7] 소스 마케팅 리포지토리 클론 중..."
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/ericosiu/ai-marketing-skills.git "$TEMP_DIR" 2>/dev/null || {
  echo "⚠️  소스 리포 클론 실패. 샘플 데이터로 진행합니다."
  mkdir -p "$TEMP_DIR"
}

# ─── 2단계: assets 디렉토리 생성 ───
echo "[2/7] 디렉토리 구조 생성 중..."
mkdir -p "$ASSETS_DIR"
mkdir -p "$LIB_DIR/models"
mkdir -p "$LIB_DIR/services"
mkdir -p "$LIB_DIR/screens"
mkdir -p "$LIB_DIR/widgets"
mkdir -p "$SCRIPTS_DIR"

# ─── 3단계: Python 추출 스크립트 생성 및 실행 ───
echo "[3/7] Python 데이터 추출 스크립트 생성 및 실행 중..."

cat > "$SCRIPTS_DIR/extract_knowledge.py" << 'PYTHON_SCRIPT'
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
PYTHON_SCRIPT

chmod +x "$SCRIPTS_DIR/extract_knowledge.py"

# Python 스크립트 실행
python3 "$SCRIPTS_DIR/extract_knowledge.py" "$TEMP_DIR" "$ASSETS_DIR/marketing_knowledge_base.json"

# ─── 4단계: Flutter 모델 생성 ───
echo "[4/7] Flutter 소스 코드 생성 중..."

# --- Model ---
cat > "$LIB_DIR/models/marketing_skill.dart" << 'DART_MODEL'
import 'dart:convert';
import 'package:flutter/services.dart';

class MarketingSkill {
  final String id;
  final String category;
  final String title;
  final String description;
  final String systemPrompt;
  final List<String> variables;
  final String originPath;

  const MarketingSkill({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.variables,
    required this.originPath,
  });

  factory MarketingSkill.fromJson(Map<String, dynamic> json) {
    return MarketingSkill(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      systemPrompt: json['system_prompt'] as String,
      variables: List<String>.from(json['variables'] as List),
      originPath: json['origin_path'] as String,
    );
  }
}

class KnowledgeBase {
  final String version;
  final String lastUpdated;
  final List<MarketingSkill> skills;

  const KnowledgeBase({
    required this.version,
    required this.lastUpdated,
    required this.skills,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      version: json['version'] as String,
      lastUpdated: json['last_updated'] as String,
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

  List<MarketingSkill> byCategory(String category) =>
      skills.where((s) => s.category == category).toList();

  List<MarketingSkill> search(String query) {
    final q = query.toLowerCase();
    return skills
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();
  }
}
DART_MODEL

# --- AIResponseService ---
cat > "$LIB_DIR/services/ai_response_service.dart" << 'DART_AI_SERVICE'
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketing_skill.dart';

class AIResponseService {
  final String apiKey;
  final String baseUrl;
  final String model;

  AIResponseService({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1/messages',
    this.model = 'claude-sonnet-4-20250514',
  });

  /// system_prompt와 사용자 입력 변수를 결합하여 LLM API와 통신합니다.
  Future<String> execute({
    required MarketingSkill skill,
    required Map<String, String> userInputs,
  }) async {
    // 시스템 프롬프트의 변수를 사용자 입력으로 치환
    String prompt = skill.systemPrompt;
    userInputs.forEach((key, value) {
      prompt = prompt.replaceAll('{$key}', value);
      prompt = prompt.replaceAll('{{$key}}', value);
      prompt = prompt.replaceAll('[${key.toUpperCase()}]', value);
    });

    final userMessage =
        '다음 마케팅 전략을 실행해주세요.\n\n'
        '카테고리: ${skill.category}\n'
        '스킬: ${skill.title}\n\n'
        '입력 데이터:\n${userInputs.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': model,
          'max_tokens': 4096,
          'system': prompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List;
        return (content.first as Map<String, dynamic>)['text'] as String;
      } else {
        return '## 오류\n\nAPI 요청 실패 (${response.statusCode})\n\n'
            '```\n${response.body}\n```\n\n'
            'API 키를 설정 화면에서 확인해주세요.';
      }
    } catch (e) {
      return '## 연결 오류\n\n서버에 연결할 수 없습니다.\n\n`$e`';
    }
  }
}
DART_AI_SERVICE

# --- DynamicFormBuilder Widget ---
cat > "$LIB_DIR/widgets/dynamic_form_builder.dart" << 'DART_FORM'
import 'package:flutter/material.dart';

class DynamicFormBuilder extends StatefulWidget {
  final List<String> variables;
  final void Function(Map<String, String> values) onSubmit;
  final bool isLoading;

  const DynamicFormBuilder({
    super.key,
    required this.variables,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  static const _variableLabels = <String, String>{
    'topic': '주제',
    'target_audience': '대상 고객',
    'goal': '목표',
    'tone': '톤 & 매너',
    'keyword': '타겟 키워드',
    'industry': '산업/업종',
    'domain_authority': '도메인 권한 점수',
    'competitors': '경쟁사',
    'product': '제품/서비스',
    'metrics': '현재 지표',
    'growth_goal': '성장 목표',
    'budget': '예산',
    'timeline': '타임라인',
    'customer_data': '고객 데이터',
    'revenue_range': '매출 범위',
    'icp': 'ICP (이상적 고객 프로필)',
    'value_prop': '가치 제안',
    'pain_points': '페인 포인트',
    'social_proof': '소셜 프루프',
    'url': '랜딩 페이지 URL',
    'conversion_rate': '현재 전환율',
    'traffic': '트래픽 볼륨',
    'benchmark': '업계 벤치마크',
    'channels': '마케팅 채널',
    'revenue_data': '매출 데이터',
    'time_period': '분석 기간',
    'attribution_model': '어트리뷰션 모델',
    'channel_spend': '채널별 지출',
    'revenue_by_channel': '채널별 매출',
    'target_roas': '목표 ROAS',
    'theme': '주제/테마',
    'audience': '대상 청취자',
    'frequency': '발행 빈도',
    'guest_info': '게스트 정보',
    'team_size': '팀 규모',
    'kpis': 'KPI 목록',
    'sprint_data': '스프린트 데이터',
    'goals': '목표',
  };

  static const _variableHints = <String, String>{
    'topic': '예: AI 마케팅 자동화 트렌드',
    'target_audience': '예: B2B SaaS 마케팅 매니저',
    'goal': '예: 리드 생성 30% 증가',
    'keyword': '예: marketing automation tools',
    'industry': '예: SaaS / 이커머스',
    'budget': '예: 월 500만원',
    'product': '예: AI 기반 마케팅 분석 플랫폼',
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final v in widget.variables) v: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _getLabel(String variable) {
    return _variableLabels[variable.toLowerCase()] ??
        variable.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String? _getHint(String variable) {
    return _variableHints[variable.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.variables.map((variable) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _controllers[variable],
                decoration: InputDecoration(
                  labelText: _getLabel(variable),
                  hintText: _getHint(variable),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                maxLines: variable.toLowerCase().contains('data') ? 3 : 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${_getLabel(variable)}을(를) 입력해주세요';
                  }
                  return null;
                },
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      final values = {
                        for (final e in _controllers.entries)
                          e.key: e.value.text.trim(),
                      };
                      widget.onSubmit(values);
                    }
                  },
            icon: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(widget.isLoading ? 'AI 분석 중...' : 'AI 실행'),
          ),
        ],
      ),
    );
  }
}
DART_FORM

# --- MarkdownViewer Widget ---
cat > "$LIB_DIR/widgets/markdown_viewer.dart" << 'DART_MARKDOWN'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownViewer extends StatelessWidget {
  final String data;
  final String? title;

  const MarkdownViewer({
    super.key,
    required this.data,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: '복사',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: data,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium,
              h1: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h2: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h3: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              code: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              codeblockDecoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
DART_MARKDOWN

# --- HomeScreen ---
cat > "$LIB_DIR/screens/home_screen.dart" << 'DART_HOME'
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

    var skills = _selectedCategory != null
        ? _knowledgeBase!.byCategory(_selectedCategory!)
        : _knowledgeBase!.skills;

    if (_searchQuery.isNotEmpty) {
      skills = _knowledgeBase!.search(_searchQuery);
      if (_selectedCategory != null) {
        skills =
            skills.where((s) => s.category == _selectedCategory).toList();
      }
    }

    return skills;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _knowledgeBase?.categories ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketingFlow'),
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
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    hintText: '마케팅 스킬 검색...',
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

                // 카테고리 칩
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('전체'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(
                                _categoryIcons[cat] ?? Icons.category,
                                size: 18,
                              ),
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == cat ? null : cat),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

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
                              Text(
                                '결과가 없습니다',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSkills.length,
                          itemBuilder: (context, index) {
                            final skill = _filteredSkills[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(
                                    _categoryIcons[skill.category] ??
                                        Icons.category,
                                  ),
                                ),
                                title: Text(
                                  skill.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  skill.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SkillDetailScreen(
                                        skill: skill),
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

# --- SkillDetailScreen ---
cat > "$LIB_DIR/screens/skill_detail_screen.dart" << 'DART_DETAIL'
import 'package:flutter/material.dart';
import '../models/marketing_skill.dart';
import '../services/ai_response_service.dart';
import '../widgets/dynamic_form_builder.dart';
import '../widgets/markdown_viewer.dart';
import 'settings_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  final MarketingSkill skill;

  const SkillDetailScreen({super.key, required this.skill});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  String? _aiResponse;
  bool _isLoading = false;
  String? _apiKey;

  Future<void> _executeSkill(Map<String, String> inputs) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      final key = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      if (key == null || key.isEmpty) return;
      _apiKey = key;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    final service = AIResponseService(apiKey: _apiKey!);
    final response = await service.execute(
      skill: widget.skill,
      userInputs: inputs,
    );

    setState(() {
      _aiResponse = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skill = widget.skill;

    return Scaffold(
      appBar: AppBar(
        title: Text(skill.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final key = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (key != null) _apiKey = key;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 스킬 정보 헤더
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(label: Text(skill.category)),
                        const Spacer(),
                        Text(
                          '변수 ${skill.variables.length}개',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(skill.description,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '출처: ${skill.originPath}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 동적 입력 폼
            Text('입력 데이터',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DynamicFormBuilder(
              variables: skill.variables,
              isLoading: _isLoading,
              onSubmit: _executeSkill,
            ),

            const SizedBox(height: 24),

            // AI 응답
            if (_aiResponse != null)
              MarkdownViewer(
                data: _aiResponse!,
                title: 'AI 분석 결과',
              ),
          ],
        ),
      ),
    );
  }
}
DART_DETAIL

# --- SettingsScreen ---
cat > "$LIB_DIR/screens/settings_screen.dart" << 'DART_SETTINGS'
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Anthropic API Key',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
DART_SETTINGS

# --- AboutScreen (MIT 라이선스 준수) ---
cat > "$LIB_DIR/screens/about_screen.dart" << 'DART_ABOUT'
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _mitLicense = '''
MIT License

Copyright (c) 2026 Single Grain

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('정보 및 라이선스')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앱 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: theme.colorScheme.primary, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MarketingFlow',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                            Text('v1.0.0',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AI 기반 마케팅 자동화 플랫폼\n'
                      'LLM과 마케팅 전문가의 지식을 결합하여\n'
                      '실행 가능한 마케팅 전략을 생성합니다.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 원저작자 고지
            Text('원저작자 고지',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 8),
                        Text('Eric Siu / Single Grain',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '본 앱의 마케팅 지식 베이스는 Eric Siu와 Single Grain이 '
                      '개발한 AI Marketing Skills 오픈소스 프로젝트를 기반으로 합니다.',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'https://github.com/ericosiu/ai-marketing-skills',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // MIT 라이선스 전문
            Text('MIT 라이선스',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _mitLicense,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 데이터 투명성
            Text('데이터 투명성',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '각 마케팅 스킬에는 원본 파일 경로(origin_path)가 포함되어 있어 '
                  '데이터의 출처를 투명하게 확인할 수 있습니다. '
                  '모든 데이터는 MIT 라이선스 하에 자유롭게 사용, 수정, 배포가 가능합니다.',
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
DART_ABOUT

# --- main.dart 업데이트 ---
cat > "$LIB_DIR/main.dart" << 'DART_MAIN'
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MarketingFlowApp());
}

class MarketingFlowApp extends StatelessWidget {
  const MarketingFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketingFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
DART_MAIN

# ─── 5단계: pubspec.yaml 업데이트 ───
echo "[5/7] pubspec.yaml 업데이트 중..."

cat > "$PROJECT_DIR/pubspec.yaml" << 'PUBSPEC'
name: marketing_flow
description: "MarketingFlow - AI 기반 마케팅 자동화 플랫폼"
publish_to: 'none'
version: 1.0.0+1

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
PUBSPEC

# ─── 6단계: Git 초기화 및 GitHub 연결 ───
echo "[6/7] Git 초기화 및 GitHub 연결 중..."

cd "$PROJECT_DIR"

# .gitignore에 임시 디렉토리 추가
if ! grep -q ".tmp_source" .gitignore 2>/dev/null; then
  echo "" >> .gitignore
  echo "# Temp source repo" >> .gitignore
  echo ".tmp_source/" >> .gitignore
fi

# Git 초기화 (이미 있으면 스킵)
if [ ! -d ".git" ]; then
  git init
fi

# 리모트 설정
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/kimdzhekhon/MarketingFlow.git

# ─── 7단계: 의존성 설치 ───
echo "[7/7] Flutter 의존성 설치 중..."
flutter pub get 2>/dev/null || echo "⚠️  flutter pub get 실패 - 나중에 수동 실행 필요"

# 임시 디렉토리 정리
rm -rf "$TEMP_DIR"

echo ""
echo "========================================"
echo "  설정 완료!"
echo "========================================"
echo ""
echo "생성된 파일:"
echo "  - assets/marketing_knowledge_base.json (마케팅 지식 베이스)"
echo "  - lib/models/marketing_skill.dart (데이터 모델)"
echo "  - lib/services/ai_response_service.dart (AI 서비스)"
echo "  - lib/widgets/dynamic_form_builder.dart (동적 폼 빌더)"
echo "  - lib/widgets/markdown_viewer.dart (마크다운 뷰어)"
echo "  - lib/screens/home_screen.dart (홈 화면)"
echo "  - lib/screens/skill_detail_screen.dart (스킬 상세)"
echo "  - lib/screens/about_screen.dart (라이선스/정보)"
echo "  - lib/screens/settings_screen.dart (API 설정)"
echo "  - scripts/extract_knowledge.py (데이터 추출 스크립트)"
echo ""
echo "다음 명령어로 커밋 & 푸시:"
echo "  cd $PROJECT_DIR"
echo "  git add -A"
echo "  git commit -m 'feat: MarketingFlow 초기 구현'"
echo "  git branch -M main"
echo "  git push -u origin main"
echo ""
echo "앱 실행:"
echo "  flutter run"
echo ""
echo "JSON 업데이트 (소스 리포 변경 시):"
echo "  python3 scripts/extract_knowledge.py /path/to/ai-marketing-skills assets/marketing_knowledge_base.json"
