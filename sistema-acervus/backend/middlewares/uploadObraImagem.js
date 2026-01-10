const multer = require('multer');
const fs = require('fs');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const { cdObra } = req.params;

    const dir = path.join(
      __dirname,
      '..',
      'uploads',
      'obras',
      String(cdObra)
    );

    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },

  filename: (req, file, cb) => {
    const isCapa =
      req.body.sts_principal === 'true' ||
      req.body.sts_principal === '1';

    const prefix = isCapa ? 'capa' : 'galeria';
    const ext = path.extname(file.originalname);
    const nome = `${prefix}_${Date.now()}${ext}`;

    cb(null, nome);
  },
});

module.exports = multer({ storage });
