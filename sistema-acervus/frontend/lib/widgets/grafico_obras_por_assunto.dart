import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';

class GraficoObrasPorAssunto extends StatelessWidget {
  const GraficoObrasPorAssunto({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: DashboardService.obrasPorAssunto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar gráfico'));
        }

        final dados = snapshot.data ?? [];

        if (dados.isEmpty) {
          return const Center(child: Text('Sem dados'));
        }

        // 🔹 Ordena e limita (Top 10)
        dados.sort(
          (a, b) => int.parse(b['total'].toString())
              .compareTo(int.parse(a['total'].toString())),
        );
        final topDados = dados.take(10).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =========================
                // HEADER PADRÃO PREMIUM
                // =========================
                Row(
                  children: const [
                    Text(
                      'Obras por Assunto (Top 10)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =========================
                // GRÁFICO (CENTRALIZADO)
                // =========================
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calcularMaxY(topDados),

                      // 🚫 sem hover (anti-flicker / web-safe)
                      barTouchData: BarTouchData(enabled: false),

                      // 🧱 GRID SUAVE
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcularIntervalo(topDados),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),

                      borderData: FlBorderData(show: false),

                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        // 🔹 Eixo Y
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: _calcularIntervalo(topDados),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),

                        // 🔹 Eixo X (Assuntos)
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 56,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= topDados.length) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 64,
                                  child: Text(
                                    topDados[index]['assunto'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 🔹 BARRAS
                      barGroups: List.generate(topDados.length, (i) {
                        final valor = double.parse(
                          topDados[i]['total'].toString(),
                        );

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: valor,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: _cores[i % _cores.length],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // 🔧 CÁLCULOS AUXILIARES
  // =========================
  static double _calcularMaxY(List<dynamic> dados) {
    final max = dados
        .map((e) => double.parse(e['total'].toString()))
        .reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }

  static double _calcularIntervalo(List<dynamic> dados) {
    final max = dados
        .map((e) => double.parse(e['total'].toString()))
        .reduce((a, b) => a > b ? a : b);
    return (max / 5).ceilToDouble();
  }

  // 🎨 Paleta institucional Acervus
  static const List<Color> _cores = [
    Color(0xFF1F3B5B), // azul escuro
    Color(0xFF2E6FA3), // azul médio
    Color(0xFF4A90E2), // azul claro
    Color(0xFFF28C28), // laranja destaque
    Color(0xFF9B9B9B), // cinza
  ];
}
