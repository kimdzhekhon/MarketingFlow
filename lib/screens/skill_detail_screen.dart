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
