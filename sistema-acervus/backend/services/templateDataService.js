const pool = require('../db');
const { injetarCssTemplate } = require('../utils/injetarCssTemplate');
const { extrairTags, substituirTags, getValorPorPath } = require('../utils/templateUtils');

// 🔄 busca dados para tags dinâmicas
async function buscarDadosPorEntidade(entidade, id) {
  //imprimir entidade
  console.log(`Buscando dados para a entidade: ${entidade} com id: ${id}`);
  switch (entidade) {
    case 'CANDIDATO': {
      const result = await pool.query(`
        SELECT
          UPPER(c.nome_completo) AS nome_completo,
          UPPER(c.rg) AS rg,
          UPPER(c.cpf) AS cpf,
          TO_CHAR(c.data_nascimento, 'DD/MM/YYYY') AS data_nascimento,
          UPPER(c.telefone) AS telefone,
          UPPER(c.semestre_ano) AS semestre_ano,
          UPPER(e.logradouro) AS logradouro,
          UPPER(e.numero) AS numero,
          UPPER(e.bairro) AS bairro,
          UPPER(e.cidade) AS cidade,
          UPPER(e.uf) AS uf,
          UPPER(e.cep) AS cep,
          UPPER(co.descricao) AS curso,
          numero_carteira_trabalho,
          numero_serie_carteira_trabalho,
          UPPER(COALESCE(c.email, ''))  as email,
          ra_matricula as matricula
        FROM public.candidato c
        LEFT JOIN public.endereco e ON e.cd_candidato = c.cd_candidato AND e.ativo = true AND e.principal = true
        LEFT JOIN public.curso co ON co.cd_curso = c.cd_curso
        WHERE c.cd_candidato = $1
      `, [id]);
      return { candidato: result.rows[0] };
    }

    case 'CONTRATO': {
      console.log(`Buscando dados do contrato com id: ${id}`);
      const result = await pool.query(`
        SELECT
         CASE
        WHEN c.aditivo = TRUE
            THEN CONCAT(c.cd_contrato_origem, ' - ', c.numero_aditivo)
        ELSE
            c.cd_contrato::text
    END AS id,
              CASE 
        WHEN c.aditivo = TRUE THEN (
            SELECT TO_CHAR(ce.data_inicio, 'DD/MM/YYYY')
            FROM public.contrato ce
            WHERE ce.cd_contrato = c.cd_contrato_origem
        )
        ELSE TO_CHAR(c.data_inicio, 'DD/MM/YYYY')
    END AS data_inicio,  
          TO_CHAR(c.data_termino, 'DD/MM/YYYY') AS data_fim,
          TO_CHAR(c.data_inicio, 'DD/MM/YYYY') AS dt_inicio_aditivo,
          TO_CHAR(c.data_termino, 'DD/MM/YYYY') AS dt_fim_aditivo,
            TO_CHAR(c.data_inicio, 'DD/MM/YYYY') AS DATA_INICIO_ADITIVO,
          TO_CHAR(c.data_termino, 'DD/MM/YYYY') AS DATA_FIM_ADITIVO,
         TO_CHAR(c.data_desligamento, 'DD/MM/YYYY') AS   data_encerramento,
          UPPER(COALESCE(s.descricao, '')) AS setor,
          COALESCE(c.total_horas_semana, 0) AS total_horas_semana,
          TO_CHAR(c.horario_inicio, 'HH24:MI') AS horario_inicio,
          TO_CHAR(c.horario_fim, 'HH24:MI') AS horario_fim,
          TO_CHAR(c.bolsa, 'FM9999990.00') AS bolsa,
          UPPER(COALESCE(c.atividades, '')) AS atividades,
          UPPER(COALESCE(valor_por_extenso(c.bolsa), '')) AS extenso_remuneracao,
          UPPER(gerar_jornada_contrato(c.cd_contrato)) AS jornada_trabalho,
          valor_transporte,
          valor_alimentacao,
          UPPER(COALESCE(valor_por_extenso(c.valor_transporte), '')) AS extenso_transporte,
          UPPER(COALESCE(valor_por_extenso(c.valor_alimentacao), '')) AS extenso_alimentacao,
          UPPER(COALESCE(CASE 
            WHEN upper(c.transporte) = 'MENSAL' THEN 'mês'
            WHEN upper(c.transporte) = 'DIARIO' THEN 'dia'
            ELSE ''
          END, '')) AS tipo_pag_transporte
         , CASE 
          WHEN aditivo = TRUE THEN (
            SELECT TO_CHAR(ce.data_termino, 'DD/MM/YYYY')
            FROM public.contrato ce
            WHERE ce.cd_contrato = c.cd_contrato_origem
          )
          ELSE TO_CHAR(c.data_termino, 'DD/MM/YYYY')
        END AS data_termino_contrato
        , REGEXP_REPLACE(
      LPAD(c.novo_cnpj, 14, '0'),
      '(\\d{2})(\\d{3})(\\d{3})(\\d{4})(\\d{2})',
      '\\1.\\2.\\3/\\4-\\5'
    ) AS novo_cnpj
        FROM public.contrato c
        left  JOIN public.setor s ON s.cd_setor = c.cd_setor
        WHERE c.cd_contrato = $1
      `, [id]);
      return { contrato: result.rows[0] };
    }

    case 'SUPERVISOR': {
      // imprimir id do supervisor
      console.log(`Buscando dados do supervisor com id: ${id}`);
      const result = await pool.query(`
          SELECT UPPER(s.nome) AS nome, UPPER(s.cargo) AS cargo, s.email, c.descricao as curso_supervisor
        FROM public.supervisor s left join curso c on s.cd_curso =  c.cd_curso
        WHERE s.cd_supervisor = $1
      `, [id]);
      // imprimir resultado da consulta do supervisor
      console.log('Resultado da busca do supervisor:', result.rows[0]);
      return { supervisor: result.rows[0] };
    }
    case 'EMPRESA': {
      console.log(`Buscando dados da empresa com id: ${id}`);
        const query = `
        SELECT
          UPPER(e.razao_social) AS razao_social,
          UPPER(e.nome_fantasia) AS nome_fantasia,
          UPPER(e.cnpj) AS cnpj,
          UPPER(e.tipo_inscricao) AS tipo_inscricao,
          UPPER(e.numero_inscricao) AS numero_inscricao,
          UPPER(e.email) AS email,
          UPPER(e.telefone) AS telefone,
          UPPER(e.celular) AS celular,
          UPPER(e.site) AS site,
          UPPER(e.observacao) AS observacao,
          UPPER(ende.logradouro) AS logradouro,
          UPPER(ende.numero) AS numero,
          UPPER(ende.bairro) AS bairro,
          UPPER(ende.cidade) AS cidade,
          UPPER(ende.uf) AS uf,
          UPPER(ende.cep) AS cep,
          UPPER(COALESCE(rep.nome, '')) AS representantenome,
          UPPER(COALESCE(rep.cargo, '')) AS representantecargo,
          seg.valor_apolice,
          UPPER(COALESCE(seg.nome_fantasia, '')) AS seguradora_nome_fantasia,
          UPPER(COALESCE(seg.numero_apolice, '')) AS numero_apolice,
          UPPER(COALESCE(seg.cnpj, '')) AS seguradora_cnpj,
          UPPER(COALESCE(e.email, '')) AS email
        FROM public.empresa e
        LEFT JOIN public.endereco ende ON ende.cd_empresa = e.cd_empresa AND ende.ativo = true AND ende.principal = true
        LEFT JOIN public.representante_legal rep ON rep.cd_empresa = e.cd_empresa AND rep.ativo = true AND rep.principal = true
        LEFT JOIN public.seguradora seg ON seg.cd_seguradora = e.cd_seguradora
        WHERE e.cd_empresa = $1;`

      console.log('Query para buscar dados da instituição de ensino:', query, 'Parâmetros:', [id]);
      const result = await pool.query(query, [id]);
      return { empresa: result.rows[0] };
    }

    case 'INSTITUICAO_ENSINO': {
      console.log(`Buscando dados da instituição de ensino com id: ${id}`);
      const query = `
        SELECT 
          UPPER(COALESCE(ie.cnpj, '')) AS cnpj,
          UPPER(COALESCE(ie.razao_social, '')) AS razao_social,
          UPPER(COALESCE(ie.nome_fantasia, '')) AS nome_fantasia,
          UPPER(COALESCE(e.logradouro, '')) AS logradouro,
          UPPER(COALESCE(e.numero, '')) AS numero,
          UPPER(COALESCE(e.bairro, '')) AS bairro,
           e.cidade  AS cidade,
          UPPER(COALESCE(e.uf, '')) AS uf,
          UPPER(COALESCE(e.cep, '')) AS cep,
          UPPER(COALESCE(e.telefone, '')) AS telefone,
          UPPER(COALESCE(rl.nome, '')) AS representante_nome,
          UPPER(COALESCE(rl.cargo, '')) AS representante_cargo,
           UPPER(COALESCE(ie.email_principal, '')) AS email
        FROM public.instituicao_ensino ie
        LEFT JOIN public.endereco e ON e.cd_instituicao_ensino = ie.cd_instituicao_ensino AND e.ativo = true AND e.principal = true
        LEFT JOIN public.representante_legal rl ON rl.cd_instituicao_ensino = ie.cd_instituicao_ensino AND rl.ativo = true AND rl.principal = true
        WHERE ie.cd_instituicao_ensino = $1
      `;
      // imprimir query e parâmetros
      console.log('Query para buscar dados da instituição de ensino:', query, 'Parâmetros:', [id]);
      const result = await pool.query(query, [id]);
      return { instituicao: result.rows[0] };
    
    }

    case 'SISTEMA': {
      const now = new Date();
      const dia = String(now.getDate()).padStart(2, '0');
      const mesExtenso = now.toLocaleString('pt-BR', { month: 'long' });
      const ano = now.getFullYear();

      return {
        data_geracao: {
          dia,
          mes: now.getMonth() + 1,
          ano,
          mes_extenso: mesExtenso
        },
        data_formatada: `${dia} de ${mesExtenso} de ${ano}`
      };
    }

    default:
      return {};
  }
}




