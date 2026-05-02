const express = require("express");
const cors = require("cors");

require("./db");

const systemRoutes = require("./routes/system.routes");
const authRoutes = require("./routes/auth.routes");

const app = express();

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.use(systemRoutes);
app.use("/api/auth", authRoutes);

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
