const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const vetVisitService = require("../services/vet-visit.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[vet-visits]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, vetVisitService.listForUser(req.auth.userId))
);

router.post("/", requireAuth, (req, res) =>
  respond(res, vetVisitService.createForUser(req.auth.userId, req.body))
);

router.put("/:visitId", requireAuth, (req, res) =>
  respond(
    res,
    vetVisitService.updateForUser(
      req.auth.userId,
      req.params.visitId,
      req.body
    )
  )
);

router.delete("/:visitId", requireAuth, (req, res) =>
  respond(
    res,
    vetVisitService.deleteForUser(req.auth.userId, req.params.visitId)
  )
);

module.exports = router;
