const path = require("node:path");

const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const app = express();

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

app.get("/api", (_req, res) => {
  res.status(200).json({ message: "SmartPaw API" });
});

app.get("/api/ping", (req, res) => {
  res.status(200).json({
    ok: true,
    message: "pong",
    method: req.method,
    path: req.path,
    at: new Date().toISOString()
  });
});

app.post("/api/echo", (req, res) => {
  res.status(200).json({
    ok: true,
    query: req.query,
    body: req.body
  });
});

const basePort = Number(process.env.PORT) || 3001;

function startServer(port, attemptsLeft = 10) {
  const server = app.listen(port, () => {
    console.log(`SmartPaw backend listening on http://localhost:${port}`);
  });

  server.on("error", (err) => {
    if (err && err.code === "EADDRINUSE" && attemptsLeft > 0) {
      server.close(() => startServer(port + 1, attemptsLeft - 1));
      return;
    }
    throw err;
  });
}

startServer(basePort);

//test endpoint
app.get('/api', (req, res) => {
  res.json({ message: 'SmartPaw API' });
});

