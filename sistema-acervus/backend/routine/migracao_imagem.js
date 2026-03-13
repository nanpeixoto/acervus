require('dotenv').config({ path: '../.env' });
const fs = require('fs');
const path = require('path');
const pool = require('../db');

async function migrarImagens() {

  const logFile = path.join(__dirname, 'migracao_imagens.log');

  const log = (msg) => {
    console.log(msg);
    fs.appendFileSync(logFile, msg + '\n');
  };

  try {

    const result = await pool.query(`
      SELECT id, cd_obra, arquivo, extensao
      FROM ace_obra_galeria
      WHERE imagem IS NOT NULL
    `);

    log(`Total de registros encontrados: ${result.rowCount}`);

    let sucesso = 0;
    let erro = 0;

    for (const row of result.rows) {

      const { id, cd_obra, arquivo, extensao } = row;

      try {

        const img = await pool.query(
          `SELECT lo_get($1) as imagem`,
          [arquivo]
        );

        const buffer = img.rows[0].imagem;

        if (!buffer) {
          log(`ERRO id=${id} → imagem vazia`);
          erro++;
          continue;
        }

        const dir = path.join(__dirname, '..', 'uploads', 'obras', String(cd_obra));

        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }

        const ext = (extensao || 'image/jpeg').split('/')[1] || 'jpg';
        const filename = `galeria_${id}.${ext}`;

        const filepath = path.join(dir, filename);

        if (fs.existsSync(filepath)) {
          log(`IGNORADO id=${id} → arquivo já existe`);
          continue;
        }

        fs.writeFileSync(filepath, buffer);

        await pool.query(`
          UPDATE ace_obra_galeria
          SET nome = $1,
              imagem = NULL
          WHERE id = $2
        `, [filename, id]);

        log(`OK id=${id} → ${filename}`);

        sucesso++;

      } catch (errRegistro) {

        log(`ERRO id=${id} → ${errRegistro.message}`);
        erro++;

      }

    }

    log(`\n===== MIGRAÇÃO FINALIZADA =====`);
    log(`Sucesso: ${sucesso}`);
    log(`Erro: ${erro}`);

  } catch (err) {

    console.error('Erro geral:', err);

  } finally {

    await pool.end();

  }

}

migrarImagens();