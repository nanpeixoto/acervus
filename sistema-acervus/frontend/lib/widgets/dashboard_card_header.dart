import 'package:flutter/material.dart';

class DashboardCardHeader extends StatelessWidget {
  final String titulo;
  final Widget? action;

  const DashboardCardHeader({
    super.key,
    required this.titulo,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}
