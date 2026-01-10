import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';
import 'dashboard_card_header.dart';

class GraficoObrasPorTipo extends StatefulWidget {
  const GraficoObrasPorTipo({super.key});

  @override
  State<GraficoObrasPorTipo> createState() => _GraficoObrasPorTipoState();
}

class _GraficoObrasPorTipoState extends State<GraficoObrasPorTipo> {
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: DashboardService.obrasPorTipo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final dados = snapshot.data!;
        if (dados.isEmpty) {
          return const Center(child: Text('Sem dados'));
        }

        final total = dados.fold<double>(
          0,
          (s, e) => s + double.parse(e['total'].toString()),
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔹 HEADER PADRÃO
                const DashboardCardHeader(
                  titulo: 'Obras por Subtipo',
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ======================
                      // DONUT CENTRALIZADO
                      // ======================
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 55,
                                sectionsSpace: 2,
                                sections: List.generate(dados.length, (i) {
                                  final valor = double.parse(
                                    dados[i]['total'].toString(),
                                  );
                                  return PieChartSectionData(
                                    value: valor,
                                    title: '',
                                    radius: 72,
                                    color: _cores[i % _cores.length],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // ======================
                      // LEGENDA CENTRALIZADA
                      // ======================
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dados.length,
                            itemBuilder: (context, i) {
                              final valor = double.parse(
                                dados[i]['total'].toString(),
                              );
                              final percentual =
                                  total > 0 ? (valor / total) * 100 : 0;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _cores[i % _cores.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        dados[i]['tipo'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${percentual.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<Color> _cores = [
    Color(0xFF1F3B5B),
    Color(0xFF2E6FA3),
    Color(0xFF4A90E2),
    Color(0xFFF28C28),
    Color(0xFF9B9B9B),
  ];
}
