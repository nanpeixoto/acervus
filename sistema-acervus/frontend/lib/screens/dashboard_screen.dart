import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/services/dashboard_service.dart';
import 'package:sistema_estagio/theme/acervus_colors.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/dashboard_card.dart';
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
      backgroundColor: AcervusColors.background,

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
              padding: const EdgeInsets.all(24),
              children: [
                // ===============================
                // 🔹 CABEÇALHO DA PÁGINA
                // ===============================
                const Text(
                  'Dashboard do Acervo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AcervusColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visão geral do seu acervo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AcervusColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // ===============================
                // 🔹 CARDS DE TOTAIS
                // ===============================
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 500;
                    final cardWidth = isMobile
                        ? (constraints.maxWidth - 16) / 2
                        : 180.0;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        DashboardCard(
                          titulo: 'Obras',
                          valor: totais['obras'].toString(),
                          icone: Icons.book_outlined,
                          cor: AcervusColors.primary,
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Assuntos',
                          valor: totais['assuntos'].toString(),
                          icone: Icons.label_outline,
                          cor: AcervusColors.success,
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Autores',
                          valor: totais['autores'].toString(),
                          icone: Icons.person_outline,
                          cor: AcervusColors.purple,
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Salas',
                          valor: totais['salas'].toString(),
                          icone: Icons.meeting_room_outlined,
                          cor: AcervusColors.warning,
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Estantes',
                          valor: totais['estantes'].toString(),
                          icone: Icons.inventory_2_outlined,
                          cor: const Color(0xFF3B82F6),
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Tipos',
                          valor: totais['tipos'].toString(),
                          icone: Icons.category_outlined,
                          cor: AcervusColors.danger,
                          width: cardWidth,
                        ),
                        DashboardCard(
                          titulo: 'Subtipos',
                          valor: totais['subtipos'].toString(),
                          icone: Icons.layers_outlined,
                          cor: const Color(0xFF14B8A6),
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
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
class CardObraCarousel extends StatefulWidget {
  final Map<String, dynamic> obra;

  const CardObraCarousel({super.key, required this.obra});

  @override
  State<CardObraCarousel> createState() => _CardObraCarouselState();
}

class _CardObraCarouselState extends State<CardObraCarousel> {
  bool hover = false;

  @override
  @override
  Widget build(BuildContext context) {
    final titulo = widget.obra['titulo'] ?? 'Sem título';
    final int id = widget.obra['cd_obra'];

    final capaUrl = widget.obra['capa_url'] != null
        ? "${AppConfig.prodBaseUrl}/${widget.obra['capa_url']}"
        : null;

    return GestureDetector(
      onTap: () {
        context.go('/admin/obras/editar/$id');
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180,
          transform: hover
              ? (Matrix4.identity()
                ..translate(0, -6)
                ..scale(1.04))
              : Matrix4.identity(),
          child: Card(
            elevation: hover ? 10 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: capaUrl != null
                      ? Image.network(
                          capaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEAEAEA),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey),
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
