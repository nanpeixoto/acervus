#!/bin/bash

# =====================================================
# Script de Migração - Estrutura de Screens
# Sistema de Gestão de Estágios - CIDE
# =====================================================

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 Migração de Estrutura de Screens - CIDE       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se estamos no diretório correto
if [ ! -d "lib/screens" ]; then
    echo -e "${RED}❌ Erro: Diretório lib/screens não encontrado!${NC}"
    echo -e "${YELLOW}   Execute este script na raiz do projeto frontend.${NC}"
    exit 1
fi

# Criar backup
BACKUP_DIR="lib/screens_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Criando backup em: ${BACKUP_DIR}${NC}"
cp -r lib/screens "$BACKUP_DIR"
echo -e "${GREEN}✅ Backup criado com sucesso!${NC}"
echo ""

# =====================================================
# FASE 1: Criar Estrutura de Diretórios
# =====================================================

echo -e "${BLUE}📁 FASE 1: Criando nova estrutura de diretórios...${NC}"

# Sistema Público
mkdir -p lib/screens/public/home
mkdir -p lib/screens/public/auth
mkdir -p lib/screens/public/cadastros_publicos/estagiario
mkdir -p lib/screens/public/cadastros_publicos/jovem_aprendiz
mkdir -p lib/screens/public/cadastros_publicos/empresa
mkdir -p lib/screens/public/cadastros_publicos/instituicao

# Sistema Administrativo
mkdir -p lib/screens/admin/dashboard

# Cadastros
mkdir -p lib/screens/admin/cadastros/_pessoas/candidatos
mkdir -p lib/screens/admin/cadastros/_pessoas/usuarios
mkdir -p lib/screens/admin/cadastros/_organizacoes/empresas
mkdir -p lib/screens/admin/cadastros/_organizacoes/instituicoes
mkdir -p lib/screens/admin/cadastros/_auxiliares/cursos
mkdir -p lib/screens/admin/cadastros/_auxiliares/cursos_aprendizagem
mkdir -p lib/screens/admin/cadastros/_auxiliares/turmas
mkdir -p lib/screens/admin/cadastros/_auxiliares/setores
mkdir -p lib/screens/admin/cadastros/_auxiliares/seguradoras
mkdir -p lib/screens/admin/cadastros/_auxiliares/cidades
mkdir -p lib/screens/admin/cadastros/_auxiliares/cbo
mkdir -p lib/screens/admin/cadastros/_auxiliares/idiomas
mkdir -p lib/screens/admin/cadastros/_auxiliares/conhecimentos
mkdir -p lib/screens/admin/cadastros/_auxiliares/niveis

# Vagas
mkdir -p lib/screens/admin/vagas/vagas_estagio
mkdir -p lib/screens/admin/vagas/vagas_aprendizagem
mkdir -p lib/screens/admin/vagas/processo_seletivo

# Contratos
mkdir -p lib/screens/admin/contratos/estagio
mkdir -p lib/screens/admin/contratos/aprendizagem
mkdir -p lib/screens/admin/contratos/termos_aditivos
mkdir -p lib/screens/admin/contratos/alertas
mkdir -p lib/screens/admin/contratos/modelos

# Financeiro
mkdir -p lib/screens/admin/financeiro/faturamento
mkdir -p lib/screens/admin/financeiro/taxas
mkdir -p lib/screens/admin/financeiro/planos_pagamento

# Relatórios e Configurações
mkdir -p lib/screens/admin/relatorios
mkdir -p lib/screens/admin/configuracoes/sistema
mkdir -p lib/screens/admin/configuracoes/perfil

# Portais de Usuários
mkdir -p lib/screens/candidato/dashboard
mkdir -p lib/screens/candidato/perfil
mkdir -p lib/screens/candidato/vagas
mkdir -p lib/screens/candidato/documentos
mkdir -p lib/screens/empresa/dashboard
mkdir -p lib/screens/empresa/vagas
mkdir -p lib/screens/empresa/contratos
mkdir -p lib/screens/instituicao/dashboard
mkdir -p lib/screens/instituicao/alunos
mkdir -p lib/screens/instituicao/contratos

