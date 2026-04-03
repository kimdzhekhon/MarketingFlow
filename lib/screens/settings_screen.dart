import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/app_locale.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiController;

  AppLocale get l => widget.appState.locale;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: widget.appState.apiKey ?? '');
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language ──
          Text(l.language,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _langTile(
                  context,
                  title: '한국어',
                  subtitle: 'Korean',
                  selected: l.isKo,
                  onTap: () {
                    widget.appState.setLocale(AppLocale.ko);
                    setState(() {});
                  },
                  isTop: true,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _langTile(
                  context,
                  title: 'English',
                  subtitle: '영어',
                  selected: l.isEn,
                  onTap: () {
                    widget.appState.setLocale(AppLocale.en);
                    setState(() {});
                  },
                  isTop: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── API Key ──
          Text(l.apiConfig,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.apiKeyTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    l.isKo
                        ? '마케팅 전략 실행을 위해 Anthropic API 키를 입력하세요.'
                        : 'Enter your Anthropic API key to execute marketing strategies.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'sk-ant-...',
                      prefixIcon: Icon(Icons.vpn_key_rounded,
                          size: 20, color: theme.colorScheme.outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      widget.appState.setApiKey(_apiController.text.trim());
                      Navigator.pop(context, _apiController.text.trim());
                    },
                    child: Text(l.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langTile(BuildContext context,
      {required String title,
      required String subtitle,
      required bool selected,
      required VoidCallback onTap,
      required bool isTop}) {
    final theme = Theme.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(12))
            : const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: onTap,
    );
  }
}
