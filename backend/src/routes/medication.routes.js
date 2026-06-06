const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const medicationService = require("../services/medication.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[medications]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

// CRUD
router.get("/", requireAuth, (req, res) =>
  respond(res, medicationService.listForUser(req.auth.userId, req.query))
);

router.post("/", requireAuth, (req, res) =>
  respond(res, medicationService.createForUser(req.auth.userId, req.body))
);

router.put("/:medicationId", requireAuth, (req, res) =>
  respond(
    res,
    medicationService.updateForUser(
      req.auth.userId,
      req.params.medicationId,
      req.body
    )
  )
);

router.delete("/:medicationId", requireAuth, (req, res) =>
  respond(
    res,
    medicationService.deleteForUser(req.auth.userId, req.params.medicationId)
  )
);

// Schedule view (for a given date)
router.get("/schedule", requireAuth, (req, res) =>
  respond(
    res,
    medicationService.getScheduleForUser(req.auth.userId, req.query.date)
  )
);

// Mark taken for a schedule time (per day)
router.post("/:medicationId/taken", requireAuth, (req, res) =>
  respond(
    res,
    medicationService.markTakenForUser(
      req.auth.userId,
      req.params.medicationId,
      req.body
    )
  )
);

module.exports = router;