echo -e "${GREEN}✅ Estrutura de diretórios criada!${NC}"
echo ""

# =====================================================
# FASE 2: Mover e Renomear Arquivos
# =====================================================

echo -e "${BLUE}🔄 FASE 2: Movendo e renomeando arquivos...${NC}"

# Função auxiliar para mover arquivo
move_file() {
    local source=$1
    local dest=$2
    
    if [ -f "$source" ]; then
        mv "$source" "$dest" 2>/dev/null && \
        echo -e "${GREEN}  ✓${NC} $(basename $source) → $(basename $dest)"
    else
        echo -e "${YELLOW}  ⚠${NC} Arquivo não encontrado: $(basename $source)"
    fi
}

# ===== DASHBOARD =====
echo -e "${YELLOW}📊 Dashboard...${NC}"
move_file "lib/screens/admin/dashboard_screen.dart" \
          "lib/screens/admin/dashboard/dashboard_screen.dart"

# ===== CADASTROS - PESSOAS =====
echo -e "${YELLOW}👥 Cadastros - Pessoas...${NC}"
move_file "lib/screens/admin/candidatos_screen.dart" \
          "lib/screens/admin/cadastros/_pessoas/candidatos/candidatos_list_screen.dart"
move_file "lib/screens/admin/usuario_screen.dart" \
          "lib/screens/admin/cadastros/_pessoas/usuarios/usuarios_list_screen.dart"

# ===== CADASTROS - ORGANIZAÇÕES =====
echo -e "${YELLOW}🏢 Cadastros - Organizações...${NC}"
move_file "lib/screens/admin/empresas_screen.dart" \
          "lib/screens/admin/cadastros/_organizacoes/empresas/empresas_list_screen.dart"
move_file "lib/screens/admin/instituicoes_screen.dart" \
          "lib/screens/admin/cadastros/_organizacoes/instituicoes/instituicoes_list_screen.dart"

# ===== CADASTROS - AUXILIARES =====
echo -e "${YELLOW}📚 Cadastros - Auxiliares...${NC}"
move_file "lib/screens/admin/cursos_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/cursos/cursos_list_screen.dart"
move_file "lib/screens/admin/curso_aprendizagem_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/cursos_aprendizagem/cursos_aprendizagem_list_screen.dart"
move_file "lib/screens/admin/turma_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/turmas/turmas_list_screen.dart"
move_file "lib/screens/admin/setores_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/setores/setores_list_screen.dart"
move_file "lib/screens/admin/seguradoras_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/seguradoras/seguradoras_list_screen.dart"
move_file "lib/screens/admin/cidades_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/cidades/cidades_list_screen.dart"
move_file "lib/screens/admin/cbo_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/cbo/cbo_list_screen.dart"
move_file "lib/screens/admin/idiomas_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/idiomas/idiomas_list_screen.dart"
move_file "lib/screens/admin/conhecimentos_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/conhecimentos/conhecimentos_list_screen.dart"
move_file "lib/screens/admin/experiencia_profissional_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/conhecimentos/experiencia_profissional_screen.dart"

# Níveis
move_file "lib/screens/admin/niveis_conhecimento_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/niveis/niveis_conhecimento_screen.dart"
move_file "lib/screens/admin/niveis_formacao_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/niveis/niveis_formacao_screen.dart"
move_file "lib/screens/admin/modalidades_ensino_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/niveis/modalidades_ensino_screen.dart"
move_file "lib/screens/admin/turnos_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/niveis/turnos_screen.dart"
move_file "lib/screens/admin/status_curso_screen.dart" \
          "lib/screens/admin/cadastros/_auxiliares/niveis/status_curso_screen.dart"

