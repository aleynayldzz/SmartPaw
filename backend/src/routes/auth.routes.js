const express = require("express");
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

router.post("/forgot-password", (req, res) =>
  respond(res, authService.forgotPassword(req.body))
);

router.post("/reset-password", (req, res) =>
  respond(res, authService.resetPassword(req.body))
);

module.exports = router;
