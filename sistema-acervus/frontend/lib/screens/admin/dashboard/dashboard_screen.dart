import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/widgets/dashboard_card.dart';
import 'package:sistema_estagio/utils/constants.dart';
import 'package:sistema_estagio/services/_core/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:sistema_estagio/utils/export_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool mostrarTodos = false;
  final ScrollController _scrollController = ScrollController();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> buscarDashboard({bool todos = false}) async {
    final url =
        todos ? '$dashboardAdmUrl?limit=0' : '$dashboardAdmUrl?limit=10';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar dashboard (${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrativo'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: buscarDashboard(todos: mostrarTodos),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final totalVagas = data['totalVagas'] ?? 0;
          final totalContratos = data['totalContratos'] ?? 0;
          final contratosAVencer =
              List<Map<String, dynamic>>.from(data['contratosAVencer'] ?? []);
          final totalEstudantes = data['totalEstudantes'] ?? 0;
          final totalAprendizes = data['totalAprendizes'] ?? 0;
          final totalEmpresas = data['totalEmpresas'] ?? 0;

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 10,
            radius: const Radius.circular(8),
            trackVisibility: true,
            interactive: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                // 🔹 Cards de resumo
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    DashboardCard(
                      titulo: 'Total de Vagas',
                      valor: totalVagas.toString(),
                      icone: Icons.work_outline,
                      cor: Colors.pink.shade100,
                    ),
                    DashboardCard(
                      titulo: 'Contratos de Estágio',
                      valor: totalContratos.toString(),
                      icone: Icons.description_outlined,
                      cor: Colors.green.shade100,
                    ),
                    DashboardCard(
                      titulo: 'Total de Estudantes',
                      valor: totalEstudantes.toString(),
                      icone: Icons.school_outlined,
                      cor: Colors.blue.shade100,
                    ),
                    DashboardCard(
                      titulo: 'Total de Aprendizes',
                      valor: totalAprendizes.toString(),
                      icone: Icons.engineering_outlined,
                      cor: Colors.orange.shade100,
                    ),
                    DashboardCard(
                      titulo: 'Total de Empresas',
                      valor: totalEmpresas.toString(),
                      icone: Icons.business_outlined,
                      cor: Colors.purple.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🔹 Lista de contratos
                _ListaContratosAVencer(
                  contratos: contratosAVencer,
                  onVerTodos: () {
                    setState(() {
                      mostrarTodos = !mostrarTodos;
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    });
                  },
                  mostrandoTodos: mostrarTodos,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================
// 🔹 LISTA CONTRATOS A VENCER
// =========================
class _ListaContratosAVencer extends StatelessWidget {
  final List<Map<String, dynamic>> contratos;
  final VoidCallback onVerTodos;
  final bool mostrandoTodos;

  const _ListaContratosAVencer({
    required this.contratos,
    required this.onVerTodos,
    required this.mostrandoTodos,
  });

  String formatarData(String dataIso) {
    if (dataIso.isEmpty) return '-';
    final data = DateTime.parse(dataIso);
    return DateFormat('dd/MM/yy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 Título
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blueGrey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Contratos vencidos ou com vencimento nos próximos 30 dias',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 👉 Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade200,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Contrato',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Empresa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Estagiário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Vencimento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Exportar',
                  onPressed: () async {
                    await ExportHelper.exportXlsxContratosVencidos(contratos);
                  },
                ),
              ],
            ),
          ),

          // 👉 Tabela rolável e selecionável
          if (contratos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhum contrato vencido ou a vencer nos próximos 30 dias.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            SizedBox(
              height: 410,
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                radius: const Radius.circular(6),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: contratos.map((contrato) {
                      final cdContrato =
                          contrato['cd_contrato']?.toString() ?? '-';
                      final empresa = contrato['empresa'] ?? '-';
                      final estagiario = contrato['estagiario'] ?? '-';
                      final vencimento = contrato['vencimento'] ?? '';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 2, child: SelectableText(cdContrato)),
                            Expanded(flex: 3, child: SelectableText(empresa)),
                            Expanded(
                                flex: 3, child: SelectableText(estagiario)),
                            Expanded(
                              flex: 2,
                              child: SelectableText(formatarData(vencimento)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // 👉 Rodapé
          if (contratos.isNotEmpty)
            GestureDetector(
              onTap: onVerTodos,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: Text(
                  mostrandoTodos ? 'Mostrar Menos' : 'Ver Todos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
