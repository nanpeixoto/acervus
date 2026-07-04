import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';

class CrudFormContainer extends StatelessWidget {
  final Widget child;

  const CrudFormContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: child,
    );
  }
}
