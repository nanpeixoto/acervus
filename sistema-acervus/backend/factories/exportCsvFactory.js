const { buildCsv } = require('../utils/csv');
const pool = require('../db');

/**
 * Cria um exportador CSV flexível, compatível com UTF-8 + BOM.
 * Funciona de duas formas:
 *  - csvExporter(req, res) → executa SQL com baseQuery
 *  - csvExporter(req, res, rows) → usa dados já prontos (sem query)
 */
function createCsvExporter(config) {
  return async function handler(req, res, rowsFromRoute) {
    try {
      let rows = [];

      // 🔹 Caso 1: rota passou os dados prontos
      if (Array.isArray(rowsFromRoute)) {
        rows = rowsFromRoute;
      }
      // 🔹 Caso 2: executa a query padrão
      else {
        const { where, params } =
          config.buildWhereAndParams?.(req) || { where: '', params: [] };

        if (!config.baseQuery) {
          throw new Error('config.baseQuery não foi definido para este exportador.');
        }

        const sql = config.baseQuery.replace('{{WHERE}}', where || '');
        const result = await pool.query(sql, params);
        rows = result.rows;
      }

      // 🔹 Gera o CSV
      const csv = buildCsv(config.header, rows, config.rowMap);

      // 🔹 Adiciona BOM (Byte Order Mark) para Excel reconhecer UTF-8
      const bom = '\uFEFF';
      const csvComBOM = bom + csv;

      // 🔹 Define nome e cabeçalhos
      const ts = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
      const name = config.filename?.(req) || `export-${ts}.csv`;

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="${name}"`
      );

      // 🔹 Envia conteúdo
      res.status(200).send(csvComBOM);
    } catch (err) {
      console.error('Erro ao exportar CSV:', err);
      res
        .status(500)
        .json({ erro: 'Erro ao exportar CSV', motivo: err.message });
    }
  };
}

module.exports = { createCsvExporter };
