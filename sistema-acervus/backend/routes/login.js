const express = require('express');
const router = express.Router();
const md5 = require('md5');            // ideal: trocar por bcrypt
const pool = require('../db');
const jwt = require('jsonwebtoken');

router.post('/login', async (req, res) => {
  const { login, senha } = req.body;

  if (!login || !senha) {
    return res.status(400).json({ erro: 'Login e senha são obrigatórios.' });
  }

  try {
    const sqlUsuario = `
      SELECT
        cd_usuario,
        nome,
        login,
        email,
        perfil,
        ativo,
        senha
      FROM public.usuarios
      WHERE login = $1 OR email = $1
      LIMIT 1
    `;

    const result = await pool.query(sqlUsuario, [login]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    const usuario = result.rows[0];

    if (!usuario.ativo) {
      return res.status(403).json({ erro: 'Usuário está inativo.' });
    }

    if (usuario.senha !== md5(senha)) {
      return res.status(401).json({ erro: 'Senha incorreta.' });
    }

    // Payload JWT SIMPLES (e correto para o Acervus)
    const payload = {
      tipo: 'usuario',
      cd_usuario: usuario.cd_usuario,
      perfil: usuario.perfil
    };

    const token = jwt.sign(
      payload,
      process.env.JWT_SECRET || 'segredo_superseguro',
      { expiresIn: '1d' }
    );

    delete usuario.senha;

    return res.json({
      mensagem: 'Login realizado com sucesso.',
      usuario,
      token
    });

  } catch (err) {
    console.error('Erro ao autenticar:', err);
    return res
      .status(500)
      .json({ erro: 'Erro ao autenticar. Tente novamente mais tarde.' });
  }
});


// POST /adm/logout
router.post('/logout', (req, res) => {
  // Em JWT, o logout é no client (remover o token)
  res.status(200).json({ mensagem: 'Logout realizado. Apague o token JWT no cliente.' });
});

module.exports = router;
