// helpers/paginador.js

async function paginarConsulta(pool, baseQuery, countQuery, filtros, page, limit) {
  const offset = (page - 1) * limit;

  // 1. Total de itens
  const totalResult = await pool.query(countQuery, filtros);
  const totalItems = parseInt(totalResult.rows[0].count);
  const totalPages = Math.ceil(totalItems / limit);


    console.log('🧪 VALORES para contagem:', filtros);
console.log('🧪 VALORES para dados paginados:', [...filtros, limit, offset]);

  // 2. Dados paginados
  const valoresComLimite = [...filtros, limit, offset];
  
  const dadosResult = await pool.query(`${baseQuery} LIMIT $${valoresComLimite.length - 1} OFFSET $${valoresComLimite.length}`, valoresComLimite);
  console.log("QUERY::: "+baseQuery);
  return {
    dados: dadosResult.rows,
    pagination: {
      currentPage: page,
      totalPages,
      totalItems,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1
    }
  };
}




async function paginarConsultaComEndereco(pool, baseQuery, countQuery, valores, page, limit) {
  const offset = (page - 1) * limit;

    // Prepara valores e parâmetros
  const valoresComLimite = [...valores, limit, offset];
   const where = valores.length ;
  const paramLimit = valores.length + 1;
  const paramOffset = valores.length + 2;

  console.log( `🧪 where : $${where} `);
  console.log('🧪 VALORES para contagem:', valores);
console.log('🧪 VALORES para dados paginados:', [...valores, limit, offset]);
console.log('📄 QUERY COUNT:', countQuery);

  // Total de itens
    const totalResult = await pool.query(countQuery, valores);
  const totalItems = parseInt(totalResult.rows[0]?.count || '0', 10);
  const totalPages = Math.ceil(totalItems / limit);



  // Adiciona LIMIT e OFFSET na baseQuery
  const queryFinal = `${baseQuery} LIMIT $${paramLimit} OFFSET $${paramOffset}`;

  console.log('📄 QUERY FINAL:', queryFinal);
  console.log('📦 VALORES COM LIMIT E OFFSET:', valoresComLimite);

  // Executa query
  const dadosResult = await pool.query(queryFinal, valoresComLimite);

  // Monta objeto com endereço
  const dadosComEndereco = dadosResult.rows.map(row => ({
    ...row,
    endereco: {
      cep: row.cep,
      logradouro: row.logradouro,
      numero: row.numero,
      bairro: row.bairro,
      cidade: row.cidade,
      estado: row.uf,
      complemento: row.complemento
    }
  }));

  return {
    dados: dadosComEndereco,
    pagination: {
      currentPage: page,
      totalPages,
      totalItems,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1
    }
  };
}


module.exports = {
  paginarConsulta,
  paginarConsultaComEndereco: paginarConsultaComEndereco
};