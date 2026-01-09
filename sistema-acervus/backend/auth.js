const jwt = require('jsonwebtoken');

function verificarToken(req, res, next) {
  // Obtém o cabeçalho de autorização
  const authHeader = req.headers.authorization;

  // Verifica se o token foi fornecido
  if (!authHeader) return res.status(401).json({ erro: 'Token não fornecido.' });

  // Extrai o token do cabeçalho "Authorization" (Bearer <token>)
  const [, token] = authHeader.split(' '); // Caso tenha "Bearer <token>"

  try {
    // Verifica se o token é válido
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'segredo_superseguro');

    // Adiciona os dados do usuário ao objeto da requisição
    req.usuario = decoded; // O decoded contém as informações do usuário

    // Continua para o próximo middleware ou rota
    next();
  } catch (err) {
    // Se o token for inválido ou expirado, retorna um erro
    return res.status(403).json({ erro: 'Token inválido ou expirado.' });
  }
  
}

function tokenOpcional(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) return next(); // Segue sem usuário

  const [, token] = authHeader.split(' ');
  if (!token) return next(); // Segue sem usuário

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'segredo_superseguro');
    req.usuario = decoded;
  } catch (err) {
    // Token inválido, mas não bloqueia
    console.warn('Token inválido, seguindo sem autenticação:', err.message);
  }

  next(); // Segue mesmo se o token for inválido
}

 
module.exports = {
  verificarToken,
  tokenOpcional
};