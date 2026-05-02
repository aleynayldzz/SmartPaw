const express = require("express");

const router = express.Router();

router.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

router.get("/api", (_req, res) => {
  res.status(200).json({ message: "SmartPaw API" });
});

router.get("/api/ping", (req, res) => {
  res.status(200).json({
    ok: true,
    message: "pong",
    method: req.method,
    path: req.path,
    at: new Date().toISOString()
  });
});

router.post("/api/echo", (req, res) => {
  res.status(200).json({
    ok: true,
    query: req.query,
    body: req.body
  });
});

module.exports = router;
