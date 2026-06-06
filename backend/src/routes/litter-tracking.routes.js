const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const litterTrackingService = require("../services/litter-tracking.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[litter-tracking]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, litterTrackingService.getCurrentForUser(req.auth.userId))
);

router.get("/:litterId", requireAuth, (req, res) =>
  respond(
    res,
    litterTrackingService.getForUser(req.auth.userId, req.params.litterId)
  )
);

router.post("/", requireAuth, (req, res) =>
  respond(res, litterTrackingService.createForUser(req.auth.userId, req.body))
);

router.put("/:litterId", requireAuth, (req, res) =>
  respond(
    res,
    litterTrackingService.updateForUser(
      req.auth.userId,
      req.params.litterId,
      req.body
    )
  )
);

router.post("/:litterId/cleaning", requireAuth, (req, res) =>
  respond(
    res,
    litterTrackingService.saveCleaningForUser(
      req.auth.userId,
      req.params.litterId
    )
  )
);

router.delete("/:litterId", requireAuth, (req, res) =>
  respond(
    res,
    litterTrackingService.deleteForUser(req.auth.userId, req.params.litterId)
  )
);

module.exports = router;