async function obterHtmlContrato(id, idModelo) {
  const contratoQuery = `
    select conteudo_html from contrato where cd_contrato = $1
  `;
  console.log('Query para buscar conteúdo do contrato:', contratoQuery.trim(), 'Parâmetros:', [id]);
  const contratoResult = await pool.query(contratoQuery, [id]);

  if (contratoResult.rowCount === 0) {
    throw new Error('Modelo de contrato não encontrado.');
  }

  let modeloHtml = contratoResult.rows[0].conteudo_html;
 

  if (!modeloHtml) {
    throw new Error('Conteúdo do modelo HTML não encontrado.');
  }
  modeloHtml = modeloHtml.replace(/<img([^>]*?)style="[^"]*?"([^>]*?)>/g, '<img$1$2>');

  return modeloHtml;
}

async function gerarHtmlComTagsSubstituidas(id, idModelo) {
  const modeloResult = await pool.query(`
    SELECT * FROM public.template_modelo tm 
    INNER JOIN public.template_tipo_modelo tipo ON tipo.id_tipo_modelo = tm.id_tipo_modelo
    WHERE id_modelo = $1
  `, [idModelo]);

  if (modeloResult.rowCount === 0) {
    throw new Error('Modelo de contrato não encontrado.');
  }

  let modeloHtml = modeloResult.rows[0].conteudo_html;
  const tipoModelo = modeloResult.rows[0].tipo_modelo;

  if (!modeloHtml) {
    throw new Error('Conteúdo do modelo HTML não encontrado.');
  }

  modeloHtml = modeloHtml.replace(/<img([^>]*?)style="[^"]*?"([^>]*?)>/g, '<img$1$2>');

  const tagsEncontradas = extrairTags(modeloHtml);

  let tags = [];
  let entidadesEnvolvidas = [];

  if (tagsEncontradas.length > 0) {
    console.log('Tags encontradas no modelo:', tagsEncontradas);
    const placeholders = tagsEncontradas.map((_, idx) => `$${idx + 1}`).join(',');
    const tagsResult = await pool.query(
      `SELECT tag, campo, entidade FROM public.template_tag WHERE tag IN (${placeholders}) AND ativo = true`,
      tagsEncontradas
    );
    tags = tagsResult.rows;
    //imprimir todas as TAGS encontradas
    tags.forEach(tag => {
      console.log(`Tag encontrada: ${tag.tag}, Campo: ${tag.campo}, Entidade: ${tag.entidade}`);
    });
    entidadesEnvolvidas = [...new Set(tags.map(t => t.entidade))];
  }

  let dadosFinal = {};

  if (tags.length > 0) {
    let cd_empresa, cd_estudante, cd_instituicao_ensino, cd_supervisor;

     if (tipoModelo.includes('Estagio' ) ||  tipoModelo.includes('Aprendiz')) {
      console.log('Tipo de modelo inclui Estagio, buscando códigos relacionados ao contrato...');
      [cd_empresa, cd_instituicao_ensino, cd_estudante, cd_supervisor, cd_setor] = await Promise.all([
        obterpeloIdCodigoEmpresa(id),
        obterpeloIdCodigoIe(id),
        obterpeloIdCodigoCandidato(id),
        obterpeloIdCodigoSupervisor(id),
         obterpeloIdCodigoSetor(id),
      ]);
    } else {
       console.log('Tipo de modelo não inclui Estagio, usando ID diretamente...');
       cd_supervisor = id;
       cd_empresa = id;
       cd_instituicao_ensino = id;  
       cd_estudante = id;
       cd_setor = id;
    }

    //IMPRIMIR ENTIDADE
    console.log(`Entidades envolvidas: ${entidadesEnvolvidas.join(', ')}`);

    for (const entidade of entidadesEnvolvidas) {
      console.log(  `Buscando dados para a entidade: ${entidade}`);
      let codigoRelacionado;
      switch (entidade) {
        case 'EMPRESA':
          codigoRelacionado = cd_empresa;
          break;
        case 'INSTITUICAO_ENSINO':
          codigoRelacionado = cd_instituicao_ensino;
          break;
        case 'CANDIDATO':
          codigoRelacionado = cd_estudante;
          break;
        case 'SUPERVISOR':
          codigoRelacionado = cd_supervisor;
          break;
        default:
          codigoRelacionado = id;
      }

      if (codigoRelacionado) {
        const dadosEntidade = await buscarDadosPorEntidade(entidade, codigoRelacionado);
        console.log('Dados finais para substituição:', JSON.stringify(dadosEntidade, null, 2));
        dadosFinal = { ...dadosFinal, ...dadosEntidade };
      }
    }
  }

  //imrimir dados finais
  console.log('Dados finais para substituição:', JSON.stringify(dadosFinal, null, 2));

  let htmlFinal = substituirTags(modeloHtml, dadosFinal, tags);
  htmlFinal = injetarCssTemplate(htmlFinal);

  return htmlFinal;
}

