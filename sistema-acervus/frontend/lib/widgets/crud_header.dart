import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
