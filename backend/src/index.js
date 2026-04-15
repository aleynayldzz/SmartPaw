const path = require("node:path");

const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const { Pool } = require("pg");
const bcrypt = require("bcrypt");

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const app = express();

app.use(cors());
app.use(express.json({ limit: "1mb" }));

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

const hasDbConfig =
  isNonEmptyString(process.env.DB_HOST) &&
  isNonEmptyString(process.env.DB_PORT) &&
  isNonEmptyString(process.env.DB_USER) &&
  isNonEmptyString(process.env.DB_PASSWORD) &&
  isNonEmptyString(process.env.DB_DATABASE);

const pool = hasDbConfig
  ? new Pool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: String(process.env.DB_PASSWORD),
      database: process.env.DB_DATABASE
    })
  : null;

if (!pool) {
  console.warn(
    "Database is not configured. Create backend/.env with DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_DATABASE."
  );
}

function isValidEmail(email) {
  if (typeof email !== "string") return false;
  // pragmatic email validation; leave strict validation to mail delivery
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

function isValidPassword(password) {
  if (typeof password !== "string") return false;
  const trimmed = password;
  if (trimmed.length < 8) return false;
  if (!/[A-Z]/.test(trimmed)) return false;
  if (!/[a-z]/.test(trimmed)) return false;
  if (!/[^A-Za-z0-9]/.test(trimmed)) return false;
  return true;
}

function generateVerificationCode() {
  // 6-digit numeric string
  return String(Math.floor(100000 + Math.random() * 900000));
}

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

// Signup
app.post("/api/auth/signup", async (req, res) => {
  try {
    if (!pool) {
      return res.status(500).json({
        ok: false,
        message:
          "Database is not configured. Please create backend/.env and set DB_* variables."
      });
    }

    const { name, surname, email, password, confirmPassword } = req.body ?? {};

    const errors = {};

    if (!isNonEmptyString(name)) errors.name = "Name is required.";
    if (!isNonEmptyString(surname)) errors.surname = "Surname is required.";

    if (!isNonEmptyString(email)) {
      errors.email = "Email is required.";
    } else if (!isValidEmail(email)) {
      errors.email = "Email format is invalid.";
    }

    if (!isNonEmptyString(password)) {
      errors.password = "Password is required.";
    } else if (!isValidPassword(password)) {
      errors.password =
        "Password must be at least 8 characters long and include uppercase, lowercase, and a special character.";
    }

    if (!isNonEmptyString(confirmPassword)) {
      errors.confirmPassword = "Confirm Password is required.";
    } else if (password !== confirmPassword) {
      errors.confirmPassword = "Confirm Password must match Password.";
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        ok: false,
        message: "Validation failed.",
        errors
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const passwordHash = await bcrypt.hash(password, 12);

    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      const insertedUserRes = await client.query(
        `
        INSERT INTO users (name, surname, email, password_hash, is_verified, avatar_gender)
        VALUES ($1, $2, $3, $4, false, 'unspecified')
        RETURNING user_id, email, is_verified
        `,
        [name.trim(), surname.trim(), normalizedEmail, passwordHash]
      );

      const createdUser = insertedUserRes.rows[0];

      await client.query(
        `
        INSERT INTO verification_codes (user_id, code, purpose, expires_at, is_used)
        VALUES ($1, $2, 'email_verification', $3, false)
        `,
        [createdUser.user_id, code, expiresAt]
      );

      await client.query("COMMIT");

      // NOTE: Sending the code back is useful for development. In production, send via email/SMS instead.
      return res.status(201).json({
        ok: true,
        message: "Registration successful. Please verify your email.",
        data: {
          user_id: createdUser.user_id,
          email: createdUser.email,
          is_verified: createdUser.is_verified,
          next: "verification_code",
          dev_verification_code: code
        }
      });
    } catch (e) {
      await client.query("ROLLBACK");
      throw e;
    } finally {
      client.release();
    }
  } catch (err) {
    // Handle unique constraint (email) gracefully
    if (err && err.code === "23505") {
      return res.status(409).json({
        ok: false,
        message: "An account with this email already exists.",
        errors: { email: "Email already exists." }
      });
    }
    console.error(err);
    return res.status(500).json({ ok: false, message: "Internal server error." });
  }
});

// Verify email with code
app.post("/api/auth/verify-email", async (req, res) => {
  try {
    if (!pool) {
      return res.status(500).json({
        ok: false,
        message:
          "Database is not configured. Please create backend/.env and set DB_* variables."
      });
    }

    const { email, code } = req.body ?? {};
    const errors = {};

    if (!isNonEmptyString(email)) {
      errors.email = "Email is required.";
    } else if (!isValidEmail(email)) {
      errors.email = "Email format is invalid.";
    }

    if (!isNonEmptyString(code)) errors.code = "Verification code is required.";

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({ ok: false, message: "Validation failed.", errors });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const userRes = await pool.query(
      `SELECT user_id, email, is_verified FROM users WHERE lower(email) = $1 LIMIT 1`,
      [normalizedEmail]
    );
    const user = userRes.rows[0];

    if (!user) {
      return res.status(404).json({ ok: false, message: "User not found." });
    }

    if (user.is_verified) {
      return res.status(200).json({
        ok: true,
        message: "Account is already verified.",
        data: { is_verified: true }
      });
    }

    const now = new Date();
    const verificationRes = await pool.query(
      `
      SELECT code_id, code, expires_at, is_used
      FROM verification_codes
      WHERE user_id = $1
        AND purpose = 'email_verification'
        AND is_used = false
        AND expires_at > $2
      ORDER BY created_at DESC
      LIMIT 1
      `,
      [user.user_id, now]
    );
    const verificationRow = verificationRes.rows[0];

    if (!verificationRow || String(verificationRow.code) !== String(code).trim()) {
      return res.status(400).json({
        ok: false,
        message: "Invalid or expired verification code.",
        errors: { code: "Invalid or expired verification code." }
      });
    }

    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query(`UPDATE verification_codes SET is_used = true WHERE code_id = $1`, [
        verificationRow.code_id
      ]);
      await client.query(`UPDATE users SET is_verified = true WHERE user_id = $1`, [
        user.user_id
      ]);
      await client.query("COMMIT");
    } catch (e) {
      await client.query("ROLLBACK");
      throw e;
    } finally {
      client.release();
    }

    return res.status(200).json({
      ok: true,
      message: "Email verified successfully.",
      data: { is_verified: true }
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ ok: false, message: "Internal server error." });
  }
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
