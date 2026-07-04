import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';

/// Stat tile do dashboard: card branco com chip de ícone colorido,
/// valor em destaque e rótulo secundário (padrão "Telas Acervus").
class DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final double? width;

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 180,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 20, color: cor),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AcervusColors.textPrimary,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: AcervusColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
