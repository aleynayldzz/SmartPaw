const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { pool, dbNotConfiguredPayload } = require("../db");
const { sendVerificationEmail } = require("./email.service");
const {
  isNonEmptyString,
  isValidEmail,
  isValidPassword,
  generateVerificationCode
} = require("../utils/validators");

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (isNonEmptyString(secret)) return String(secret).trim();
  if (process.env.NODE_ENV === "production") {
    console.error("JWT_SECRET is required in production.");
  }
  return "smartpaw-dev-jwt-secret-change-me";
}

function signAccessToken(user) {
  return jwt.sign(
    {
      sub: user.user_id,
      email: user.email,
      typ: "access"
    },
    getJwtSecret(),
    { expiresIn: "7d" }
  );
}

function signRefreshToken(user) {
  return jwt.sign(
    {
      sub: user.user_id,
      typ: "refresh"
    },
    getJwtSecret(),
    { expiresIn: "30d" }
  );
}

async function signup(body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const { name, surname, email, password, confirmPassword } = body ?? {};

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
    return {
      statusCode: 400,
      json: { ok: false, message: "Validation failed.", errors }
    };
  }

  const normalizedEmail = email.trim().toLowerCase();
  const passwordHash = await bcrypt.hash(password, 12);
  const code = generateVerificationCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

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

    try {
      await sendVerificationEmail({
        toEmail: createdUser.email,
        code,
        expiresAt
      });
    } catch (mailErr) {
      console.error(mailErr);
      try {
        await pool.query(`DELETE FROM users WHERE user_id = $1`, [createdUser.user_id]);
      } catch (cleanupErr) {
        console.error(cleanupErr);
      }

      if (mailErr && mailErr.code === "SMTP_NOT_CONFIGURED") {
        return {
          statusCode: 500,
          json: {
            ok: false,
            message:
              "Email delivery is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM in backend/.env."
          }
        };
      }

      return {
        statusCode: 500,
        json: {
          ok: false,
          message:
            "We could not send the verification email. Please check SMTP settings and try again."
        }
      };
    }

    const payload = {
      ok: true,
      message: "Registration successful. Please verify your email.",
      data: {
        user_id: createdUser.user_id,
        email: createdUser.email,
        is_verified: createdUser.is_verified,
        next: "verification_code"
      }
    };

    if (process.env.NODE_ENV !== "production") {
      payload.data.dev_verification_code = code;
    }

    return { statusCode: 201, json: payload };
  } catch (e) {
    await client.query("ROLLBACK");
    if (e && e.code === "23505") {
      return {
        statusCode: 409,
        json: {
          ok: false,
          message: "An account with this email already exists.",
          errors: { email: "Email already exists." }
        }
      };
    }
    console.error(e);
    return { statusCode: 500, json: { ok: false, message: "Internal server error." } };
  } finally {
    client.release();
  }
}

async function verifyEmail(body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const { email, code } = body ?? {};
  const errors = {};

  if (!isNonEmptyString(email)) {
    errors.email = "Email is required.";
  } else if (!isValidEmail(email)) {
    errors.email = "Email format is invalid.";
  }

  if (!isNonEmptyString(code)) {
    errors.code = "Verification code is required.";
  }

  if (Object.keys(errors).length > 0) {
    return { statusCode: 400, json: { ok: false, message: "Validation failed.", errors } };
  }

  const normalizedEmail = email.trim().toLowerCase();

  const userRes = await pool.query(
    `SELECT user_id, email, is_verified FROM users WHERE lower(email) = $1 LIMIT 1`,
    [normalizedEmail]
  );
  const user = userRes.rows[0];

  if (!user) {
    return { statusCode: 404, json: { ok: false, message: "User not found." } };
  }

  if (user.is_verified) {
    return {
      statusCode: 200,
      json: {
        ok: true,
        message: "Account is already verified.",
        data: { is_verified: true }
      }
    };
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
    return {
      statusCode: 400,
      json: {
        ok: false,
        message: "Invalid or expired verification code.",
        errors: { code: "Invalid or expired verification code." }
      }
    };
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
    console.error(e);
    return { statusCode: 500, json: { ok: false, message: "Internal server error." } };
  } finally {
    client.release();
  }

  return {
    statusCode: 200,
    json: {
      ok: true,
      message: "Email verified successfully.",
      data: { is_verified: true }
    }
  };
}

