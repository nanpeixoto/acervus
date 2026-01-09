const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');


router.put('/alterar/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;

  // Campos que podem ser atualizados
  const campos = ['cd_idioma', 'cd_nivel_conhecimento', 'cd_candidato'];
  const updateFields = [];
  const updateValues = [];

  campos.forEach((campo) => {
    if (req.body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(req.body[campo]);
    }

    console .log(`Campo: ${campo}, Valor: ${req.body[campo]}`);
     if (campo== 'cd_candidato') {
      cd_candidato = req.body[campo];
      console.log('cd_candidato:', cd_candidato);
    }

     if (campo== 'cd_idioma') {
      cd_idioma = req.body[campo];
      console.log('cd_idioma:', cd_idioma);
    }
  });

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }


    // Verificação para garantir que o idioma não é duplicado para o mesmo candidato
  if (cd_candidato && cd_idioma) {
    const checkQuery = `
      SELECT COUNT(*) AS count
      FROM public.candidato_idioma
      WHERE cd_candidato = $1
        AND cd_idioma = $2
        AND cd_idioma_candidato != $3
    `;
    const checkValues = [cd_candidato, cd_idioma, id];
    const checkResult = await pool.query(checkQuery, checkValues);

    if (checkResult.rows[0].count > 0) {
      return res.status(400).json({ erro: 'Este idioma já está cadastrado para o candidato.' });
    }
  }


  // Auditoria
  const userId = req.usuario?.cd_usuario || req.body.atualizado_por || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  updateFields.push(`data_atualizacao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);

  // WHERE
  updateValues.push(id);

  const query = `
    UPDATE public.candidato_idioma
    SET ${updateFields.join(', ')}
    WHERE cd_idioma_candidato = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Idioma do candidato não encontrado.' });
    }

    res.status(200).json({
      mensagem: 'Idioma atualizado com sucesso.',
      idioma: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao atualizar idioma:', err);
    logger.error('Erro ao atualizar idioma: ' + err.stack, 'candidato-idioma');
    res.status(500).json({ erro: 'Erro ao atualizar idioma do candidato.', motivo : err.message });
  }
});


router.delete('/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM public.candidato_idioma WHERE cd_idioma_candidato = $1 RETURNING cd_idioma_candidato',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Idioma do candidato não encontrado.' });
    }

    res.status(200).json({
      mensagem: 'Idioma do candidato excluído com sucesso.',
      cd_idioma_candidato: result.rows[0].cd_idioma_candidato
    });
  } catch (error) {
    console.error('Erro ao excluir idioma do candidato:', error);
    res.status(500).json({ erro: 'Erro ao excluir idioma do candidato.' });
  }
});

router.get('/listar/:cd_candidato', tokenOpcional, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const offset = (page - 1) * limit;
  const { cd_candidato } = req.params;

  console.log("Código do candidato:", cd_candidato);

  const baseQuery = `
    SELECT 
      ci.cd_idioma_candidato AS id,
      ci.cd_candidato,
      ci.cd_idioma,
      ci.cd_nivel_conhecimento,
      i.descricao AS idioma,
      nc.descricao AS nivel_conhecimento,
      ci.data_criacao,
      ci.data_atualizacao,
      ci.criado_por,
      ci.atualizado_por
    FROM public.candidato_idioma ci
    JOIN public.idioma i ON i.cd_idioma = ci.cd_idioma
    JOIN public.nivel_conhecimento nc ON nc.cd_nivel_conhecimento = ci.cd_nivel_conhecimento
    WHERE ci.cd_candidato = $1
    ORDER BY ci.data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.candidato_idioma
    WHERE cd_candidato = $1
  `;

  const valores = [cd_candidato];

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar idiomas do candidato:', err);
    logger.error('Erro ao buscar idiomas do candidato: ' + err.stack, 'candidato-idioma');
    res.status(500).json({ erro: 'Erro ao buscar idiomas do candidato.', motivo  : err.message  });
  }
});


router.get('/:cd_idioma_candidato', verificarToken, async (req, res) => {
  const { cd_idioma_candidato } = req.params;

  try {
    const query = `
      SELECT 
        ci.cd_idioma_candidato AS id,
        ci.cd_candidato,
        ci.cd_idioma,
        ci.cd_nivel_conhecimento,
        ci.data_criacao,
        ci.data_atualizacao,
        ci.criado_por,
        ci.atualizado_por,
        i.descricao AS idioma,
        n.descricao AS nivel_conhecimento
      FROM public.candidato_idioma ci
      JOIN public.idioma i ON i.cd_idioma = ci.cd_idioma
      JOIN public.nivel_conhecimento n ON n.cd_nivel_conhecimento = ci.cd_nivel_conhecimento
      WHERE ci.cd_idioma_candidato = $1
    `;

    console.log("Buscando idioma do candidato com ID: %s", cd_idioma_candidato);
    const result = await pool.query(query, [cd_idioma_candidato]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Idioma do candidato não encontrado.' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar idioma do candidato:', err);
    logger.error('Erro ao buscar idioma do candidato: ' + err.stack, 'candidato-idioma');
    res.status(500).json({ erro: 'Erro ao buscar idioma do candidato.', motivo: err.message });
  }
});

router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    cd_candidato,
    cd_idioma,
    cd_nivel_conhecimento,
    criado_por
  } = req.body;

  // Validação básica
  if (!cd_candidato) {
    return res.status(400).json({ erro: 'Código do candidato é obrigatório.' });
  }

  if (!cd_idioma) {
    return res.status(400).json({ erro: 'Código do idioma é obrigatório.' });
  }

  if (!cd_nivel_conhecimento) {
    return res.status(400).json({ erro: 'Código do nível de conhecimento é obrigatório.' });
  }



  const checkQuery = `
  SELECT COUNT(*) AS count
  FROM public.candidato_idioma
  WHERE cd_candidato = $1
    AND cd_idioma = $2
`;

const checkValues = [cd_candidato, cd_idioma];
const checkResult = await pool.query(checkQuery, checkValues);

if (checkResult.rows[0].count > 0) {
  return res.status(400).json({ erro: 'Este idioma já está cadastrado para o candidato.' });
}

  try {
    const query = `
      INSERT INTO public.candidato_idioma (
        cd_candidato,
        cd_idioma,
        cd_nivel_conhecimento,
        data_criacao,
        criado_por
      ) VALUES ($1, $2, $3, NOW(), $4)
      RETURNING cd_idioma_candidato
    `;

    const values = [
      cd_candidato,
      cd_idioma,
      cd_nivel_conhecimento,
      criado_por || req.usuario?.cd_usuario || null
    ];

    const result = await pool.query(query, values);

    res.status(201).json({
      mensagem: 'Idioma do candidato cadastrado com sucesso.',
      cd_idioma_candidato: result.rows[0].cd_idioma_candidato
    });
  } catch (err) {
    console.error('Erro ao cadastrar idioma do candidato:', err);
    logger.error('Erro ao cadastrar idioma do candidato: ' + err.stack, 'candidato-idioma');
    res.status(500).json({ erro: 'Erro ao cadastrar idioma do candidato.' , motivo    : err.message   });
  }
});


module.exports = router;