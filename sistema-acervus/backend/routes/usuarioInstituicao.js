const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');

const { paginarConsulta } = require('../helpers/paginador');
const md5 = require('md5');

const perfil = 'IE';  // Valor fixo


// POST - Cadastrar usuário + vínculo (ou só vínculo)
router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    cd_usuario,
    nome,
    email,
    senha,
    cd_instituicao_ensino,
    bloqueado = false,
    recebe_email = true
  } = req.body;


  const userId = req.usuario?.cd_usuario || null ;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!cd_instituicao_ensino) {
    return res.status(400).json({ erro: 'Código da Instituição de Ensino é obrigatório.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    let usuarioId = cd_usuario;

    // Se for para criar novo usuário
    if (!usuarioId) {
      if (!nome || !email || !senha) {
        return res.status(400).json({ erro: 'Nome, Email e Senha são obrigatórios para criação de novo usuário.' });
      }

      // Verificar se já existe usuário com o mesmo email/login
      const checkUserQuery = `
        SELECT cd_usuario FROM public.usuarios
        WHERE login = $1 OR email = $1
        LIMIT 1;
      `;
      const existingUser = await client.query(checkUserQuery, [email]);

      if (existingUser.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({
          erro: 'Já existe um usuário cadastrado com este e-mail/login.'
        });
      }

      // Se passou, então cria o novo usuário
      const senhaCriptografada = await md5(senha);

      const insertUserQuery = `
        INSERT INTO public.usuarios (
          nome, login, email, senha, perfil, ativo,
          data_criacao, criado_por, cd_instituicao_ensino
        )
        VALUES ($1, $2, $3, $4, $5, true, $6, $7, $8)
        RETURNING cd_usuario;
      `;

      const userValues = [
        nome, email, email, senhaCriptografada, perfil, dataAtual, userId, cd_instituicao_ensino
      ];

      const userResult = await client.query(insertUserQuery, userValues);
      usuarioId = userResult.rows[0].cd_usuario;
    }

    // Agora cria o vínculo com a instituição
    const insertVinculoQuery = `
      INSERT INTO public.usuario_instituicao (
        cd_usuario, cd_instituicao_ensino, perfil, bloqueado, recebe_email,
        data_criacao, criado_por
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id_usuario_instituicao;
    `;

    const vinculoValues = [
      usuarioId, cd_instituicao_ensino, perfil, bloqueado, recebe_email,
      dataAtual, userId
    ];

    const vinculoResult = await client.query(insertVinculoQuery, vinculoValues);

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Usuário e vínculo criados com sucesso!',
      cd_usuario: usuarioId,
      id_usuario_instituicao: vinculoResult.rows[0].id_usuario_instituicao
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar usuário e vínculo: ' + err.stack, 'usuario_instituicao');
    res.status(500).json({ erro: 'Erro ao cadastrar usuário e vínculo. ' + err.stack});
  } finally {
    client.release();
  }
});


// GET - Listar usuários por instituição
router.get('/instituicao/listar/:cd_instituicao_ensino', tokenOpcional, async (req, res) => {
  const { cd_instituicao_ensino } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT
      u.cd_usuario,
      u.nome,
      u.email,
      ui.perfil,
      ui.bloqueado,
      ui.recebe_email,
      ui.data_criacao,
      ui.data_alteracao,
      ui.criado_por,
      ui.alterado_por
    FROM public.usuario_instituicao ui
    JOIN public.usuarios u ON ui.cd_usuario = u.cd_usuario
    WHERE ui.cd_instituicao_ensino = $1
    ORDER BY u.nome ASC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.usuario_instituicao
    WHERE cd_instituicao_ensino = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_instituicao_ensino], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao listar usuários da instituição: ' + err.stack, 'usuario_instituicao');
    res.status(500).json({ erro: 'Erro ao listar usuários da instituição.' });
  }
});

 // PUT - Alterar vínculo usuário-instituição + nome/email do usuário
router.put('/alterar/:id_usuario_instituicao', tokenOpcional, async (req, res) => {
  const { id_usuario_instituicao } = req.params;
  const {
    nome,
    email,
    bloqueado,
    recebe_email
  } = req.body;

  const userId = req.usuario?.cd_usuario || null ;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Primeiro, buscar o cd_usuario correspondente ao id_usuario_instituicao
    const selectQuery = `
      SELECT cd_usuario FROM public.usuario_instituicao
      WHERE cd_usuario = $1
    `;
    const selectResult = await client.query(selectQuery, [id_usuario_instituicao]);

    if (selectResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Vínculo não encontrado.' });
    }

    const cd_usuario = selectResult.rows[0].cd_usuario;

    // Atualizar nome e email do usuário
    const updateUsuarioQuery = `
      UPDATE public.usuarios
      SET nome = $1,
          email = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_usuario = $5;
    `;
    await client.query(updateUsuarioQuery, [nome, email, dataAtual, userId, cd_usuario]);

    // Atualizar vínculo
    const updateVinculoQuery = `
      UPDATE public.usuario_instituicao
      SET bloqueado = $1,
          recebe_email = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_usuario = $5
      RETURNING cd_usuario;
    `;
    const vinculoValues = [
      bloqueado, recebe_email, dataAtual, userId, id_usuario_instituicao
    ];

    const vinculoResult = await client.query(updateVinculoQuery, vinculoValues);

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Usuário e vínculo atualizados com sucesso!',
      id_usuario_instituicao: vinculoResult.rows[0].id_usuario_instituicao
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao atualizar vínculo e usuário: ' + err.stack, 'usuario_instituicao');
    res.status(500).json({ erro: 'Erro ao atualizar usuário e vínculo.' });
  } finally {
    client.release();
  }
});




module.exports = router;
