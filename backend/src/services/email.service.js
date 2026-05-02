const nodemailer = require("nodemailer");
const { isNonEmptyString } = require("../utils/validators");

function hasSmtpConfig() {
  return (
    isNonEmptyString(process.env.SMTP_HOST) &&
    isNonEmptyString(process.env.SMTP_PORT) &&
    isNonEmptyString(process.env.SMTP_USER) &&
    isNonEmptyString(process.env.SMTP_PASS) &&
    isNonEmptyString(process.env.SMTP_FROM)
  );
}

function createMailTransport() {
  if (!hasSmtpConfig()) {
    return null;
  }

  const port = Number(process.env.SMTP_PORT);
  const secure =
    String(process.env.SMTP_SECURE || "").trim() === "1" ||
    String(process.env.SMTP_SECURE || "").trim().toLowerCase() === "true" ||
    port === 465;

  return nodemailer.createTransport({
    host: String(process.env.SMTP_HOST).trim(),
    port,
    secure,
    auth: {
      user: String(process.env.SMTP_USER).trim(),
      pass: String(process.env.SMTP_PASS)
    }
  });
}

async function sendVerificationEmail({ toEmail, code, expiresAt }) {
  const transport = createMailTransport();
  if (!transport) {
    const err = new Error("SMTP is not configured");
    err.code = "SMTP_NOT_CONFIGURED";
    throw err;
  }

  const from = String(process.env.SMTP_FROM).trim();
  const subject = "SmartPaw email verification code";

  const text = [
    "Your SmartPaw verification code is:",
    "",
    code,
    "",
    `This code expires at: ${expiresAt.toISOString()}`,
    "",
    "If you did not create an account, you can ignore this email."
  ].join("\n");

  const html = `
    <div style="font-family:Segoe UI,Roboto,Arial,sans-serif;line-height:1.5;color:#111">
      <p>Your SmartPaw verification code is:</p>
      <p style="font-size:28px;font-weight:700;letter-spacing:4px">${code}</p>
      <p style="color:#444">This code expires at: <strong>${expiresAt.toISOString()}</strong></p>
      <p style="color:#444">If you did not create an account, you can ignore this email.</p>
    </div>
  `;

  await transport.sendMail({
    from,
    to: toEmail,
    subject,
    text,
    html
  });
}

module.exports = {
  hasSmtpConfig,
  sendVerificationEmail
};
