const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');



router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    cd_candidato,
    cd_conhecimento,
    descricao_conhecimento,
    cd_nivel_conhecimento
  } = req.body;

  if (!cd_candidato) {
    return res.status(400).json({ erro: 'Código do candidato é obrigatório.' });
  }

  if (!cd_nivel_conhecimento) {
    return res.status(400).json({ erro: 'Nível de conhecimento é obrigatório.' });
  }

  if (!cd_conhecimento && !descricao_conhecimento) {
    return res.status(400).json({ erro: 'Informe um conhecimento da lista ou digite um novo conhecimento.' });
  }

  const criado_por = req.usuario?.cd_usuario || null;


  if (await verificarDuplicidadeConhecimento({ cd_candidato, cd_conhecimento })) {
  return res.status(400).json({ erro: 'Este conhecimento já está cadastrado para o candidato.' });
}

  const query = `
    INSERT INTO public.candidato_conhecimento (
      cd_candidato,
      cd_conhecimento,
      descricao_conhecimento,
      cd_nivel_conhecimento,
      data_criacao,
      criado_por
    ) VALUES ($1, $2, $3, $4, NOW(), $5)
    RETURNING cd_conhecimento_candidato
  `;

  try {
    const values = [cd_candidato, cd_conhecimento || null, descricao_conhecimento || null, cd_nivel_conhecimento, criado_por];
    const result = await pool.query(query, values);
    res.status(201).json({ mensagem: 'Conhecimento cadastrado com sucesso.', cd_conhecimento_candidato: result.rows[0].cd_conhecimento_candidato });
  } catch (err) {
    console.error('Erro ao cadastrar conhecimento:', err);
    logger.error  ('Erro ao cadastrar conhecimento: ' + err.stack, 'candidato-conhecimento');  
    res.status(500).json({ erro: 'Erro ao cadastrar conhecimento do candidato.', motivo: err.message });
  }
});

router.put('/alterar/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;
  const campos = ['cd_conhecimento', 'descricao_conhecimento', 'cd_nivel_conhecimento'];
  const updateFields = [];
  const updateValues = [];
  const { cd_conhecimento } = req.body;

  campos.forEach((campo) => {
    if (req.body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(req.body[campo]);
    }
  });

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  updateFields.push(`data_atualizacao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);

  updateValues.push(id);

   // Buscar cd_candidato original
  let cd_candidato;
  try {
    const busca = await pool.query(
      'SELECT cd_candidato FROM public.candidato_conhecimento WHERE cd_conhecimento_candidato = $1',
      [id]
    );
    if (busca.rowCount === 0) {
      return res.status(404).json({ erro: 'Conhecimento não encontrado para alteração.' });
    }
    cd_candidato = busca.rows[0].cd_candidato;
  } catch (err) {
    console.error('Erro ao buscar conhecimento para alteração:', err);
    return res.status(500).json({ erro: 'Erro ao buscar conhecimento do candidato.', motivo: err.message });
  }
if (await verificarDuplicidadeConhecimento({ cd_candidato, cd_conhecimento, ignorarId: id })) {
  return res.status(400).json({ erro: 'Este conhecimento já está cadastrado para o candidato.' });
}

  const query = `
    UPDATE public.candidato_conhecimento
    SET ${updateFields.join(', ')}
    WHERE cd_conhecimento_candidato = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Conhecimento não encontrado.' });
    }

    res.status(200).json({ mensagem: 'Conhecimento atualizado com sucesso.', conhecimento: result.rows[0] });
  } catch (err) {
    console.error('Erro ao atualizar conhecimento:', err);
    logger  .error('Erro ao atualizar conhecimento: ' + err.stack, 'candidato-conhecimento'); 
    res.status(500).json({ erro: 'Erro ao atualizar conhecimento.', motivo: err.message     });
  }
});

