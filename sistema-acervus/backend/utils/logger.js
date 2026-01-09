const fs = require('fs');
const path = require('path');

const logDir = path.join(__dirname, '../logs');
const logFile = path.join(logDir, 'app.log');

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

function log(tipo = 'INFO', mensagem = '', contexto = '') {
  const timestamp = new Date().toISOString();
  const conteudo = `[${timestamp}] [${tipo}]${contexto ? ` [${contexto}]` : ''} ${mensagem}\n`;
  console.log(conteudo);
  fs.appendFile(logFile, conteudo, err => {
    if (err) console.error('Erro ao escrever no log:', err);
  });
}

module.exports = {
  info: (mensagem, contexto) => log('INFO', mensagem, contexto),
  warn: (mensagem, contexto) => log('WARN', mensagem, contexto),
  error: (mensagem, contexto) => log('ERROR', mensagem, contexto),
  custom: log
};
