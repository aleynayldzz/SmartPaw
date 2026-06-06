const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const weightHistoryService = require("../services/weight-history.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[weight-history]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, weightHistoryService.listForUser(req.auth.userId, req.query))
);

module.exports = router;
