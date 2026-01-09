import 'package:flutter/material.dart';

const _primary = Color(0xFF82265C);
const _orange = Color(0xFFF39C12);

class TransparenciaSection extends StatelessWidget {
  const TransparenciaSection({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['CERTIDÕES', 'CERTIFICADOS', 'ESTATUTO', 'REGULAMENTOS', 'CONTRATOS'];
    const imgs = [
      'assets/images/icon-certidoes.png',
      'assets/images/icon-certificados.png',
      'assets/images/icon-estatutos.png',
      'assets/images/icon-regulamentos.png',
      'assets/images/icon-contratos.png',
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Text(
                  'TRANSPARÊNCIA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 800;
                  final itemWidth = isNarrow ? (c.maxWidth - 16) / 2 : 200.0;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(imgs.length, (i) {
                      return SizedBox(
                        width: itemWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Material(
                            color: Colors.white,
                            elevation: 0,
                            child: InkWell(
                              onTap: () {}, // ligue com seus documentos
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))],
                                ),
                                child: Column(
                                  children: [
                                    // faixa laranja
                                    Container(
                                      height: 26,
                                      width: double.infinity,
                                      color: _orange,
                                      alignment: Alignment.center,
                                      child: Text(
                                        labels[i],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: const Color(0xFFF1EDF9),
                                      alignment: Alignment.center,
                                      child: Image.asset(imgs[i], height: 56, fit: BoxFit.contain),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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