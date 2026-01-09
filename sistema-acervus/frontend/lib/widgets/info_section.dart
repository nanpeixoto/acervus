import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Text(
            'Sobre o CIDE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: const [
              _InfoCard(
                icon: Icons.groups,
                title: 'Conectamos Pessoas',
                description: 'Ligamos estudantes às melhores oportunidades do mercado de trabalho.',
              ),
              _InfoCard(
                icon: Icons.trending_up,
                title: 'Desenvolvimento Profissional',
                description: 'Focamos no crescimento e capacitação dos jovens talentos.',
              ),
              _InfoCard(
                icon: Icons.handshake,
                title: 'Parcerias Sólidas',
                description: 'Construímos relacionamentos duradouros entre empresas e instituições.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF2E7D9A),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}