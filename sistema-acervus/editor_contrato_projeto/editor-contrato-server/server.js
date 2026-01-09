
const express = require('express');
const multer = require('multer');
const mammoth = require('mammoth');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const app = express();
const port = 3000;
app.use(cors());
const upload = multer({ dest: 'uploads/' });

function htmlToEnhancedDelta(html) {
  const dom = new JSDOM(html);
  const doc = dom.window.document;
  const delta = { ops: [] };

  function addText(text, attrs = {}) {
    if (text && text.trim()) {
      delta.ops.push({ insert: text, ...(Object.keys(attrs).length ? { attributes: attrs } : {}) });
    }
  }

  function addNewLine() {
    delta.ops.push({ insert: '\n' });
  }

  function processNode(node) {
    if (node.nodeType === 3) { // text node
      addText(node.textContent);
    } else if (node.nodeType === 1) {
      const tag = node.tagName.toLowerCase();
      const children = Array.from(node.childNodes);

      if (tag === 'strong' || tag === 'b') {
        children.forEach(child => processStyled(child, { bold: true }));
      } else if (tag === 'em' || tag === 'i') {
        children.forEach(child => processStyled(child, { italic: true }));
      } else if (tag === 'u') {
        children.forEach(child => processStyled(child, { underline: true }));
      } else if (tag === 'h1') {
        children.forEach(child => processStyled(child, { header: 1 }));
        addNewLine();
      } else if (tag === 'h2') {
        children.forEach(child => processStyled(child, { header: 2 }));
        addNewLine();
      } else if (tag === 'h3') {
        children.forEach(child => processStyled(child, { header: 3 }));
        addNewLine();
      } else if (tag === 'p') {
        children.forEach(processNode);
        addNewLine();
      } else if (tag === 'li') {
        children.forEach(child => processStyled(child, { list: 'bullet' }));
        addNewLine();
      } else if (tag === 'br') {
        addNewLine();
      } else if (tag === 'img') {
        const src = node.getAttribute('src');
        if (src) delta.ops.push({ insert: { image: src } });
      } else {
        children.forEach(processNode);
      }
    }
  }

  function processStyled(node, style) {
    if (node.nodeType === 3) {
      addText(node.textContent, style);
    } else if (node.nodeType === 1) {
      Array.from(node.childNodes).forEach(child => processStyled(child, style));
    }
  }

  Array.from(doc.body.childNodes).forEach(processNode);
  return delta;
}

app.post('/upload', upload.single('arquivo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ erro: 'Nenhum arquivo enviado.' });

  try {
    const filePath = path.resolve(req.file.path);
    const result = await mammoth.convertToHtml({ path: filePath, convertImage: mammoth.images.inline() });
    fs.unlinkSync(filePath);

    const html = result.value;
    const delta = htmlToEnhancedDelta(html);

    res.json({ delta });
  } catch (err) {
    console.error(err);
    res.status(500).json({ erro: 'Erro ao converter o arquivo.' });
  }
});

app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});
