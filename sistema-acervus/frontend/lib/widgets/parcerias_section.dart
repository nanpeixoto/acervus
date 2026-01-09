import 'package:flutter/material.dart';

const _primary = Color(0xFF82265C);
const _orange = Color(0xFFF39C12);

class ParceriasSection extends StatelessWidget {
  const ParceriasSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Destaque parceria
              LayoutBuilder(
                builder: (context, c) {
                  final isMobile = c.maxWidth < 900;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: isMobile
                        ? Column(
                            children: [
                              _LeftPanel(),
                              _RightImage(),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _LeftPanel()),
                              SizedBox(width: 320, child: _RightImage()),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Título PARCEIROS
              Container(
                height: 28,
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Text(
                  'PARCEIROS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4),
                ),
              ),
              const SizedBox(height: 10),

              // Logos
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  _logo('assets/images/logo-GDF.png'),
                  _logo('assets/images/logo-sudesb.png'),
                  _logo('assets/images/logo-coruripe.png'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _LeftPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PARCERIA CIDE',
              style: TextStyle(color: _orange, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
            'PREFEITURA DE CORURIPE/AL',
            style: TextStyle(
                color: _primary, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'O CIDE — Capacitação, Inserção e Desenvolvimento atua com a Prefeitura Minicipal de Coruripe/AL na execução do Programa de Eficientização da Gestão Patrimonial, com foco em serviços de zeladoria, conservação urbana e apoio à gestão dos bens públicos.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  static Widget _RightImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Image.asset('assets/images/parceriacoruripe.png',
          height: 200, fit: BoxFit.cover),
    );
  }

  Widget _logo(String asset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDF9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(asset, height: 40, fit: BoxFit.contain),
    );
  }
}
