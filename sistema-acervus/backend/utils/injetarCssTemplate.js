function injetarCssTemplate(html) {
  const css = `
    <style>
      .ql-align-center {
        text-align: center !important;
      }
      .ql-align-right {
        text-align: right !important;
      }
      .ql-align-left {
        text-align: left !important;
      }
      .ql-align-justify {
        text-align: justify !important;
      }
      img.ql-image {
        max-width: 50px !important;
        height: auto !important;
        display: block;
        margin: 10px auto;
      }
      .page-break {
        page-break-after: always;
      }
    </style>
  `;

  // Adiciona antes de </head>, se existir
  if (html.includes('</head>')) {
    return html.replace('</head>', `${css}</head>`);
  } else {
    // Se não tiver head, apenas concatena no final
    return html + css;
  }
}

 

module.exports = { injetarCssTemplate };
