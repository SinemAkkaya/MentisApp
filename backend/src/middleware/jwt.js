// JWT doğrulama middleware'i.
// Authorization: Bearer <token> header'ından token okur,
// req.user = { id, role } yerleştirir.

const jwt = require('jsonwebtoken');

function signToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });
}

function authRequired(req, res, next) {
  const auth = req.headers.authorization || '';
  const m = auth.match(/^Bearer\s+(.+)$/i);
  if (!m) {
    return res.status(401).json({ error: 'unauthorized', message: 'Token gerekli.' });
  }
  try {
    const decoded = jwt.verify(m[1], process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'invalid_token', message: 'Token geçersiz veya süresi dolmuş.' });
  }
}

function therapistOnly(req, res, next) {
  if (req.user?.role !== 'therapist') {
    return res.status(403).json({ error: 'forbidden', message: 'Yalnızca terapist erişebilir.' });
  }
  next();
}

function clientOnly(req, res, next) {
  if (req.user?.role !== 'client') {
    return res.status(403).json({ error: 'forbidden', message: 'Yalnızca danışan erişebilir.' });
  }
  next();
}

module.exports = { signToken, authRequired, therapistOnly, clientOnly };
