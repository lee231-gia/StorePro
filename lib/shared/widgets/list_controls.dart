import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
      decoration: AppInput.field(hint, icon: Icons.search),
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
                  color: active ? kRed : kCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? kRed : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : kGrey,
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
