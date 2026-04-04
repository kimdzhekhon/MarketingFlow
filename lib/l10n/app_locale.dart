class AppLocale {
  final String code;
  const AppLocale._(this.code);

  static const ko = AppLocale._('ko');
  static const en = AppLocale._('en');

  bool get isKo => code == 'ko';
  bool get isEn => code == 'en';

  // ── App ──
  String get appTitle => isKo ? 'MarketingFlow' : 'MarketingFlow';
  String get appSubtitle =>
      isKo ? '마케팅 전략 실행 플랫폼' : 'Marketing Strategy Platform';
  String get appDescription => isKo
      ? '전문가의 마케팅 지식을 실행 가능한 전략으로 변환합니다.'
      : 'Transform expert marketing knowledge into actionable strategies.';

  // ── Home ──
  String get searchHint => isKo ? '전략 검색...' : 'Search strategies...';
  String itemCount(int n) => isKo ? '$n개 항목' : '$n items';
  String resultCount(int n) => isKo ? '$n개 결과' : '$n results';
  String get allTypes => isKo ? '전체 타입' : 'All Types';
  String get allCategories => isKo ? '전체' : 'All';
  String get noResults => isKo ? '결과가 없습니다' : 'No results found';
  String get resetFilters => isKo ? '필터 초기화' : 'Reset Filters';

  // ── Type labels ──
  String typeLabel(String type) {
    if (isKo) {
      switch (type) {
        case 'skill_definition': return '전략 정의';
        case 'expert_persona': return '전문가';
        case 'automation_script': return '자동화';
        case 'reference': return '참고자료';
        case 'scoring_rubric': return '평가기준';
        case 'documentation': return '문서';
        case 'config_template': return '설정';
        case 'config': return '설정';
        case 'requirements': return '의존성';
        default: return type;
      }
    } else {
      switch (type) {
        case 'skill_definition': return 'Strategy';
        case 'expert_persona': return 'Expert';
        case 'automation_script': return 'Script';
        case 'reference': return 'Reference';
        case 'scoring_rubric': return 'Rubric';
        case 'documentation': return 'Docs';
        case 'config_template': return 'Config';
        case 'config': return 'Config';
        case 'requirements': return 'Deps';
        default: return type;
      }
    }
  }

  // ── Category labels ──
  String categoryLabel(String cat) {
    if (isEn) {
      switch (cat) {
        case '콘텐츠 운영': return 'Content Ops';
        case '전환 최적화': return 'Conversion';
        case '재무 운영': return 'Finance';
        case '성장 엔진': return 'Growth';
        case '아웃바운드 엔진': return 'Outbound';
        case '팟캐스트 운영': return 'Podcast';
        case '매출 인텔리전스': return 'Revenue Intel';
        case '세일즈 파이프라인': return 'Sales Pipeline';
        case '세일즈 플레이북': return 'Sales Playbook';
        case 'SEO 운영': return 'SEO';
        case '팀 운영': return 'Team Ops';
        default: return cat;
      }
    }
    return cat;
  }

  // ── Detail ──
  String get inputData => isKo ? '입력 데이터' : 'Input Data';
  String variableCount(int n) => isKo ? '변수 $n개' : '$n variables';
  String get source => isKo ? '출처' : 'Source';
  String get execute => isKo ? '실행' : 'Execute';
  String get executing => isKo ? '분석 중...' : 'Analyzing...';
  String get analysisResult => isKo ? '분석 결과' : 'Analysis Result';

  // ── Settings ──
  String get settings => isKo ? '설정' : 'Settings';
  String get apiKeyTitle => 'Anthropic API Key';
  String get save => isKo ? '저장' : 'Save';
  String get language => isKo ? '언어 / Language' : 'Language';
  String get korean => '한국어';
  String get english => 'English';
  String get appearance => isKo ? '외관' : 'Appearance';
  String get apiConfig => isKo ? 'API 설정' : 'API Configuration';

  // ── About ──
  String get aboutTitle => isKo ? '정보 및 라이선스' : 'About & License';
  String get attribution => isKo ? '원저작자 고지' : 'Attribution';
  String get attributionBody => isKo
      ? '본 앱의 마케팅 지식 베이스는 Eric Siu와 Single Grain이 개발한 AI Marketing Skills 오픈소스 프로젝트를 기반으로 합니다.'
      : 'The marketing knowledge base in this app is based on the AI Marketing Skills open-source project developed by Eric Siu and Single Grain.';
  String get mitLicense => 'MIT License';
  String get dataTransparency => isKo ? '데이터 투명성' : 'Data Transparency';
  String get dataTransparencyBody => isKo
      ? '각 마케팅 전략에는 원본 파일 경로(origin_path)가 포함되어 있어 데이터의 출처를 투명하게 확인할 수 있습니다. 모든 데이터는 MIT 라이선스 하에 자유롭게 사용, 수정, 배포가 가능합니다.'
      : 'Each marketing strategy includes the original file path (origin_path) for full transparency. All data is freely available under the MIT License.';

  // ── Widgets ──
  String get copied => isKo ? '클립보드에 복사되었습니다' : 'Copied to clipboard';
  String get copy => isKo ? '복사' : 'Copy';
  String inputRequired(String field) =>
      isKo ? '$field을(를) 입력해주세요' : 'Please enter $field';

  // ── Variable labels ──
  String variableLabel(String variable) {
    if (isEn) return variable.replaceAll('_', ' ').replaceAll('-', ' ');
    const map = <String, String>{
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
    return map[variable.toLowerCase()] ??
        variable.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String? variableHint(String variable) {
    if (isEn) {
      const map = <String, String>{
        'topic': 'e.g. Marketing automation trends',
        'target_audience': 'e.g. B2B SaaS marketing managers',
        'goal': 'e.g. Increase leads by 30%',
        'keyword': 'e.g. marketing automation tools',
        'industry': 'e.g. SaaS / E-commerce',
        'budget': 'e.g. \$5,000/month',
        'product': 'e.g. Marketing analytics platform',
      };
      return map[variable.toLowerCase()];
    }
    const map = <String, String>{
      'topic': '예: 마케팅 자동화 트렌드',
      'target_audience': '예: B2B SaaS 마케팅 매니저',
      'goal': '예: 리드 생성 30% 증가',
      'keyword': '예: marketing automation tools',
      'industry': '예: SaaS / 이커머스',
      'budget': '예: 월 500만원',
      'product': '예: 마케팅 분석 플랫폼',
    };
    return map[variable.toLowerCase()];
  }
}
