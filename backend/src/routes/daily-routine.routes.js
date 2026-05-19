const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const dailyRoutineService = require("../services/daily-routine.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[daily-routine]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, dailyRoutineService.getRoutine(req.auth.userId, req.query.date))
);

router.put("/", requireAuth, (req, res) =>
  respond(res, dailyRoutineService.putRoutineTask(req.auth.userId, req.body))
);

module.exports = router;
