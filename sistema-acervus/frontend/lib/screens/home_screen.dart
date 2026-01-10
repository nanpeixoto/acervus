import 'package:flutter/material.dart';
import 'package:sistema_estagio/widgets/top_nav_bar.dart';
import 'package:sistema_estagio/widgets/hero_header_section.dart';
import 'package:sistema_estagio/widgets/quem_somos_section.dart';

import 'package:sistema_estagio/widgets/transparencia_section.dart';
import 'package:sistema_estagio/widgets/parcerias_section.dart';
import 'package:sistema_estagio/widgets/footer_section.dart';

// Paleta do site
const Color _primaryColor = Color(0xFF82265C);
const Color _accentColor = Color.fromARGB(255, 163, 73, 126);
const Color _goldColor = Color(0xFFF39C12);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();

  // Âncoras das seções
  final _quemSomosKey = GlobalKey();
  final _vagasKey = GlobalKey();
  final _transparenciaKey = GlobalKey();
  final _parceriasKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TopNavBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                children: [
                  // Hero com imagem, moldura e menu vertical (replica o index.html)
                  HeroHeaderSection(
                    onVagas: () => _scrollTo(_vagasKey),
                    onProcessos: () => _scrollTo(_vagasKey),
                    onTransparencia: () => _scrollTo(_transparenciaKey),
                    onParcerias: () => _scrollTo(_parceriasKey),
                    onQuemSomos: () => _scrollTo(_quemSomosKey),
                  ),

                  // Seções (mantida a lógica/endpoints)
                  Container(
                      key: _quemSomosKey, child: const QuemSomosSection()),

                  Container(
                      key: _transparenciaKey,
                      child: const TransparenciaSection()),
                  Container(
                      key: _parceriasKey, child: const ParceriasSection()),
                  const FooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
