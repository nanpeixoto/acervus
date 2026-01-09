import 'package:flutter/material.dart';

/// Widget melhorado para exibir seguradoras em dropdowns
/// Mostra informações completas sem truncar texto
class SeguradoraDropdownItem extends StatelessWidget {
  final String razaoSocial;
  final String? nomeFantasia;
  final String? cnpj;
  final String? cidade;
  final String? uf;
  final bool ativo;
  final bool isSelected;

  const SeguradoraDropdownItem({
    super.key,
    required this.razaoSocial,
    this.nomeFantasia,
    this.cnpj,
    this.cidade,
    this.uf,
    this.ativo = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        nomeFantasia?.isNotEmpty == true ? nomeFantasia! : razaoSocial;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade50 : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ícone de identificação
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ativo ? Colors.blue.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: ativo ? Colors.blue.shade700 : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Informações da seguradora
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nome completo (sem truncar)
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ativo ? Colors.black87 : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // CNPJ e localização
                Row(
                  children: [
                    if (cnpj != null && cnpj!.isNotEmpty) ...[
                      Icon(
                        Icons.badge,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatarCNPJ(cnpj!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if ((cidade != null && cidade!.isNotEmpty) ||
                        (uf != null && uf!.isNotEmpty)) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _montarLocalizacao(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Badge de status
          if (ativo)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                'Ativa',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Inativa',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Formata CNPJ para o padrão XX.XXX.XXX/XXXX-XX
  String _formatarCNPJ(String cnpj) {
    final numeros = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length != 14) return cnpj;

    return '${numeros.substring(0, 2)}.${numeros.substring(2, 5)}.${numeros.substring(5, 8)}/${numeros.substring(8, 12)}-${numeros.substring(12)}';
  }

  /// Monta string de localização (Cidade - UF)
  String _montarLocalizacao() {
    if (cidade != null && cidade!.isNotEmpty && uf != null && uf!.isNotEmpty) {
      return '$cidade - $uf';
    } else if (cidade != null && cidade!.isNotEmpty) {
      return cidade!;
    } else if (uf != null && uf!.isNotEmpty) {
      return uf!;
    }
    return '';
  }
}

/// Widget simplificado para quando a seguradora está selecionada
/// Mostra apenas o nome de forma compacta
class SeguradoraDropdownSelectedItem extends StatelessWidget {
  final String razaoSocial;
  final String? nomeFantasia;
  final bool ativo;

  const SeguradoraDropdownSelectedItem({
    super.key,
    required this.razaoSocial,
    this.nomeFantasia,
    this.ativo = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        nomeFantasia?.isNotEmpty == true ? nomeFantasia! : razaoSocial;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: ativo ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                color: ativo ? Colors.black87 : Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
