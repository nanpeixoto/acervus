// lib/screens/admin/turma_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/services/_academico/curso/curso_aprendizagem_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/custom_dropdown.dart';
import 'package:sistema_estagio/models/_academico/turma/turma.dart';
import 'package:sistema_estagio/services/_academico/curso/turma_service.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  final _searchController = TextEditingController();

  List<Turma> _turmas = [];
  //List<CursoAprendizagemOption> _cursosAprendizagem = [];
  // Adicionar variáveis para controle do autocomplete
  static const List<int> _pageSizeOptions = [5, 10, 20, 50, 100];
  String? _cursoAprendizagemSelecionado;
  String? _cursoAprendizagemNome;
  final _cursoAprendizagemController = TextEditingController();
  bool _isLoading = false;
  bool _ativo = true;
  final bool _isDefault = false;

  // Paginação
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  // Formulário
  bool _showForm = false;
  Turma? _turmaEditando;
  final _formKey = GlobalKey<FormState>();
  final _numeroTurmaController = TextEditingController();
  //int? _cursoAprendizagemSelecionado;

  @override
  void initState() {
    super.initState();
    //_loadCursosAprendizagem();
    _loadTurmas();
  }

  Future<void> _loadTurmas({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await TurmaService.listarTurmas(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      if (mounted) {
        setState(() {
          _turmas = result['turmas'];
          _pagination = result['pagination'];
        });
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showErrorSnackBar(context, 'Erro ao carregar turmas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFormulario([Turma? turma]) async {
    setState(() {
      _showForm = true;
      _turmaEditando = turma;
    });

    if (turma != null) {
      // ✅ BUSCAR DADOS COMPLETOS DA TURMA
      try {
        setState(() => _isLoading = true);

        final turmaCompleta = await TurmaService.buscarTurmaPorId(turma.id!);

        // Usar campos do JSON conforme estrutura retornada
        _numeroTurmaController.text = turmaCompleta['numero'].toString();

        setState(() {
          _cursoAprendizagemSelecionado = turmaCompleta['cd_curso'].toString();
          _cursoAprendizagemNome = turmaCompleta['curso'];
          _cursoAprendizagemController.text = turmaCompleta['curso'];
        });

        print('✅ Dados da turma carregados: $turmaCompleta');
      } catch (e) {
        print('❌ Erro ao buscar dados da turma: $e');
        AppUtils.showErrorSnackBar(
            context, 'Erro ao carregar dados da turma: $e');

        // Fallback para dados básicos se falhar
        _numeroTurmaController.text = turma.numeroTurma.toString();
        setState(() {
          _cursoAprendizagemSelecionado = turma.cursoAprendizagemId.toString();
          _cursoAprendizagemNome = turma.cursoAprendizagemNome ?? '';
          _cursoAprendizagemController.text = turma.cursoAprendizagemNome ?? '';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _limparFormulario();
    }
  }

  void _limparFormulario() {
    _numeroTurmaController.clear();
    _cursoAprendizagemController.clear();
    _cursoAprendizagemSelecionado = null;
    _cursoAprendizagemNome = null;
  }

  Future<void> _salvarTurma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cursoAprendizagemSelecionado == null) {
      AppUtils.showErrorSnackBar(
          context, 'Por favor, selecione um curso de aprendizagem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar se o número da turma já existe para o curso
      if (_turmaEditando == null ||
          _turmaEditando!.numeroTurma != _numeroTurmaController.text.trim() ||
          _turmaEditando!.cursoAprendizagemId.toString() !=
              _cursoAprendizagemSelecionado) {}

      final dados = {
        'numero': _numeroTurmaController.text.trim(),
        'cd_curso':
            int.parse(_cursoAprendizagemSelecionado!), // Converter para int
        'ativo': true,
        'criado_por': 'usuario_atual', // TODO: Pegar do provider
      };

      bool sucesso;
      if (_turmaEditando != null) {
        dados['alterado_por'] = 'usuario_atual'; // TODO: Pegar do provider
        sucesso = await TurmaService.atualizarTurma(_turmaEditando!.id!, dados);
      } else {
        sucesso = await TurmaService.criarTurma(dados);
      }

      if (sucesso) {
        AppUtils.showSuccessSnackBar(
          context,
          _turmaEditando != null
              ? 'Turma atualizada com sucesso!'
              : 'Turma criada com sucesso!',
        );
        setState(() => _showForm = false);
        _loadTurmas();
        TurmaService.clearCache();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao salvar turma: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirTurma(Turma turma) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deseja excluir a turma "${turma.numeroTurma}" do curso "${turma.cursoAprendizagemNome}"?\n\n'
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      setState(() => _isLoading = true);
      try {
        await TurmaService.deletarTurma(turma.id!);
        AppUtils.showSuccessSnackBar(context, 'Turma excluída com sucesso!');
        _loadTurmas();
        TurmaService.clearCache();
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro ao excluir turma: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _pesquisar() {
    setState(() {
      _currentSearch = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadTurmas();
  }

  void _limparPesquisa() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadTurmas();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Turmas',
          actions: [
            // Botão Exportar
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Implementar exportação
                AppUtils.showErrorSnackBar(
                    context, 'Funcionalidade de exportação em desenvolvimento');
              },
              tooltip: 'Exportar',
            ),
            // Botão Adicionar Turma
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showFormulario(),
              tooltip: 'Adicionar Turma',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTurmas,
              tooltip: 'Atualizar',
            ),
          ],
        ),
        body: Column(
          children: [
            if (_showForm) _buildFormulario(),
            if (!_showForm) _buildHeader(),
            if (!_showForm) Expanded(child: _buildTurmasList()),
            if (!_showForm) _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Estatísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Turmas',
                  (_pagination?['total'] ?? _turmas.length).toString(),
                  Icons.group,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativas',
                  _turmas.length
                      .toString(), // Todas turmas são ativas por padrão
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou descrição',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _currentSearch.isNotEmpty
                        ? IconButton(
                            onPressed: _limparPesquisa,
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _pesquisar(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pesquisar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Configurações de paginação
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página: ', style: TextStyle(fontSize: 14)),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                      _currentPage = 1;
                    });
                    _loadTurmas();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadTurmas();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _turmaEditando != null ? Icons.edit : Icons.add,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Text(
                  _turmaEditando != null ? 'Editar Turma' : 'Nova Turma',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showForm = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos do formulário
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _numeroTurmaController,
                    label: 'Número da Turma',
                    validator: Turma.validarNumeroTurma,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (curso) => curso['nome'],
                    optionsBuilder: (textEditingValue) async {
                      final query = textEditingValue.text.trim();

                      if (query.length < 3) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }

                      try {
                        final result = await CursoAprendizagemService
                            .buscarCursoAprendizagem(query);
                        // Converter CursoAprendizagem para Map para usar no Autocomplete
                        return (result ?? []).map((curso) => {
                              'id': curso.id.toString(),
                              'nome': curso.nomeCurso,
                              'nome_aprendizagem': curso.nomeCursoAprendizagem,
                            });
                      } catch (e) {
                        print('Erro ao buscar cursos: $e');
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                    },
                    onSelected: (curso) {
                      setState(() {
                        _cursoAprendizagemSelecionado = curso['id'];
                        _cursoAprendizagemNome = curso['nome'];
                        _cursoAprendizagemController.text = curso['nome'];
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      // Preencher o campo no modo edição
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted &&
                            _cursoAprendizagemNome != null &&
                            _cursoAprendizagemNome!.isNotEmpty &&
                            controller.text.isEmpty) {
                          controller.text = _cursoAprendizagemNome!;
                        }
                      });

                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: 'Curso de Aprendizagem',
                          hintText:
                              'Digite para buscar curso (mín. 3 caracteres)',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: Icon(Icons.search),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          if (_cursoAprendizagemSelecionado == null) {
                            return 'Selecione um curso válido da lista';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Se o usuário limpar o campo, limpar a seleção
                          if (value.isEmpty) {
                            setState(() {
                              _cursoAprendizagemSelecionado = null;
                              _cursoAprendizagemNome = null;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                ElevatedButton(
                  onPressed: _salvarTurma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: Text(_turmaEditando != null ? 'Atualizar' : 'Criar'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _showForm = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurmasList() {
    if (_turmas.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhuma turma encontrada com "$_currentSearch"'
                  : 'Nenhuma turma cadastrada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar primeira turma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _turmas.length,
            itemBuilder: (context, index) {
              final turma = _turmas[index];
              return _buildTurmaCard(turma, index);
            },
          ),
        ),
        // ✅ ADICIONAR PAGINAÇÃO AQUI
        if (_pagination != null && (_pagination!['pages'] ?? 0) > 1)
          _buildPaginationControls(),
      ],
    );
  }

// ===== ADICIONAR MÉTODO _buildPaginacao() =====

  Widget _buildPaginationControls() {
    if (_turmas.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['pages'] ??
        ((_turmas.isNotEmpty)
            ? ((_turmas.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['page'] ?? _currentPage;
    final total = _pagination?['total'] ?? _turmas.length;
    final hasNextPage =
        _pagination?['hasNextPage'] ?? (_currentPage < totalPages);
    final hasPrevPage = _pagination?['hasPrevPage'] ?? (_currentPage > 1);

    final startItem = ((currentPage - 1) * _pageSize) + 1;
    final endItem =
        (currentPage * _pageSize) > total ? total : (currentPage * _pageSize);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $startItem-$endItem de $total registros',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Página $currentPage de $totalPages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Primeira página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 1
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed:
                    hasPrevPage ? () => _goToPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                style: IconButton.styleFrom(
                  backgroundColor: hasPrevPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 16),
              ..._buildPageNumbers(currentPage, totalPages),
              const SizedBox(width: 16),
              IconButton(
                onPressed:
                    hasNextPage ? () => _goToPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próxima página',
                style: IconButton.styleFrom(
                  backgroundColor: hasNextPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => _goToPage(totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Última página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ===== ADICIONAR MÉTODO _buildPageNumbers() =====

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> pages = [];

    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    if (end - start < 4) {
      if (start == 1) {
        end = (start + 4).clamp(1, totalPages);
      } else if (end == totalPages) {
        start = (end - 4).clamp(1, totalPages);
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: i == currentPage ? null : () => _goToPage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF2E7D32) : Colors.white,
              foregroundColor:
                  i == currentPage ? Colors.white : const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return pages;
  }

// ===== ADICIONAR MÉTODO _goToPage() =====

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1) {
      setState(() => _currentPage = page);
      _loadTurmas(showLoading: false);
    }
  }

  Widget _buildTurmaCard(Turma turma, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Center(
                    child: Text(
                      turma.id?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TURMA: ${turma.numeroTurma.toString()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        turma.cursoAprendizagemNome ?? 'Curso não encontrado',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, turma),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: turma.ativo ? 'desativar' : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            turma.ativo
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: turma.ativo ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            turma.ativo ? 'Desativar' : 'Ativar',
                            style: TextStyle(
                              color: turma.ativo ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: turma.ativo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: turma.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    turma.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: turma.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${turma.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Turma turma) {
    switch (action) {
      case 'editar':
        _editarTurma(turma);
        break;
      case 'ativar':
        _ativarTurma(turma);
        break;
      case 'desativar':
        _desativarTurma(turma);
        break;
      case 'excluir':
        _confirmarExclusao(turma);
        break;
    }
  }

  //implementar metodo _editarTurma com base no codigo do plano de pagamento screen.dart
  void _editarTurma(Turma turma) async {
    setState(() {
      _ativo = turma.ativo;
      _showForm = true;
      _turmaEditando = turma;
      _isLoading = true;
    });

    try {
      // ✅ BUSCAR DADOS COMPLETOS DA TURMA
      final turmaCompleta = await TurmaService.buscarTurmaPorId(turma.id!);

      _numeroTurmaController.text = turmaCompleta['numero'].toString();

      setState(() {
        _cursoAprendizagemSelecionado = turmaCompleta['cd_curso'].toString();
        _cursoAprendizagemNome = turmaCompleta['curso'];
        _cursoAprendizagemController.text = turmaCompleta['curso'];
      });

      print('✅ Turma editada carregada: $turmaCompleta');
    } catch (e) {
      print('❌ Erro ao buscar dados da turma: $e');
      AppUtils.showErrorSnackBar(
          context, 'Erro ao carregar dados da turma: $e');

      // Fallback para dados básicos se falhar
      _numeroTurmaController.text = turma.numeroTurma.toString();
      setState(() {
        _cursoAprendizagemSelecionado = turma.cursoAprendizagemId.toString();
        _cursoAprendizagemNome = turma.cursoAprendizagemNome ?? '';
        _cursoAprendizagemController.text = turma.cursoAprendizagemNome ?? '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ativarTurma(Turma turma) async {
    try {
      final success = await TurmaService.ativarTurma(turma.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item ativado com sucesso!');
        _loadTurmas(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarTurma(Turma turma) async {
    try {
      final success = await TurmaService.desativarTurma(turma.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item desativado com sucesso!');
        _loadTurmas(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _confirmarExclusao(Turma turma) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Item',
      content:
          'Tem certeza que deseja excluir "${turma.id}"?\n\nEsta ação não pode ser desfeita e pode afetar Turmas que utilizam este status.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success = await TurmaService.deletarTurma(turma.id!);
        if (success) {
          AppUtils.showSuccessSnackBar(context, 'Item excluído com sucesso!');
          _loadTurmas();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _numeroTurmaController.dispose();
    _cursoAprendizagemController.dispose(); // Adicionar esta linha
    super.dispose();
  }
}
