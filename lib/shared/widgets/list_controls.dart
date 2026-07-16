import 'package:flutter/material.dart';

import '../../widgets/shared_widgets.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: AppInput.field(context, hint, icon: Icons.search),
    );
  }
}

class AppFilterChips extends StatelessWidget {
  final List<AppFilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final active = selected == option.value;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(option.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppFilterOption {
  final String value;
  final String label;

  const AppFilterOption(this.value, this.label);
}
