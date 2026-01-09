import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF5A1E42), // roxo escuro
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo-cide.png',
              height: 40, color: Colors.white),
          const SizedBox(height: 14),
          const Text(
            'AVENIDA TANCREDO NEVES, 1186 • CAMINHO DAS ÁRVORES • SALVADOR - BA',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              GestureDetector(
                onTap: () => _launchUrl('mailto:comercial@cideestagio.com.br'),
                child: const Text('comercial@cideestagio.com.br',
                    style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline)),
              ),
              const Text('•', style: TextStyle(color: Colors.white70)),
              GestureDetector(
                onTap: () => _launchUrl('mailto:apoiosgc@cideestagio.com.br'),
                child: const Text('apoiosgc@cideestagio.com.br',
                    style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [              
              Icon(FontAwesomeIcons.instagram, size: 16, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '© 2025 CIDE. Todos os direitos reservados.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
