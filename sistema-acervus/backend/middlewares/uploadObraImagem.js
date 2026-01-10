const multer = require('multer');
const fs = require('fs');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const cdObra = parseInt(req.params.obraId || req.params.cdObra, 10);

    if (!cdObra) {
      return cb(new Error('cdObra não informado'), null);
    }

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
      req.body.sts_principal === '1' ||
      req.body.sts_principal === true;

    const prefix = isCapa ? 'capa' : 'galeria';
    const ext = path.extname(file.originalname);
    cb(null, `${prefix}_${Date.now()}${ext}`);
  },
});

// ✅ ISSO É O MAIS IMPORTANTE
module.exports = multer({ storage });
