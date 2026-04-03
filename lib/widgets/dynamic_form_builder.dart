import 'package:flutter/material.dart';
import '../l10n/app_locale.dart';

class DynamicFormBuilder extends StatefulWidget {
  final List<String> variables;
  final void Function(Map<String, String> values) onSubmit;
  final bool isLoading;
  final AppLocale locale;

  const DynamicFormBuilder({
    super.key,
    required this.variables,
    required this.onSubmit,
    this.isLoading = false,
    required this.locale,
  });

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  AppLocale get l => widget.locale;

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.variables.map((variable) {
            final label = l.variableLabel(variable);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: _controllers[variable],
                decoration: InputDecoration(
                  labelText: label,
                  hintText: l.variableHint(variable),
                ),
                maxLines: variable.toLowerCase().contains('data') ? 3 : 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.inputRequired(label);
                  }
                  return null;
                },
              ),
            );
          }),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: widget.isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit({
                        for (final e in _controllers.entries)
                          e.key: e.value.text.trim(),
                      });
                    }
                  },
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow_rounded),
            label: Text(widget.isLoading ? l.executing : l.execute),
          ),
        ],
      ),
    );
  }
}
