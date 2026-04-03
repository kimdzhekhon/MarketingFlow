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
