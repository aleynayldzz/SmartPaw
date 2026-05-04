const { verifyAccessToken } = require("../services/auth.service");

function requireAuth(req, res, next) {
  const auth = verifyAccessToken(req.headers.authorization);
  if (!auth) {
    return res.status(401).json({
      ok: false,
      message: "Unauthorized. Sign in with a valid access token."
    });
  }
  req.auth = auth;
  next();
}

module.exports = { requireAuth };