# ===== VAGAS =====
echo -e "${YELLOW}💼 Vagas...${NC}"
move_file "lib/screens/admin/vagas_screen.dart" \
          "lib/screens/admin/vagas/vagas_estagio/vagas_estagio_list_screen.dart"
move_file "lib/screens/admin/lista_vagas_screen.dart" \
          "lib/screens/admin/vagas/vagas_aprendizagem/vagas_aprendizagem_list_screen.dart"

# ===== CONTRATOS =====
echo -e "${YELLOW}📄 Contratos...${NC}"

# Estágio
move_file "lib/screens/admin/contratos_estagio_screen.dart" \
          "lib/screens/admin/contratos/estagio/contratos_estagio_list_screen.dart"
move_file "lib/screens/admin/cadastro_contrato_estagio_screen.dart" \
          "lib/screens/admin/contratos/estagio/contrato_estagio_form_screen.dart"

# Aprendizagem
move_file "lib/screens/admin/contrato_aprendiz_screen.dart" \
          "lib/screens/admin/contratos/aprendizagem/contratos_aprendizagem_list_screen.dart"
move_file "lib/screens/admin/cadastro_contrato_aprendiz_screen.dart" \
          "lib/screens/admin/contratos/aprendizagem/contrato_aprendizagem_form_screen.dart"

# Alertas
move_file "lib/screens/admin/contratos_a_vencer_screen.dart" \
          "lib/screens/admin/contratos/alertas/contratos_a_vencer_screen.dart"

# Modelos
move_file "lib/screens/admin/cadastro_modelo_contrato_screen.dart" \
          "lib/screens/admin/contratos/modelos/modelo_contrato_form_screen.dart"
move_file "lib/screens/admin/tipos_modelos_screen.dart" \
          "lib/screens/admin/contratos/modelos/tipos_modelos_screen.dart"

# ===== FINANCEIRO =====
echo -e "${YELLOW}💰 Financeiro...${NC}"
move_file "lib/screens/admin/taxa_administrativa_screen.dart" \
          "lib/screens/admin/financeiro/taxas/taxa_administrativa_screen.dart"
move_file "lib/screens/admin/visualizacao_taxas_horizontal_screen.dart" \
          "lib/screens/admin/financeiro/taxas/visualizacao_taxas_horizontal_screen.dart"
move_file "lib/screens/admin/planos_pagamentos_screen.dart" \
          "lib/screens/admin/financeiro/planos_pagamento/planos_pagamento_list_screen.dart"

echo -e "${GREEN}✅ Arquivos movidos com sucesso!${NC}"
echo ""

# =====================================================
# FASE 3: Criar Arquivos de Export
# =====================================================

echo -e "${BLUE}📦 FASE 3: Criando arquivos de export...${NC}"

# Export de Cadastros
cat > lib/screens/admin/cadastros/_exports.dart << 'EOF'
// =====================================================
// Exports - Módulo de Cadastros
// Auto-gerado pelo script de migração
// =====================================================

// === PESSOAS ===
// Candidatos
export '_pessoas/candidatos/candidatos_list_screen.dart';

// Usuários
export '_pessoas/usuarios/usuarios_list_screen.dart';

// === ORGANIZAÇÕES ===
// Empresas
export '_organizacoes/empresas/empresas_list_screen.dart';

// Instituições
export '_organizacoes/instituicoes/instituicoes_list_screen.dart';

// === AUXILIARES ===
// Cursos
export '_auxiliares/cursos/cursos_list_screen.dart';
export '_auxiliares/cursos_aprendizagem/cursos_aprendizagem_list_screen.dart';

