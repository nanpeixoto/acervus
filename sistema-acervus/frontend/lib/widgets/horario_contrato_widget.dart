// lib/widgets/horario_contrato_widget.dart - CORREÇÃO COMPLETA
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class HorarioContratoWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onHorarioChanged;
  final Map<String, dynamic>? horarioInicial;

  const HorarioContratoWidget({
    super.key,
    required this.onHorarioChanged,
    this.horarioInicial,
  });

  @override
  State<HorarioContratoWidget> createState() => _HorarioContratoWidgetState();
}

class _HorarioContratoWidgetState extends State<HorarioContratoWidget> {
  static const Color _primaryColor = Color(0xFF82265C);

  // Formatador para horários
  final _horarioFormatter = MaskTextInputFormatter(mask: '##:##');

  // Tipo de horário: 'sem_escala' ou 'com_escala'
  String _tipoHorario = 'sem_escala';

  // Para horário sem escala
  bool _possuiIntervalo = true;
  final _horarioInicioController = TextEditingController();
  final _horarioFimController = TextEditingController();
  final _horarioInicioIntervaloController = TextEditingController();
  final _horarioFimIntervaloController = TextEditingController();

  // Para horário com escala
  final Map<String, bool> _diasSelecionados = {
    'segunda': false,
    'terca': false,
    'quarta': false,
    'quinta': false,
    'sexta': false,
    'sabado': false,
    'domingo': false,
  };

  final Map<String, Map<String, TextEditingController>> _horariosEscala = {};
  final Map<String, bool> _possuiIntervaloEscala = {};

  // Labels dos dias
  final Map<String, String> _diasLabels = {
    'segunda': 'Segunda-feira',
    'terca': 'Terça-feira',
    'quarta': 'Quarta-feira',
    'quinta': 'Quinta-feira',
    'sexta': 'Sexta-feira',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };

  // ==========================================
  // MÉTODOS DE CONVERSÃO SEGURA
  // ==========================================