router.delete('/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM public.candidato_conhecimento WHERE cd_conhecimento_candidato = $1 RETURNING cd_conhecimento_candidato',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Conhecimento não encontrado.' });
    }

    res.status(200).json({ mensagem: 'Conhecimento excluído com sucesso.', id: result.rows[0].cd_conhecimento_candidato });
  } catch (err) {
    console.error('Erro ao excluir conhecimento:', err);
    logger  .error('Erro ao excluir conhecimento: ' + err.stack, 'candidato-conhecimento');        
    res.status(500).json({ erro: 'Erro ao excluir conhecimento.', motivo: err.message  });
  }
});

router.get('/listar/:cd_candidato', tokenOpcional, async (req, res) => {
  const { cd_candidato } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT 
      cc.cd_conhecimento_candidato AS id,
      cc.cd_candidato,
      cc.cd_conhecimento,
      cc.descricao_conhecimento,
      cc.cd_nivel_conhecimento,
      c.descricao AS conhecimento,
      nc.descricao AS nivel_conhecimento,
      cc.data_criacao,
      cc.data_atualizacao
    FROM public.candidato_conhecimento cc
    LEFT JOIN public.conhecimento c ON c.cd_conhecimento = cc.cd_conhecimento
    JOIN public.nivel_conhecimento nc ON nc.cd_nivel_conhecimento = cc.cd_nivel_conhecimento
    WHERE cc.cd_candidato = $1
    ORDER BY cc.data_criacao DESC
  `;

  const countQuery = `SELECT COUNT(*) FROM public.candidato_conhecimento WHERE cd_candidato = $1`;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_candidato], page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao listar conhecimentos:', err);
    logger  .error('Erro ao listar conhecimentos: ' + err.stack, 'candidato-conhecimento');
    res.status(500).json({ erro: 'Erro ao listar conhecimentos do candidato.', motivo: err.message   });
  }
});

router.get('/:cd_conhecimento_candidato', verificarToken, async (req, res) => {
  const { cd_conhecimento_candidato } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT 
      cc.cd_conhecimento_candidato AS id,
      cc.cd_candidato,
      cc.cd_conhecimento,
      cc.descricao_conhecimento,
      cc.cd_nivel_conhecimento,
      c.descricao AS conhecimento,
      nc.descricao AS nivel_conhecimento,
      cc.data_criacao,
      cc.data_atualizacao,
      cc.criado_por,
      cc.atualizado_por
    FROM public.candidato_conhecimento cc
    LEFT JOIN public.conhecimento c ON c.cd_conhecimento = cc.cd_conhecimento
    JOIN public.nivel_conhecimento nc ON nc.cd_nivel_conhecimento = cc.cd_nivel_conhecimento
    WHERE cc.cd_conhecimento_candidato = $1
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.candidato_conhecimento
    WHERE cd_conhecimento_candidato = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_conhecimento_candidato], page, limit);

    if (resultado.dados.length === 0) {
      return res.status(404).json({ erro: 'Conhecimento do candidato não encontrado.' });
    }

    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao buscar conhecimento:', err);
    logger.error('Erro ao buscar conhecimento: ' + err.stack, 'candidato-conhecimento');
    res.status(500).json({ erro: 'Erro ao buscar conhecimento do candidato.', motivo  : err.message  });
  }
});


async function verificarDuplicidadeConhecimento({ cd_candidato, cd_conhecimento, ignorarId = null }) {
  let query = `
    SELECT COUNT(*) AS count
    FROM public.candidato_conhecimento
    WHERE cd_candidato = $1
      AND (
        (cd_conhecimento IS NOT DISTINCT FROM $2 AND $2 IS NOT NULL)
      )
  `;

  const values = [cd_candidato, cd_conhecimento ?? null];

  if (ignorarId) {
    query += ' AND cd_conhecimento_candidato != $3';
    values.push(ignorarId);
  }

  const result = await pool.query(query, values);

  return parseInt(result.rows[0].count) > 0;
}


module.exports = router;