import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../l10n/app_locale.dart';

class MarkdownViewer extends StatelessWidget {
  final String data;
  final String? title;
  final AppLocale locale;

  const MarkdownViewer({
    super.key,
    required this.data,
    this.title,
    required this.locale,
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
                Icon(Icons.description_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy_rounded,
                      size: 18, color: theme.colorScheme.outline),
                  tooltip: locale.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.copied),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: data,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium,
              h1: theme.textTheme.headlineSmall,
              h2: theme.textTheme.titleLarge,
              h3: theme.textTheme.titleMedium,
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