  /// Converte valor para boolean de forma segura
  bool _safeToBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'sim';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _carregarDadosIniciais();
  }

  void _inicializarControllers() {
    // Inicializar controllers para cada dia da semana
    for (String dia in _diasSelecionados.keys) {
      _horariosEscala[dia] = {
        'inicio': TextEditingController(),
        'fim': TextEditingController(),
        'inicio_intervalo': TextEditingController(),
        'fim_intervalo': TextEditingController(),
      };
      _possuiIntervaloEscala[dia] = true;
    }
  }

  void _carregarDadosIniciais() {
    if (widget.horarioInicial != null) {
      final dados = widget.horarioInicial!;

      _tipoHorario = dados['tipo_horario'] ?? 'sem_escala';

      if (_tipoHorario == 'sem_escala') {
        // ✅ CORREÇÃO: Usar conversão segura
        _possuiIntervalo =
            _safeToBool(dados['possui_intervalo'], defaultValue: true);
        _horarioInicioController.text = dados['horario_inicio'] ?? '';
        _horarioFimController.text = dados['horario_fim'] ?? '';
        _horarioInicioIntervaloController.text =
            dados['horario_inicio_intervalo'] ?? '';
        _horarioFimIntervaloController.text =
            dados['horario_fim_intervalo'] ?? '';
      } else {
        // Carregar dados da escala
        Map<String, dynamic>? escala = dados['escala'];
        if (escala != null) {
          escala.forEach((dia, dadosDia) {
            if (_diasSelecionados.containsKey(dia) && dadosDia is Map) {
              // ✅ CORREÇÃO: Usar conversão segura para valores booleanos
              _diasSelecionados[dia] = _safeToBool(dadosDia['ativo']);
              _possuiIntervaloEscala[dia] =
                  _safeToBool(dadosDia['possui_intervalo'], defaultValue: true);

              if (_horariosEscala.containsKey(dia)) {
                _horariosEscala[dia]!['inicio']!.text =
                    dadosDia['horario_inicio']?.toString() ?? '';
                _horariosEscala[dia]!['fim']!.text =
                    dadosDia['horario_fim']?.toString() ?? '';
                _horariosEscala[dia]!['inicio_intervalo']!.text =
                    dadosDia['horario_inicio_intervalo']?.toString() ?? '';
                _horariosEscala[dia]!['fim_intervalo']!.text =
                    dadosDia['horario_fim_intervalo']?.toString() ?? '';
              }
            }
          });
        }
      }
    }
  }

  void _notificarMudanca() {
    Map<String, dynamic> dadosHorario = {
      'tipo_horario': _tipoHorario,
    };

    if (_tipoHorario == 'sem_escala') {
      dadosHorario.addAll({
        'possui_intervalo': _possuiIntervalo,
        'horario_inicio': _horarioInicioController.text,
        'horario_fim': _horarioFimController.text,
        'horario_inicio_intervalo':
            _possuiIntervalo ? _horarioInicioIntervaloController.text : null,
        'horario_fim_intervalo':
            _possuiIntervalo ? _horarioFimIntervaloController.text : null,
        // MUDANÇA: Converter minutos para horas no retorno
        'total_horas_semana': (_calcularTotalHorasSemEscala() / 60).round(),
      });
    } else {
      Map<String, dynamic> escala = {};
      int totalMinutosSemana = 0;

      _diasSelecionados.forEach((dia, ativo) {
        if (ativo) {
          Map<String, dynamic> dadosDia = {
            'ativo': true,
            'possui_intervalo': _possuiIntervaloEscala[dia]!,
            'horario_inicio': _horariosEscala[dia]!['inicio']!.text,
            'horario_fim': _horariosEscala[dia]!['fim']!.text,
          };

          if (_possuiIntervaloEscala[dia]!) {
            dadosDia.addAll({
              'horario_inicio_intervalo':
                  _horariosEscala[dia]!['inicio_intervalo']!.text,
              'horario_fim_intervalo':
                  _horariosEscala[dia]!['fim_intervalo']!.text,
            });
          }

          escala[dia] = dadosDia;
          totalMinutosSemana += _calcularHorasDia(dia);
        }
      });

      dadosHorario.addAll({
        'escala': escala,
        // MUDANÇA: Converter minutos para horas no retorno
        'total_horas_semana': (totalMinutosSemana / 60).round(),
      });
    }

    print('📋 [HorarioWidget] Dados enviados: $dadosHorario');

    // Debug dos tipos
    if (_tipoHorario == 'com_escala' && dadosHorario['escala'] != null) {
      final escala = dadosHorario['escala'] as Map<String, dynamic>;
      escala.forEach((dia, dados) {
        if (dados is Map) {
          print(
              '🔍 $dia - ativo: ${dados['ativo']} (${dados['ativo'].runtimeType})');
          print(
              '🔍 $dia - possui_intervalo: ${dados['possui_intervalo']} (${dados['possui_intervalo'].runtimeType})');
        }
      });
    }

    widget.onHorarioChanged(dadosHorario);
  }

  int _calcularHorasEntre(String inicio, String fim, String? inicioIntervalo,
      String? fimIntervalo) {
    try {
      List<String> partesInicio = inicio.split(':');
      List<String> partesFim = fim.split(':');

      int minutosInicio =
          int.parse(partesInicio[0]) * 60 + int.parse(partesInicio[1]);
      int minutosFim = int.parse(partesFim[0]) * 60 + int.parse(partesFim[1]);

      int totalMinutos = minutosFim - minutosInicio;

      // Subtrair intervalo se houver
      if (inicioIntervalo != null &&
          fimIntervalo != null &&
          inicioIntervalo.isNotEmpty &&
          fimIntervalo.isNotEmpty) {
        List<String> partesInicioIntervalo = inicioIntervalo.split(':');
        List<String> partesFimIntervalo = fimIntervalo.split(':');

        int minutosInicioIntervalo = int.parse(partesInicioIntervalo[0]) * 60 +
            int.parse(partesInicioIntervalo[1]);
        int minutosFimIntervalo = int.parse(partesFimIntervalo[0]) * 60 +
            int.parse(partesFimIntervalo[1]);

        int minutosIntervalo = minutosFimIntervalo - minutosInicioIntervalo;
        totalMinutos -= minutosIntervalo;
      }

      // MUDANÇA: Retornar em formato decimal (horas + minutos)
      return totalMinutos; // Retorna total em minutos para cálculo preciso
    } catch (e) {
      return 0;
    }
  }

  // NOVO MÉTODO: Converter minutos para formato de horas decimais
  double _minutosParaHoras(int minutos) {
    return minutos / 60.0;
  }

  // NOVO MÉTODO: Formatar horas para exibição
  String _formatarHorasParaExibicao(int minutos) {
    int horas = minutos ~/ 60;
    int minutosRestantes = minutos % 60;
    
    if (minutosRestantes == 0) {
      return '${horas}:00';
    } else {
      return '$horas:${minutosRestantes.toString().padLeft(2, '0')}';
    }
  }

  int _calcularHorasDia(String dia) {
    if (!_diasSelecionados[dia]!) return 0;

    String inicio = _horariosEscala[dia]!['inicio']!.text;
    String fim = _horariosEscala[dia]!['fim']!.text;

    if (inicio.isEmpty || fim.isEmpty) return 0;

    try {
      return _calcularHorasEntre(
        inicio,
        fim,
        _possuiIntervaloEscala[dia]!
            ? _horariosEscala[dia]!['inicio_intervalo']!.text
            : null,
        _possuiIntervaloEscala[dia]!
            ? _horariosEscala[dia]!['fim_intervalo']!.text
            : null,
      );
    } catch (e) {
      return 0;
    }
  }

  int _calcularTotalHorasSemEscala() {
    if (_horarioInicioController.text.isEmpty ||
        _horarioFimController.text.isEmpty) {
      return 0;
    }

    try {
      int minutosDia = _calcularHorasEntre(
        _horarioInicioController.text,
        _horarioFimController.text,
        _possuiIntervalo ? _horarioInicioIntervaloController.text : null,
        _possuiIntervalo ? _horarioFimIntervaloController.text : null,
      );
      return minutosDia * 5; // Total de minutos por semana (5 dias úteis)
    } catch (e) {
      return 0;
    }
  }

  int _calcularTotalHorasEscala() {
    int totalMinutos = 0;
    _diasSelecionados.forEach((dia, ativo) {
      if (ativo) {
        totalMinutos += _calcularHorasDia(dia);
      }
    });
    return totalMinutos;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: _primaryColor),
                SizedBox(width: 8),
                Text(
                  'HORÁRIO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de horário
                const Text(
                  'TIPO DE HORÁRIO',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _tipoHorario,
                  items: const [
                    DropdownMenuItem(
                        value: 'sem_escala', child: Text('Sem Escala')),
                    DropdownMenuItem(
                        value: 'com_escala', child: Text('Com Escala')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoHorario = value!;
                    });
                    _notificarMudanca();
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                const SizedBox(height: 24),

                // Conteúdo baseado no tipo
                if (_tipoHorario == 'sem_escala') ...[
                  _buildHorarioSemEscala(),
                ] else ...[
                  _buildHorarioComEscala(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioSemEscala() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox para intervalo
        Row(
          children: [
            const Text('Possui intervalo?'),
            const SizedBox(width: 16),
            Radio<bool>(
              value: true,
              groupValue: _possuiIntervalo,
              onChanged: (value) {
                setState(() {
                  _possuiIntervalo = value!;
                });
                _notificarMudanca();
              },
            ),
            const Text('Sim'),
            Radio<bool>(
              value: false,
              groupValue: _possuiIntervalo,
              onChanged: (value) {
                setState(() {
                  _possuiIntervalo = value!;
                });
                _notificarMudanca();
              },
            ),
            const Text('Não'),
          ],
        ),

        const SizedBox(height: 16),

        // Campos de horário
        if (_possuiIntervalo) ...[
          // Com intervalo
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INÍCIO',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioInicioController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '08:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INÍCIO INTERVALO',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioInicioIntervaloController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '12:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FIM INTERVALO',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioFimIntervaloController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '13:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FIM',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioFimController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '18:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // Sem intervalo
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INÍCIO',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioInicioController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '08:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FIM',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _horarioFimController,
                      inputFormatters: [_horarioFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '18:00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _notificarMudanca(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Total de horas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                // MUDANÇA: Mostrar total formatado corretamente
                'TOTAL DE HORAS DA SEMANA: ${_formatarHorasParaExibicao(_calcularTotalHorasSemEscala())}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioComEscala() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione os dias da semana:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Lista dos dias da semana
        ..._diasSelecionados.keys.map((dia) {
          final isSelected = _diasSelecionados[dia]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? _primaryColor.withOpacity(0.05) : null,
            ),
            child: Column(
              children: [
                // Header do dia
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            _diasSelecionados[dia] = value!;
                            if (!value) {
                              // Limpar horários se desmarcado
                              _horariosEscala[dia]!.forEach((key, controller) {
                                controller.clear();
                              });
                            }
                          });
                          _notificarMudanca();
                        },
                      ),
                      Text(
                        _diasLabels[dia]!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Text('Possui intervalo?'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _possuiIntervaloEscala[dia]!,
                          onChanged: (value) {
                            setState(() {
                              _possuiIntervaloEscala[dia] = value;
                              if (!value) {
                                _horariosEscala[dia]!['inicio_intervalo']!
                                    .clear();
                                _horariosEscala[dia]!['fim_intervalo']!.clear();
                              }
                            });
                            _notificarMudanca();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Campos de horário (só aparecem se o dia estiver selecionado)
                if (isSelected) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _possuiIntervaloEscala[dia]!
                        ? _buildHorarioComIntervalo(dia)
                        : _buildHorarioSemIntervalo(dia),
                  ),
                ],
              ],
            ),
          );
        }),

        // Total de horas da semana
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                // MUDANÇA: Mostrar total formatado corretamente
                'TOTAL DE HORAS DA SEMANA: ${_formatarHorasParaExibicao(_calcularTotalHorasEscala())}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioComIntervalo(String dia) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INÍCIO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['inicio']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '08:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INÍCIO INT.',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['inicio_intervalo']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '12:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FIM INT.',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['fim_intervalo']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '13:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FIM',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['fim']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '18:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioSemIntervalo(String dia) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INÍCIO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['inicio']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '08:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FIM',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _horariosEscala[dia]!['fim']!,
                inputFormatters: [_horarioFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '18:00',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  // MUDANÇA: Forçar rebuild para atualizar o total
                  setState(() {});
                  _notificarMudanca();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  // MUDANÇA: Mostrar horas e minutos corretamente
                  _formatarHorasParaExibicao(_calcularHorasDia(dia)),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _horarioInicioController.dispose();
    _horarioFimController.dispose();
    _horarioInicioIntervaloController.dispose();
    _horarioFimIntervaloController.dispose();

    for (var controllers in _horariosEscala.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }
}
