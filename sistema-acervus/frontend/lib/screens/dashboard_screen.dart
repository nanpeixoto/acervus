import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sistema_estagio/services/dashboard_service.dart';
import 'package:sistema_estagio/utils/app_colors.dart';
import 'package:sistema_estagio/widgets/dashboard_card.dart';
import 'package:sistema_estagio/services/storage_service.dart';
import 'package:sistema_estagio/widgets/grafico_obras_por_assunto.dart';
import 'package:sistema_estagio/widgets/grafico_obras_por_tipo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===============================
      // 🔹 APP BAR
      // ===============================
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1F3B5B),
                Color(0xFF2E6FA3),
              ],
            ),
          ),
        ),
        title: const Text(
          'Dashboard do Acervo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      // ===============================
      // 🔹 BODY
      // ===============================
      body: FutureBuilder<Map<String, dynamic>>(
        future: DashboardService.buscarTotais(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          final totais = data['totais'] ?? {};
          final List obrasPorAssuntoCarousel =
              data['obrasPorAssuntoCarousel'] ?? [];

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // ===============================
                // 🔹 CARDS DE TOTAIS
                // ===============================
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    DashboardCard(
                      titulo: 'Obras',
                      valor: totais['obras'].toString(),
                      icone: Icons.book_outlined,
                      cor: AppColors.cardBlue,
                    ),
                    DashboardCard(
                      titulo: 'Assuntos',
                      valor: totais['assuntos'].toString(),
                      icone: Icons.label_outline,
                      cor: AppColors.cardGreen,
                    ),
                    DashboardCard(
                      titulo: 'Autores',
                      valor: totais['autores'].toString(),
                      icone: Icons.person_outline,
                      cor: AppColors.cardPurple,
                    ),
                    DashboardCard(
                      titulo: 'Salas',
                      valor: totais['salas'].toString(),
                      icone: Icons.meeting_room_outlined,
                      cor: AppColors.cardGray,
                    ),
                    DashboardCard(
                      titulo: 'Estantes',
                      valor: totais['estantes'].toString(),
                      icone: Icons.inventory_2_outlined,
                      cor: AppColors.cardBlue,
                    ),
                    DashboardCard(
                      titulo: 'Tipos',
                      valor: totais['tipos'].toString(),
                      icone: Icons.category_outlined,
                      cor: AppColors.cardGreen,
                    ),
                    DashboardCard(
                      titulo: 'Subtipos',
                      valor: totais['subtipos'].toString(),
                      icone: Icons.layers_outlined,
                      cor: AppColors.cardPurple,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ===============================
                // 📊 GRÁFICOS
                // ===============================
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    const double altura = 360;

                    if (isMobile) {
                      return Column(
                        children: const [
                          SizedBox(
                            height: altura,
                            child: GraficoObrasPorAssunto(),
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            height: altura,
                            child: GraficoObrasPorTipo(),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: const [
                        Expanded(
                          child: SizedBox(
                            height: altura,
                            child: GraficoObrasPorAssunto(),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: SizedBox(
                            height: altura,
                            child: GraficoObrasPorTipo(),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ===============================
                // 🎬 CARROSSEIS ESTILO NETFLIX
                // ===============================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: obrasPorAssuntoCarousel.map<Widget>((grupo) {
                    final String assunto = grupo['assunto'];
                    final List obras = grupo['obras'] ?? [];

                    if (obras.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 TÍTULO DO ASSUNTO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                assunto,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: navegar filtrando por assunto
                                },
                                child: const Text('Ver todas'),
                              ),
                            ],
                          ),

                          // 🎬 CARROSSEL
                          CarouselComSetas(
                            items: obras
                                .map<Widget>(
                                  (obra) => CardObraCarousel(obra: obra),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

//
// ==========================================================
// 🎴 CARD DA OBRA
// ==========================================================
class CardObraCarousel extends StatelessWidget {
  final Map<String, dynamic> obra;

  const CardObraCarousel({super.key, required this.obra});

  @override
  Widget build(BuildContext context) {
    final titulo = obra['titulo'] ?? 'Sem título';
    final capaUrl = obra['capa_url'];

    return SizedBox(
      width: 180,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: capaUrl != null
                  ? Image.network(
                      capaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEAEAEA),
      child: const Center(
        child: Icon(Icons.book_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}

//
// ==========================================================
// 🎬 CARROSSEL COM SETAS (NETFLIX STYLE)
// ==========================================================
class CarouselComSetas extends StatefulWidget {
  final List<Widget> items;
  final double itemWidth;
  final double height;

  const CarouselComSetas({
    super.key,
    required this.items,
    this.itemWidth = 180,
    this.height = 280,
  });

  @override
  State<CarouselComSetas> createState() => _CarouselComSetasState();
}

class _CarouselComSetasState extends State<CarouselComSetas> {
  final ScrollController _controller = ScrollController();
  bool _hover = false;

  void _scroll(double offset) {
    _controller.animateTo(
      _controller.offset + offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollAmount = widget.itemWidth * 4;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) => widget.items[i],
            ),
            if (_hover)
              Align(
                alignment: Alignment.centerLeft,
                child: _ArrowButton(
                  icon: Icons.chevron_left,
                  onTap: () => _scroll(-scrollAmount),
                ),
              ),
            if (_hover)
              Align(
                alignment: Alignment.centerRight,
                child: _ArrowButton(
                  icon: Icons.chevron_right,
                  onTap: () => _scroll(scrollAmount),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 88,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
