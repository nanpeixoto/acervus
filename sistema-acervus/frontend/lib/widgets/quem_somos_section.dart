import 'package:flutter/material.dart';

const _primary = Color(0xFF82265C);
const _orange = Color(0xFFF39C12);

class QuemSomosSection extends StatelessWidget {
  const QuemSomosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faixa roxa com título (como no HTML)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('QUEM SOMOS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final isMobile = c.maxWidth < 780;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isMobile ? 0 : 24, bottom: isMobile ? 16 : 0),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black87, fontSize: 16, height: 1.5),
                              children: [
                                TextSpan(text: 'O '),
                                TextSpan(
                                  text: 'CIDE - Capacitação, Inserção e Desenvolvimento',
                                  style: TextStyle(color: _orange, fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      ' é uma organização sem fins lucrativos que, desde 1998, atua na formação, qualificação e inclusão de estudantes e jovens no mercado de trabalho. Promovemos estágios, programas de aprendizagem e ações educativas voltadas ao desenvolvimento social e profissional. Reconhecido como de utilidade pública, o CIDE também está habilitado a prestar serviços e parcerias com órgãos públicos e privados em projetos de relevância social.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/quem-somos.png',
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
