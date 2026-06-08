const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const authService = require("../services/auth.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error(err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.post("/signup", (req, res) => respond(res, authService.signup(req.body)));

router.post("/verify-email", (req, res) =>
  respond(res, authService.verifyEmail(req.body))
);

router.post("/login", (req, res) => respond(res, authService.login(req.body)));

/** Oturumdaki kullanıcının güncel profil alanları (ana ekran selamlaması vb.). */
router.get("/me", requireAuth, (req, res) =>
  respond(res, authService.getMe(req.auth.userId))
);

router.post("/forgot-password", (req, res) =>
  respond(res, authService.forgotPassword(req.body))
);

router.post("/verify-reset-code", (req, res) =>
  respond(res, authService.verifyResetCode(req.body))
);

router.post("/reset-password", (req, res) =>
  respond(res, authService.resetPassword(req.body))
);

router.post("/change-password", requireAuth, (req, res) =>
  respond(res, authService.changePassword(req.auth.userId, req.body))
);

module.exports = router;
