const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const foodTrackingService = require("../services/food-tracking.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[food-tracking]", err?.message || err);
    res.status(500).json({ ok: false, message: "Internal server error." });
  }
}

router.get("/", requireAuth, (req, res) =>
  respond(res, foodTrackingService.getCurrentForUser(req.auth.userId))
);

router.get("/:foodId", requireAuth, (req, res) =>
  respond(res, foodTrackingService.getForUser(req.auth.userId, req.params.foodId))
);

router.post("/", requireAuth, (req, res) =>
  respond(res, foodTrackingService.createForUser(req.auth.userId, req.body))
);

router.put("/:foodId", requireAuth, (req, res) =>
  respond(
    res,
    foodTrackingService.updateForUser(
      req.auth.userId,
      req.params.foodId,
      req.body
    )
  )
);

router.post("/:foodId/replace", requireAuth, (req, res) =>
  respond(
    res,
    foodTrackingService.replacePackageForUser(
      req.auth.userId,
      req.params.foodId,
      req.body
    )
  )
);

router.delete("/:foodId", requireAuth, (req, res) =>
  respond(
    res,
    foodTrackingService.deleteForUser(req.auth.userId, req.params.foodId)
  )
);

module.exports = router;