async function login(body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const { email, password } = body ?? {};
  const errors = {};

  if (!isNonEmptyString(email) || !isValidEmail(email)) {
    errors.email = "Please enter a valid email address";
  }

  if (!isNonEmptyString(password)) {
    errors.password = "Password cannot be empty";
  }

  if (Object.keys(errors).length > 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Validation failed.", errors }
    };
  }

  const normalizedEmail = email.trim().toLowerCase();

  const userRes = await pool.query(
    `
      SELECT user_id, email, password_hash, is_verified, name, surname
      FROM users
      WHERE lower(email) = $1
      LIMIT 1
      `,
    [normalizedEmail]
  );
  const user = userRes.rows[0];

  if (!user) {
    return { statusCode: 404, json: { ok: false, message: "Account not found" } };
  }

  const passwordOk = await bcrypt.compare(password, user.password_hash);
  if (!passwordOk) {
    return {
      statusCode: 401,
      json: { ok: false, message: "Email or password is incorrect." }
    };
  }

  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  return {
    statusCode: 200,
    json: {
      ok: true,
      message: user.is_verified
        ? "Login successful"
        : "Login successful. Please verify your email address.",
      data: {
        accessToken,
        refreshToken,
        token: accessToken,
        user: {
          user_id: user.user_id,
          email: user.email,
          name: user.name,
          surname: user.surname,
          is_verified: user.is_verified
        }
      }
    }
  };
}

async function forgotPassword(body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const { email } = body ?? {};
  const errors = {};

  if (!isNonEmptyString(email) || !isValidEmail(email)) {
    errors.email = "Please enter a valid email address";
  }

  if (Object.keys(errors).length > 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Validation failed.", errors }
    };
  }

  const normalizedEmail = email.trim().toLowerCase();

  const userRes = await pool.query(
    `SELECT user_id FROM users WHERE lower(email) = $1 LIMIT 1`,
    [normalizedEmail]
  );
  const user = userRes.rows[0];

  if (!user) {
    return { statusCode: 404, json: { ok: false, message: "Account not found" } };
  }

  const code = generateVerificationCode();
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

  await pool.query(
    `
      INSERT INTO verification_codes (user_id, code, purpose, expires_at, is_used)
      VALUES ($1, $2, 'password_reset', $3, false)
      `,
    [user.user_id, code, expiresAt]
  );

  const payload = {
    ok: true,
    message: "Password reset code sent. Check your email.",
    data: { next: "reset_password" }
  };

  if (process.env.NODE_ENV !== "production") {
    payload.data.dev_reset_code = code;
  }

  return { statusCode: 200, json: payload };
}

async function resetPassword(body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const { email, code, password, confirmPassword } = body ?? {};
  const errors = {};

  if (!isNonEmptyString(email) || !isValidEmail(email)) {
    errors.email = "Please enter a valid email address";
  }
  if (!isNonEmptyString(code)) errors.code = "Reset code is required.";
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
    return { statusCode: 400, json: { ok: false, message: "Validation failed.", errors } };
  }

  const normalizedEmail = email.trim().toLowerCase();

  const userRes = await pool.query(
    `SELECT user_id FROM users WHERE lower(email) = $1 LIMIT 1`,
    [normalizedEmail]
  );
  const user = userRes.rows[0];

  if (!user) {
    return { statusCode: 404, json: { ok: false, message: "Account not found" } };
  }

  const now = new Date();
  const verificationRes = await pool.query(
    `
      SELECT code_id, code, expires_at, is_used
      FROM verification_codes
      WHERE user_id = $1
        AND purpose = 'password_reset'
        AND is_used = false
        AND expires_at > $2
      ORDER BY created_at DESC
      LIMIT 1
      `,
    [user.user_id, now]
  );
  const verificationRow = verificationRes.rows[0];

  if (!verificationRow || String(verificationRow.code) !== String(code).trim()) {
    return {
      statusCode: 400,
      json: {
        ok: false,
        message: "Invalid or expired reset code.",
        errors: { code: "Invalid or expired reset code." }
      }
    };
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(`UPDATE verification_codes SET is_used = true WHERE code_id = $1`, [
      verificationRow.code_id
    ]);
    await client.query(`UPDATE users SET password_hash = $1 WHERE user_id = $2`, [
      passwordHash,
      user.user_id
    ]);
    await client.query("COMMIT");
  } catch (e) {
    await client.query("ROLLBACK");
    console.error(e);
    return { statusCode: 500, json: { ok: false, message: "Internal server error." } };
  } finally {
    client.release();
  }

  return {
    statusCode: 200,
    json: {
      ok: true,
      message: "Password updated successfully."
    }
  };
}

module.exports = {
  signup,
  verifyEmail,
  login,
  forgotPassword,
  resetPassword
};
