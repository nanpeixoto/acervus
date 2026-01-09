// lib/screens/admin/cidades_screen.dart
import 'package:flutter/material.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_auxiliares/localizacao/cidade.dart';
import 'package:sistema_estagio/services/_auxiliares/localizacao/cidade_service.dart';
import 'package:sistema_estagio/utils/validators.dart';

class CidadesScreen extends StatefulWidget {
  const CidadesScreen({super.key});

  @override
  State<CidadesScreen> createState() => _CidadesScreenState();
}

class _CidadesScreenState extends State<CidadesScreen> {
  final _searchController = TextEditingController();
  final _nomeController = TextEditingController();
  final _ufController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Cidade> _cidades = [];
  List<Cidade> _cidadesFiltradas = [];
  bool _isLoading = false;
  bool _isSaving = false;
  Cidade? _cidadeEditando;

  @override
  void initState() {
    super.initState();
    _loadCidades();
    _searchController.addListener(_filterCidades);
  }

  Future<void> _loadCidades() async {
    setState(() => _isLoading = true);

    try {
      final cidades = await CidadeService.listarCidades();
      setState(() {
        _cidades = cidades;
        _cidadesFiltradas = cidades;
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar cidades: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCidades() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _cidadesFiltradas = _cidades.where((cidade) {
        return cidade.nome.toLowerCase().contains(query) ||
            cidade.uf.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gerenciar Cidades',
        actions: [
          IconButton(
            onPressed: _showCidadeDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Cidade',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Cabeçalho com busca e estatísticas
            _buildHeader(),

            // Lista de cidades
            Expanded(
              child: _buildCidadesList(),
            ),
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
          // Estatísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Cidades',
                  _cidades.length.toString(),
                  Icons.location_city,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'UFs Cadastradas',
                  _cidades.map((c) => c.uf).toSet().length.toString(),
                  Icons.map,
                  const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          CustomTextField(
            controller: _searchController,
            label: 'Buscar cidades ou UF...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _filterCidades();
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
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

  Widget _buildCidadesList() {
    if (_cidadesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _cidades.isEmpty
                  ? 'Nenhuma cidade cadastrada'
                  : 'Nenhuma cidade encontrada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_cidades.isEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _showCidadeDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeira Cidade'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cidadesFiltradas.length,
      itemBuilder: (context, index) {
        final cidade = _cidadesFiltradas[index];
        return _buildCidadeCard(cidade);
      },
    );
  }

  Widget _buildCidadeCard(Cidade cidade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32),
          child: Text(
            cidade.uf,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          cidade.nome,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${cidade.uf} • ${cidade.regiao}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'editar':
                _editarCidade(cidade);
                break;
              case 'excluir':
                _confirmarExclusao(cidade);
                break;
            }
          },
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
            const PopupMenuItem(
              value: 'excluir',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCidadeDialog([Cidade? cidade]) {
    _cidadeEditando = cidade;

    if (cidade != null) {
      _nomeController.text = cidade.nome;
      _ufController.text = cidade.uf;
    } else {
      _nomeController.clear();
      _ufController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cidade == null ? 'Adicionar Cidade' : 'Editar Cidade'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nomeController,
                label: 'Nome da Cidade',
                validator: (value) =>
                    Validators.validateRequired(value, 'Nome'),
                prefixIcon: const Icon(Icons.location_city),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ufController,
                label: 'UF',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'UF é obrigatória';
                  }
                  if (value.length != 2) {
                    return 'UF deve ter 2 caracteres';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.map),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _salvarCidade,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(cidade == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarCidade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final cidade = Cidade(
        id: _cidadeEditando?.id,
        nome: _nomeController.text,
        uf: _ufController.text.toUpperCase(),
        regiao: _getRegiaoByUF(_ufController.text.toUpperCase()),
      );

      bool success;
      if (_cidadeEditando == null) {
        success = await CidadeService.criarCidade(cidade);
      } else {
        success = await CidadeService.atualizarCidade(cidade);
      }

      if (success) {
        Navigator.of(context).pop();
        AppUtils.showSuccessSnackBar(
            context,
            _cidadeEditando == null
                ? 'Cidade adicionada com sucesso!'
                : 'Cidade atualizada com sucesso!');
        _loadCidades();
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao salvar cidade');
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _editarCidade(Cidade cidade) {
    _showCidadeDialog(cidade);
  }

  Future<void> _confirmarExclusao(Cidade cidade) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Cidade',
      content: 'Tem certeza que deseja excluir a cidade "${cidade.nome}"?',
      confirmText: 'Excluir',
    );

    if (confirm) {
      _excluirCidade(cidade);
    }
  }

  Future<void> _excluirCidade(Cidade cidade) async {
    setState(() => _isLoading = true);

    try {
      final success = await CidadeService.excluirCidade(cidade.id!);

      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Cidade excluída com sucesso!');
        _loadCidades();
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao excluir cidade');
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getRegiaoByUF(String uf) {
    const regioes = {
      'AC': 'Norte',
      'AL': 'Nordeste',
      'AP': 'Norte',
      'AM': 'Norte',
      'BA': 'Nordeste',
      'CE': 'Nordeste',
      'DF': 'Centro-Oeste',
      'ES': 'Sudeste',
      'GO': 'Centro-Oeste',
      'MA': 'Nordeste',
      'MT': 'Centro-Oeste',
      'MS': 'Centro-Oeste',
      'MG': 'Sudeste',
      'PA': 'Norte',
      'PB': 'Nordeste',
      'PR': 'Sul',
      'PE': 'Nordeste',
      'PI': 'Nordeste',
      'RJ': 'Sudeste',
      'RN': 'Nordeste',
      'RS': 'Sul',
      'RO': 'Norte',
      'RR': 'Norte',
      'SC': 'Sul',
      'SP': 'Sudeste',
      'SE': 'Nordeste',
      'TO': 'Norte',
    };
    return regioes[uf] ?? 'Não informado';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    _ufController.dispose();
    super.dispose();
  }
}