// Outros
export '_auxiliares/turmas/turmas_list_screen.dart';
export '_auxiliares/setores/setores_list_screen.dart';
export '_auxiliares/seguradoras/seguradoras_list_screen.dart';
export '_auxiliares/cidades/cidades_list_screen.dart';
export '_auxiliares/cbo/cbo_list_screen.dart';
export '_auxiliares/idiomas/idiomas_list_screen.dart';
export '_auxiliares/conhecimentos/conhecimentos_list_screen.dart';
export '_auxiliares/conhecimentos/experiencia_profissional_screen.dart';

// Níveis
export '_auxiliares/niveis/niveis_conhecimento_screen.dart';
export '_auxiliares/niveis/niveis_formacao_screen.dart';
export '_auxiliares/niveis/modalidades_ensino_screen.dart';
export '_auxiliares/niveis/turnos_screen.dart';
export '_auxiliares/niveis/status_curso_screen.dart';
EOF

# Export de Contratos
cat > lib/screens/admin/contratos/_exports.dart << 'EOF'
// =====================================================
// Exports - Módulo de Contratos
// Auto-gerado pelo script de migração
// =====================================================

// Estágio
export 'estagio/contratos_estagio_list_screen.dart';
export 'estagio/contrato_estagio_form_screen.dart';

// Aprendizagem
export 'aprendizagem/contratos_aprendizagem_list_screen.dart';
export 'aprendizagem/contrato_aprendizagem_form_screen.dart';

// Alertas
export 'alertas/contratos_a_vencer_screen.dart';

// Modelos
export 'modelos/modelo_contrato_form_screen.dart';
export 'modelos/tipos_modelos_screen.dart';
EOF

# Export de Vagas
cat > lib/screens/admin/vagas/_exports.dart << 'EOF'
// =====================================================
// Exports - Módulo de Vagas
// Auto-gerado pelo script de migração
// =====================================================

// Vagas de Estágio
export 'vagas_estagio/vagas_estagio_list_screen.dart';

// Vagas de Aprendizagem
export 'vagas_aprendizagem/vagas_aprendizagem_list_screen.dart';
EOF

# Export de Financeiro
cat > lib/screens/admin/financeiro/_exports.dart << 'EOF'
// =====================================================
// Exports - Módulo Financeiro
// Auto-gerado pelo script de migração
// =====================================================

// Taxas
export 'taxas/taxa_administrativa_screen.dart';
export 'taxas/visualizacao_taxas_horizontal_screen.dart';

// Planos de Pagamento
export 'planos_pagamento/planos_pagamento_list_screen.dart';
EOF

echo -e "${GREEN}✅ Arquivos de export criados!${NC}"
echo ""

# =====================================================
# FINALIZAÇÃO
# =====================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ Migração concluída com sucesso!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 PRÓXIMOS PASSOS:${NC}"
echo ""
echo -e "  ${BLUE}1.${NC} Atualizar imports em todos os arquivos"
echo -e "     ${YELLOW}Buscar:${NC} import '.*/(.*_screen)\\.dart';"
echo -e "     ${YELLOW}Substituir por:${NC} novo caminho conforme estrutura"
echo ""
echo -e "  ${BLUE}2.${NC} Atualizar rotas em ${YELLOW}lib/routes/app_routes.dart${NC}"
echo ""
echo -e "  ${BLUE}3.${NC} Executar testes:"
echo -e "     ${YELLOW}flutter analyze${NC}"
echo -e "     ${YELLOW}flutter test${NC}"
echo ""
echo -e "  ${BLUE}4.${NC} Testar navegação completa do sistema"
echo ""
echo -e "  ${BLUE}5.${NC} Se tudo OK, remover backup:"
echo -e "     ${YELLOW}rm -rf $BACKUP_DIR${NC}"
echo ""
echo -e "${BLUE}📦 Backup criado em:${NC} ${YELLOW}$BACKUP_DIR${NC}"
echo -e "${BLUE}📄 Documentação:${NC} ${YELLOW}PROPOSTA_REORGANIZACAO_SCREENS.md${NC}"
echo ""
