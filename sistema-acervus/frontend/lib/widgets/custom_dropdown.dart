import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hintText;

  final bool isExpanded;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.isExpanded = true,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      selectedItemBuilder: selectedItemBuilder,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: AcervusColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AcervusColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AcervusColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AcervusColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AcervusColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
