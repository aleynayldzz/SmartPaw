const express = require("express");
const { requireAuth } = require("../middleware/auth.middleware");
const catService = require("../services/cat.service");

const router = express.Router();

async function respond(res, pending) {
  try {
    const { statusCode, json } = await pending;
    res.status(statusCode).json(json);
  } catch (err) {
    console.error("[cats]", err?.message || err);
    if (err && err.code) console.error("[cats] code:", err.code);
    res.status(500).json({
      ok: false,
      message: "Internal server error.",
      detail:
        process.env.NODE_ENV !== "production" && err?.message
          ? String(err.message)
          : undefined
    });
  }
}

/** Irk listesi (giriş gerekmez; mobil uygulama dropdown için). */
router.get("/breeds", (req, res) => respond(res, catService.listBreeds()));

router.get("/", requireAuth, (req, res) =>
  respond(res, catService.listCats(req.auth.userId))
);

router.post("/", requireAuth, (req, res) =>
  respond(res, catService.createCat(req.auth.userId, req.body))
);

router.get("/:catId", requireAuth, (req, res) =>
  respond(res, catService.getCat(req.auth.userId, req.params.catId))
);

router.patch("/:catId", requireAuth, (req, res) =>
  respond(res, catService.updateCat(req.auth.userId, req.params.catId, req.body))
);

router.delete("/:catId", requireAuth, (req, res) =>
  respond(res, catService.deleteCat(req.auth.userId, req.params.catId))
);

module.exports = router;
