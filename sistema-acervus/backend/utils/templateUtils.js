function extrairTags(html) {
  const regex = /@[\w_]+/g;
  const matches = html.match(regex);
  return matches ? [...new Set(matches)] : [];
}

function getValorPorPath(obj, path) {
  return path.split('.').reduce((acc, part) => acc && acc[part], obj);
}

function substituirTags(modelo, dados, tags) {
  let resultado = modelo;
  tags.forEach(tagInfo => {
    console.log(  `Substituindo tag: ${tagInfo.tag} pelo valor do campo: ${tagInfo.campo}`);
    let valorCampo = getValorPorPath(dados, tagInfo.campo); // ← agora é let

   //imprimir valor do campo
   console.log(`Valor do campo ${tagInfo.campo}:`, valorCampo);

    // 🔄 Fallback para "NÃO INFORMADO"
    if (valorCampo === null || valorCampo === undefined || valorCampo.toString().trim() === '') {
      valorCampo = 'NÃO INFORMADO';
    }

    const regex = new RegExp(tagInfo.tag, 'g');
    resultado = resultado.replace(regex, valorCampo !== undefined ? valorCampo : `[${tagInfo.tag}]`);
   // console.log('resultado:', resultado);
  });
  return resultado;
}


module.exports = { extrairTags, getValorPorPath, substituirTags };
