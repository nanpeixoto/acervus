const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');


router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const { cd_candidato, nome_empresa, data_inicio, data_fim, atividades } = req.body;

  if (!cd_candidato  )  {
    return res.status(400).json({ erro: 'Cód do Candidato não preenchidos.' });
  }

 

     if (!nome_empresa ) {
    return res.status(400).json({ erro: 'Nome da Empresa é obrigatório.' });
  }

  
     if (!atividades ) {
    return res.status(400).json({ erro: 'Atividades é obrigatório.' });
  }

  
     if (!data_inicio ) {
    return res.status(400).json({ erro: 'Data de Inicio é obrigatório.' });
  }



  const criado_por = req.usuario?.cd_usuario || null;

  try {
    const query = `
      INSERT INTO public.candidato_experiencia (
        cd_candidato, nome_empresa, data_inicio, data_fim, atividades,
        data_criacao, criado_por
      ) VALUES ($1, $2, $3, $4, $5, NOW(), $6)
      RETURNING cd_experiencia_candidato
    `;

    const result = await pool.query(query, [cd_candidato, nome_empresa, data_inicio, data_fim, atividades, criado_por]);
    res.status(201).json({
      mensagem: 'Experiência cadastrada com sucesso.',
      cd_experiencia_candidato: result.rows[0].cd_experiencia_candidato
    });
  } catch (err) {
    console.error('Erro ao cadastrar experiência:', err);
    logger.error('Erro ao cadastrar experiência: ' + err.stack, 'candidato-experiencia');
    res.status(500).json({ erro: 'Erro ao cadastrar experiência profissional.', motivo: err.message });
  }
});


router.put('/alterar/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;
  const campos = ['nome_empresa', 'data_inicio', 'data_fim', 'atividades'];
  const updateFields = [];
  const updateValues = [];

  campos.forEach(campo => {
    if (req.body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(req.body[campo]);
    }
  });

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(req.usuario?.cd_usuario || null);

  updateFields.push(`data_atualizacao = NOW()`);

  updateValues.push(id);

  const query = `
    UPDATE public.candidato_experiencia
    SET ${updateFields.join(', ')}
    WHERE cd_experiencia_candidato = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Experiência não encontrada.' });
    }

    res.status(200).json({
      mensagem: 'Experiência atualizada com sucesso.',
      experiencia: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao atualizar experiência:', err);
    logger.error('Erro ao atualizar experiência: ' + err.stack, 'candidato-experiencia');
    res.status(500).json({ erro: 'Erro ao atualizar experiência profissional.', motivo: err.message });
  }
});


router.get('/listar/:cd_candidato', tokenOpcional, async (req, res) => {
  const { cd_candidato } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT 
      ce.cd_experiencia_candidato AS id,
      ce.cd_candidato,
      ce.nome_empresa,
      ce.data_inicio,
      ce.data_fim,
      ce.atividades,
      ce.data_criacao,
      ce.data_atualizacao,
      ce.criado_por,
      ce.atualizado_por
    FROM public.candidato_experiencia ce
    WHERE ce.cd_candidato = $1
    ORDER BY ce.data_inicio DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.candidato_experiencia
    WHERE cd_candidato = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_candidato], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao buscar experiências: ' + err.stack, 'candidato-experiencia');
    res.status(500).json({ erro: 'Erro ao buscar experiências do candidato.', motivo: err.message });
  }
});

router.delete('/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM public.candidato_experiencia WHERE cd_experiencia_candidato = $1 RETURNING cd_experiencia_candidato',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Experiência não encontrada.' });
    }

    res.status(200).json({
      mensagem: 'Experiência excluída com sucesso.',
      id: result.rows[0].cd_experiencia_candidato
    });
  } catch (err) {
    console.error('Erro ao excluir experiência:', err);
    res.status(500).json({ erro: 'Erro ao excluir experiência profissional.', motivo  : err.message });
  }
});

router.get('/:cd_experiencia_candidato', verificarToken, async (req, res) => {
  const { cd_experiencia_candidato } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT 
      ce.cd_experiencia_candidato AS id,
      ce.cd_candidato,
      ce.nome_empresa,
      ce.data_inicio,
      ce.data_fim,
      ce.atividades,
      ce.data_criacao,
      ce.data_atualizacao,
      ce.criado_por,
      ce.atualizado_por
    FROM public.candidato_experiencia ce
    WHERE ce.cd_experiencia_candidato = $1
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.candidato_experiencia
    WHERE cd_experiencia_candidato = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_experiencia_candidato], page, limit);

    if (resultado.dados.length === 0) {
      return res.status(404).json({ erro: 'Experiência do candidato não encontrada.' });
    }

    res.status(200).json(resultado);
  } catch (err) {
    console.error ('Erro ao buscar experiência:', err);
    logger.error('Erro ao buscar experiência: ' + err.stack, 'candidato-experiencia');
    res.status(500).json({ erro: 'Erro ao buscar experiência do candidato.', motivo:  err.message  });
  }
});
 

module.exports = router;