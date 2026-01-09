// backend/utils/csv.js

// 🔹 Normaliza uma célula individual para o CSV
function sanitizeCell(val) {
  if (val === null || val === undefined) return '';

  let s = String(val);

  // ⚙️ Evita que Excel interprete como fórmula (= + - @)
  if (/^[=+\-@]/.test(s.trim())) s = "'" + s;

  // ⚙️ Remove quebras de linha e duplica aspas
  s = s.replace(/\r?\n|\r/g, ' ').replace(/"/g, '""');

  // ⚙️ Substitui ponto e vírgula por vírgula (mantém integridade do CSV)
  s = s.replace(/;/g, ',');

  // ⚙️ Adiciona aspas se houver espaços, aspas ou ponto e vírgula
  if (/[;"\s]/.test(s)) s = `"${s}"`;

  return s;
}

// 🔹 Constrói o conteúdo completo de um CSV
function buildCsv(header = [], rows = [], rowMap) {
  if (!Array.isArray(rows)) rows = [];

  // Cria cabeçalho CSV
  const headerLine = header.join(';');

  // Converte linhas em texto CSV
  const lines = rows.map(row => {
    if (!row) return ''; // ignora linhas nulas

    const values = rowMap ? rowMap(row) : Object.values(row);

    // 🧩 Diagnóstico: identifica valores undefined
    for (const v of values) {
      if (v === undefined) {
        console.error('🚨 Valor undefined detectado na linha CSV:', row);
      }
    }

    return values.map(sanitizeCell).join(';');
  });

  // Junta cabeçalho + linhas
  return [headerLine, ...lines].join('\n');
}

module.exports = { buildCsv, sanitizeCell };
