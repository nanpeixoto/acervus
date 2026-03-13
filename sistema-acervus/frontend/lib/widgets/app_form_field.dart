import 'package:flutter/material.dart';

class AppFormField extends StatelessWidget {
  final Widget child;
  final String label;

  const AppFormField({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 42, // 👈 ALTURA PADRÃO ERP
          child: child,
        ),
      ],
    );
  }
}
