import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';

class CrudHeader extends StatelessWidget {
  final Widget stats;
  final Widget search;

  const CrudHeader({
    super.key,
    required this.stats,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Column(
        children: [
          stats,
          const SizedBox(height: 16),
          search,
        ],
      ),
    );
  }
}