async function obterpeloIdCodigoIe(id) {
        const result = await pool.query(
          'select cd_instituicao_ensino from contrato where cd_contrato = $1',
          [id]
        );
        return result.rows[0]?.cd_instituicao_ensino || null;
      }

async function obterpeloIdCodigoCandidato(id) {
        const result = await pool.query(
          'SELECT cd_estudante   from contrato where cd_contrato = $1',
          [id]
        );
        return result.rows[0]?.cd_estudante || null;
      }
 

async function obterpeloIdCodigoSupervisor(id) {
        const result = await pool.query(
          `SELECT 
            CASE 
              WHEN cd_supervisor IS NULL AND aditivo = true THEN 
          (SELECT cd_supervisor
           FROM public.contrato ce
           WHERE ce.cd_contrato = contrato.cd_contrato_origem)
              ELSE cd_supervisor
            END AS cd_supervisor
           FROM contrato WHERE cd_contrato = $1`,
          [id]
        );
        console.log('Resultado da busca de cd_supervisor:', result.rows[0]);
        return result.rows[0]?.cd_supervisor || null;
      }

      async function obterpeloIdCodigoSetor(id) {
        const result = await pool.query(
          `SELECT 
            CASE 
              WHEN cd_setor IS NULL AND aditivo = true THEN 
          (SELECT cd_setor
           FROM public.contrato ce
           WHERE ce.cd_contrato = contrato.cd_contrato_origem)
              ELSE cd_setor
            END AS cd_setor
           FROM contrato WHERE cd_contrato = $1`,
          [id]
        );
        console.log('Resultado da busca de cd_supervisor:', result.rows[0]);
        return result.rows[0]?.cd_supervisor || null;
      }


async function obterpeloIdCodigoEmpresa(id) {
        const query = 'SELECT cd_empresa FROM contrato WHERE cd_contrato = $1';
       // console.log('Executando query:', query, 'com id:', id);
        const result = await pool.query(query, [id]);
        //console.log('Resultado da busca de cd_empresa:', result.rows[0]);
        return result.rows[0]?.cd_empresa || null;
      }


module.exports = {
  buscarDadosPorEntidade,
  gerarHtmlComTagsSubstituidas, obterHtmlContrato
};