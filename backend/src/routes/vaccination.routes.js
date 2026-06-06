const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const vaccinationService = require("../services/vaccination.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[vaccinations]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, vaccinationService.listForUser(req.auth.userId, req.query))
);

router.post("/", requireAuth, (req, res) =>
  respond(res, vaccinationService.createForUser(req.auth.userId, req.body))
);

router.put("/:vaccinationId", requireAuth, (req, res) =>
  respond(
    res,
    vaccinationService.updateForUser(
      req.auth.userId,
      req.params.vaccinationId,
      req.body
    )
  )
);

router.delete("/:vaccinationId", requireAuth, (req, res) =>
  respond(
    res,
    vaccinationService.deleteForUser(
      req.auth.userId,
      req.params.vaccinationId
    )
  )
);

module.exports = router;
