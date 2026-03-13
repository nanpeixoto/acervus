import 'package:flutter/material.dart';

class ObraDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const ObraDateField({
    super.key,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );

        if (date != null) {
          onPicked(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year}'
              : 'Selecionar',
        ),
      ),
    );
  }
}
