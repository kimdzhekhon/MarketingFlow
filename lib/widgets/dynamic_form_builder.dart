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
