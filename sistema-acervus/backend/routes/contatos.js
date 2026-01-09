const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

// Função reutilizável para cadastro de contato
async function cadastrarContato(
  contato,
  cd_candidato = null,
  cd_usuario = null,
  cd_instituicao_ensino = null, 
  client = pool
) {
  const {
    nome,
    grau_parentesco,
    telefone,
    celular,
    whatsapp,
    principal = true
  } = contato;

  if (!cd_candidato ) {
    throw new Error('Campos obrigatórios: cd_candidato ');
  }

  if (!nome || !grau_parentesco) {
    return null;
  } 

  const shouldRelease = !client;
  const executor = shouldRelease ? await pool.connect() : client;

  try {
    await executor.query('BEGIN');

    if (principal) {
      await executor.query(
        'UPDATE public.contatos SET principal = false WHERE cd_candidato = $1',
        [cd_candidato]
      );
    }

    const insertQuery = `
      INSERT INTO public.contatos
        (cd_candidato, nome, grau_parentesco, telefone, celular, whatsapp, principal)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;

    const { rows } = await executor.query(insertQuery, [
      cd_candidato,
      nome,
      grau_parentesco,
      telefone,
      celular,
      whatsapp,
      principal
    ]);

    await executor.query('COMMIT');
    return rows[0];
  } catch (error) {
    await executor.query('ROLLBACK');
    logger.error('Erro ao cadastrar contato: ' + error.stack, 'contatos');
    throw new Error('Erro ao cadastrar contato no banco de dados.');
  } finally {
    if (shouldRelease && executor.release) {
      executor.release();
    }
  }
}

// Cadastro via rota
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { cd_candidato, nome, grau_parentesco, telefone, celular, whatsapp, principal = true } = req.body;

  try {
  const novoContato = await cadastrarContato(
    {
      nome,
      grau_parentesco,
      telefone,
      celular,
      whatsapp,
      principal
    },
    cd_candidato,           // agora passado como parâmetro separado
    req.usuario.cd_usuario, // cd_usuario
    null                    // cd_instituicao_ensino (caso não se aplique)
  );


    res.status(201).json(novoContato);
  } catch (err) {
    console.error('Erro ao cadastrar contato:', err.message);
    res.status(400).json({ erro: err.message });
  }
});

// Listar contatos de um candidato
router.get('/listar', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { tipo, id } = req.query;

  if (!tipo || !id) {
    return res.status(400).json({ erro: 'Parâmetros obrigatórios: tipo e id.' });
  }

  let campo;
  if (tipo === 'candidato') {
    campo = 'cd_candidato';
  } else {
    return res.status(400).json({ erro: 'Tipo inválido. Use "instituicao" ou "candidato".' });
  }

  const baseQuery = `
    SELECT id, cd_candidato, nome, grau_parentesco, telefone, celular, whatsapp, principal
    FROM public.contatos
    WHERE ${campo} = $1
    ORDER BY principal DESC, nome DESC;
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.contatos WHERE ${campo} = $1;
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [id], page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar contatos:', err);
    logger.error('Erro ao buscar contatos: ' + err.stack, 'contatos');
    res.status(500).json({ erro: 'Erro ao buscar contatos.' });
  }
});

// Atualizar contato
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const contato = req.body;

  try {
    const resultado = await alterarContato(
      contato,
      id,
      req.usuario.cd_usuario
    );

    res.status(200).json({
      mensagem: 'Contato atualizado com sucesso!',
      contato: resultado
    });
  } catch (err) {
    console.error('Erro ao alterar contato:', err.message);
    res.status(400).json({ erro: err.message });
  }
});

 
async function alterarContato(
  contato,
  id,
  cd_usuario = null,
  client = pool
) {
  const {
    nome,
    grau_parentesco,
    telefone,
    celular,
    whatsapp,
    principal,
    cd_candidato
  } = contato;

  if(id==null){
    return;
  }

  if (!nome || !grau_parentesco) {
    throw new Error('Campos obrigatórios não fornecidos: nome e grau_parentesco.');
  }

     console.log('id'+id);

  if (!id) {
    if (!cd_candidato) {
      throw new Error('Campos obrigatórios: cd_candidato');
    }
    return await cadastrarContato(contato, cd_candidato, cd_usuario, client);
  }

  const shouldRelease = !client;
  const executor = shouldRelease ? await pool.connect() : client;

  try {
    await executor.query('BEGIN');

    const campos = [
      'nome',
      'grau_parentesco',
      'telefone',
      'celular',
      'whatsapp',
      'principal'
    ];

    const valores = [
      nome,
      grau_parentesco,
      telefone,
      celular,
      whatsapp,
      principal
    ];

    const setQuery = campos.map((campo, idx) => `${campo} = $${idx + 1}`).join(', ');

    const updateQuery = `
      UPDATE public.contatos
      SET ${setQuery}
      WHERE id = $${valores.length + 1}
      RETURNING *;
    `;

    const result = await executor.query(updateQuery, [...valores, id]);
    console.log('result.rowCount:'+result.rowCount)
    if (result.rowCount === 0) {
      throw new Error('Contato não encontrado para alteração.');
    }

    await executor.query('COMMIT');
    return result.rows[0];
  } catch (err) {
    await executor.query('ROLLBACK');
    logger.error('Erro ao alterar contato: ' + err.stack, 'contatos');
    throw new Error('Erro ao alterar contato no banco de dados.');
  } finally {
    if (shouldRelease) {
      executor.release();
    }
  }
}



async function alterarContato(
  contato,
  id,
  cd_usuario = null,
  client = pool
) {
  const {
    nome,
    grau_parentesco,
    telefone,
    celular,
    whatsapp,
    principal,
    cd_candidato
  } = contato;

  if (!nome || !grau_parentesco) {
    throw new Error('Campos obrigatórios não fornecidos: nome e grau_parentesco.');
  }

  if (!id) {
    if (!cd_candidato) {
      throw new Error('Campos obrigatórios: cd_candidato');
    }
    return await cadastrarContato(contato, cd_candidato, cd_usuario, client);
  }

  const shouldRelease = !client;
  const executor = shouldRelease ? await pool.connect() : client;

  try {
    await executor.query('BEGIN');

    const updateQuery = `
      UPDATE public.contatos
      SET nome = $1, grau_parentesco = $2, telefone = $3,
          celular = $4, whatsapp = $5, principal = $6
      WHERE cd_contatos = $7
      RETURNING *;
    `;

    const result = await executor.query(updateQuery, [
      nome, grau_parentesco, telefone, celular, whatsapp, principal, id
    ]);

    if (result.rowCount === 0) {
      throw new Error('Contato não encontrado para alteração.');
    }

    await executor.query('COMMIT');
    return result.rows[0];
  } catch (err) {
    await executor.query('ROLLBACK');
    logger.error('Erro ao alterar contato: ' + err.stack, 'contatos');
    throw new Error('Erro ao alterar contato: ' + err.message);
  } finally {
    if (shouldRelease) {
      executor.release();
    }
  }
}





// Remover contato
router.delete('/remover/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM public.contatos WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Contato não encontrado' });
    }

    res.json({ mensagem: 'Contato removido com sucesso' });
  } catch (error) {
    console.error('Erro ao remover contato:', error);
    res.status(500).json({ erro: 'Erro ao remover contato' });
  }
});

module.exports = {
  router,
  cadastrarContato, 
  alterarContato
};
