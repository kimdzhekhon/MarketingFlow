import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/app_locale.dart';
import '../models/marketing_skill.dart';
import '../services/ai_response_service.dart';
import '../theme.dart';
import '../widgets/dynamic_form_builder.dart';
import '../widgets/markdown_viewer.dart';
import 'settings_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  final MarketingSkill skill;
  final AppState appState;

  const SkillDetailScreen({super.key, required this.skill, required this.appState});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  String? _response;
  bool _isLoading = false;

  AppLocale get l => widget.appState.locale;

  Future<void> _execute(Map<String, String> inputs) async {
    final apiKey = widget.appState.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.isKo
                ? 'API 키를 설정해주세요'
                : 'Please set your API key in Settings'),
            action: SnackBarAction(
              label: l.settings,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(appState: widget.appState))),
            ),
          ),
        );
      }
      return;
    }

    setState(() { _isLoading = true; _response = null; });

    final service = AIResponseService(apiKey: apiKey);
    final result = await service.execute(skill: widget.skill, userInputs: inputs);

    setState(() { _response = result; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skill = widget.skill;
    final catColor = AppTheme.categoryColor(skill.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.isKo && skill.titleKo.isNotEmpty ? skill.titleKo : skill.title,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.categoryLabel(skill.category),
                              style: TextStyle(fontSize: 12, color: catColor, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(l.variableCount(skill.variables.length),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(skill.description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text('${l.source}: ${skill.originPath}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(l.inputData,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            DynamicFormBuilder(
              variables: skill.variables,
              isLoading: _isLoading,
              onSubmit: _execute,
              locale: l,
            ),

            const SizedBox(height: 24),

            if (_response != null)
              MarkdownViewer(data: _response!, title: l.analysisResult, locale: l),
          ],
        ),
      ),
    );
  }
}
