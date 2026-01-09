const express = require('express');
const router = express.Router();
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');

// Endpoint para verificar se o token é válido
router.get('/token/validar', verificarToken, (req, res) => {
  res.status(200).json({
    mensagem: 'Token válido.',
    usuario: req.usuario // Retorna os dados decodificados do token
  });
});

module.exports = router;
