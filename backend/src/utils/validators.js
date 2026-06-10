function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function isValidEmail(email) {
  if (typeof email !== "string") return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

function isValidPassword(password) {
  if (typeof password !== "string") return false;
  const trimmed = password;
  if (trimmed.length < 8) return false;
  if (!/\p{Uppercase_Letter}/u.test(trimmed)) return false;
  if (!/\p{Lowercase_Letter}/u.test(trimmed)) return false;
  if (!/[^\p{Letter}\p{Number}]/u.test(trimmed)) return false;
  return true;
}

function generateVerificationCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

module.exports = {
  isNonEmptyString,
  isValidEmail,
  isValidPassword,
  generateVerificationCode
};
