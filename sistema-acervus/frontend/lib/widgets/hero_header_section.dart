import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// Paleta do site
const Color _primaryColor = Color(0xFF82265C);
const Color _accentColor = Color.fromARGB(255, 163, 73, 126);
const Color _goldColor = Color(0xFFF39C12);

class HeroHeaderSection extends StatelessWidget {
  const HeroHeaderSection({
    super.key,
    this.onVagas,
    this.onProcessos,
    this.onTransparencia,
    this.onParcerias,
    this.onQuemSomos,
  });

  final VoidCallback? onVagas;
  final VoidCallback? onProcessos;
  final VoidCallback? onTransparencia;
  final VoidCallback? onParcerias;
  final VoidCallback? onQuemSomos;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1100;

    // Altura fixa do hero por breakpoint (igual ao layout)
    final double heroHeight = isWide ? 640.0 : 520.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/hero-bg.png'),
          fit: BoxFit.cover,
        ),
      ), constraints: BoxConstraints(
        minHeight: heroHeight,
        maxHeight: heroHeight,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SizedBox(
              height: heroHeight, // controla a área do hero
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Moldura dourada
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: _goldColor, width: 2),
                        ),
                      ),
                    ),
                  ),

                  // Overlay (menu)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B0F22).withOpacity(0.45),
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final isMobile = c.maxWidth < 900;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isMobile ? 1 : 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset('assets/images/logo-cide.png', height: 50, fit: BoxFit.contain),
                                  const SizedBox(height: 18),
                                  _MenuItem(text: 'VAGAS', onTap: onVagas),
                                  const SizedBox(height: 12),
                                  _MenuItem(text: 'PROCESSOS SELETIVOS', onTap: onProcessos),
                                  const SizedBox(height: 12),
                                  _MenuItem(text: 'TRANSPARÊNCIA', onTap: onTransparencia),
                                  const SizedBox(height: 12),
                                  _MenuItem(
                                    text: 'EDITAIS / TRF3 / JFSP',
                                    onTap: () => launchUrl(
                                      Uri.parse('https://ciderh.org.br/documentos/Proc_Sel_Andamento.html'),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _MenuItem(text: 'PARCERIAS', onTap: onParcerias),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    width: 110,
                                    child: ElevatedButton(
                                      onPressed: () => GoRouter.of(context).go('/login'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _goldColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [                                      
                                      _social('assets/images/icon-instagram.png', 'https://www.instagram.com/ciderh'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile) const Spacer(flex: 3),
                          ],
                        );
                      },
                    ),
                  ),

                  // Garota em primeiro plano (escala pela ALTURA -> não corta)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Padding(
                        // pequena folga para não encostar na moldura inferior
                        padding: const EdgeInsets.only(right: 16, bottom: 8),
                        child: Image.asset(
                          'assets/images/hero-image_dt.png',
                          height: heroHeight - 24, // cabe inteira dentro da moldura
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _social(String asset, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.4),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(7),
        child: Image.asset(asset, color: Colors.white),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white10,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Roboto Condensed',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}