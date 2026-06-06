const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const weeklyCareCompletionService = require("../services/weekly-care-completion.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[weekly-care-completion]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(
    res,
    weeklyCareCompletionService.getCurrentWeek(
      req.auth.userId,
      req.query.date
    )
  )
);

module.exports = router;
