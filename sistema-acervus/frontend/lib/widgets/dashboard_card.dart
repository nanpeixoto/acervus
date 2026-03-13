import 'package:flutter/material.dart';

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
        color: cor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 32),
          const Spacer(),
          Text(valor,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(titulo, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
