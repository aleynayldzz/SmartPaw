const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");

const VACCINE_NAME_MIN = 2;
const VACCINE_NAME_MAX = 80;
const NOTES_MAX = 2000;

function mapVaccinationRow(row) {
  if (!row) return null;
  return {
    vaccination_id: row.vaccination_id,
    cat_id: row.cat_id,
    cat_name: row.cat_name ?? undefined,
    vaccine_name: row.vaccine_name,
    vaccination_date: row.vaccination_date,
    next_due_date: row.next_due_date,
    reminder_enabled: Boolean(row.reminder_enabled),
    notes: row.notes ?? "",
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

function parseDateOnly(value, { required = true, allowFuture = false } = {}) {
  if (!isNonEmptyString(value)) {
    if (!required) return { valid: true, value: null };
    return { valid: false, error: "Date is required." };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "Date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "Date is invalid." };
  }
  if (!allowFuture) {
    const today = new Date();
    today.setUTCHours(23, 59, 59, 999);
    if (d.getTime() > today.getTime()) {
      return { valid: false, error: "Vaccination date cannot be in the future." };
    }
  }
  return { valid: true, value: s };
}

function parseOptionalNextDueDate(value, vaccinationDateStr) {
  if (value === undefined || value === null || value === "") {
    return { valid: true, value: null };
  }
  const parsed = parseDateOnly(value, { required: true, allowFuture: true });
  if (!parsed.valid) {
    return { valid: false, error: "Next due date must be YYYY-MM-DD." };
  }
  const next = new Date(`${parsed.value}T12:00:00.000Z`);
  const admin = new Date(`${vaccinationDateStr}T12:00:00.000Z`);
  if (next.getTime() <= admin.getTime()) {
    return {
      valid: false,
      error: "Next due date must be later than vaccination date."
    };
  }
  return { valid: true, value: parsed.value };
}

function validateVaccineName(name) {
  if (!isNonEmptyString(name)) {
    return { valid: false, error: "Vaccine name is required." };
  }
  const t = name.trim();
  if (t.length < VACCINE_NAME_MIN || t.length > VACCINE_NAME_MAX) {
    return {
      valid: false,
      error: `Vaccine name must be between ${VACCINE_NAME_MIN} and ${VACCINE_NAME_MAX} characters.`
    };
  }
  return { valid: true, value: t };
}

function parseNotes(value) {
  if (value === undefined || value === null) {
    return { valid: true, value: "" };
  }
  if (typeof value !== "string") {
    return { valid: false, error: "Notes must be text." };
  }
  const t = value.trim();
  if (t.length > NOTES_MAX) {
    return {
      valid: false,
      error: `Notes must be at most ${NOTES_MAX} characters.`
    };
  }
  return { valid: true, value: t };
}

function parseCatId(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: "cat_id is required." };
  }
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    return { valid: false, error: "cat_id must be a positive integer." };
  }
  return { valid: true, value: id };
}

function parseReminderEnabled(value) {
  if (value === undefined || value === null) {
    return { valid: true, value: false };
  }
  if (typeof value === "boolean") {
    return { valid: true, value };
  }
  if (value === "true" || value === "false") {
    return { valid: true, value: value === "true" };
  }
  return { valid: false, error: "reminder_enabled must be a boolean." };
}

async function assertCatOwner(userId, catId) {
  const r = await pool.query(
    `SELECT cat_id, name FROM cats WHERE cat_id = $1 AND user_id = $2`,
    [catId, userId]
  );
  return r.rows[0] ?? null;
}

async function listForUser(userId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const res = await pool.query(
    `
    SELECT
      v.vaccination_id,
      v.cat_id,
      c.name AS cat_name,
      v.vaccine_name,
      v.vaccination_date,
      v.next_due_date,
      v.reminder_enabled,
      v.notes,
      v.created_at,
      v.updated_at
    FROM vaccinations v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE c.user_id = $1
    ORDER BY v.vaccination_date DESC, v.vaccination_id DESC
    `,
    [userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        vaccinations: res.rows.map(mapVaccinationRow)
      }
    }
  };
}

async function createForUser(userId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const catParsed = parseCatId(body?.cat_id);
  if (!catParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: catParsed.error } };
  }

  const cat = await assertCatOwner(userId, catParsed.value);
  if (!cat) {
    return { statusCode: 404, json: { ok: false, message: "Cat not found." } };
  }

  const vaccineParsed = validateVaccineName(body?.vaccine_name);
  if (!vaccineParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: vaccineParsed.error } };
  }

  const dateParsed = parseDateOnly(body?.vaccination_date, {
    required: true,
    allowFuture: false
  });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  const nextParsed = parseOptionalNextDueDate(
    body?.next_due_date,
    dateParsed.value
  );
  if (!nextParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: nextParsed.error } };
  }

  const notesParsed = parseNotes(body?.notes);
  if (!notesParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: notesParsed.error } };
  }

  const reminderParsed = parseReminderEnabled(body?.reminder_enabled);
  if (!reminderParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: reminderParsed.error } };
  }

  const insert = await pool.query(
    `
    INSERT INTO vaccinations (
      cat_id,
      vaccine_name,
      vaccination_date,
      next_due_date,
      reminder_enabled,
      notes
    )
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING vaccination_id, cat_id, vaccine_name, vaccination_date,
              next_due_date, reminder_enabled, notes, created_at, updated_at
    `,
    [
      catParsed.value,
      vaccineParsed.value,
      dateParsed.value,
      nextParsed.value,
      reminderParsed.value,
      notesParsed.value
    ]
  );

  const row = mapVaccinationRow({
    ...insert.rows[0],
    cat_name: cat.name
  });

  return {
    statusCode: 201,
    json: { ok: true, data: { vaccination: row } }
  };
}

async function updateForUser(userId, vaccinationIdRaw, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const vaccinationId = Number(vaccinationIdRaw);
  if (!Number.isInteger(vaccinationId) || vaccinationId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid vaccination id." }
    };
  }

  const existing = await pool.query(
    `
    SELECT v.vaccination_id
    FROM vaccinations v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE v.vaccination_id = $1 AND c.user_id = $2
    `,
    [vaccinationId, userId]
  );

  if (existing.rows.length === 0) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Vaccination not found." }
    };
  }

  const catParsed = parseCatId(body?.cat_id);
  if (!catParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: catParsed.error } };
  }

  const cat = await assertCatOwner(userId, catParsed.value);
  if (!cat) {
    return { statusCode: 404, json: { ok: false, message: "Cat not found." } };
  }

  const vaccineParsed = validateVaccineName(body?.vaccine_name);
  if (!vaccineParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: vaccineParsed.error } };
  }

  const dateParsed = parseDateOnly(body?.vaccination_date, {
    required: true,
    allowFuture: false
  });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  const nextParsed = parseOptionalNextDueDate(
    body?.next_due_date,
    dateParsed.value
  );
  if (!nextParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: nextParsed.error } };
  }

  const notesParsed = parseNotes(body?.notes);
  if (!notesParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: notesParsed.error } };
  }

  const reminderParsed = parseReminderEnabled(body?.reminder_enabled);
  if (!reminderParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: reminderParsed.error } };
  }

  const updated = await pool.query(
    `
    UPDATE vaccinations
    SET
      cat_id = $1,
      vaccine_name = $2,
      vaccination_date = $3,
      next_due_date = $4,
      reminder_enabled = $5,
      notes = $6,
      updated_at = NOW()
    WHERE vaccination_id = $7
    RETURNING vaccination_id, cat_id, vaccine_name, vaccination_date,
              next_due_date, reminder_enabled, notes, created_at, updated_at
    `,
    [
      catParsed.value,
      vaccineParsed.value,
      dateParsed.value,
      nextParsed.value,
      reminderParsed.value,
      notesParsed.value,
      vaccinationId
    ]
  );

  const row = mapVaccinationRow({
    ...updated.rows[0],
    cat_name: cat.name
  });

  return {
    statusCode: 200,
    json: { ok: true, data: { vaccination: row } }
  };
}

async function deleteForUser(userId, vaccinationIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const vaccinationId = Number(vaccinationIdRaw);
  if (!Number.isInteger(vaccinationId) || vaccinationId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid vaccination id." }
    };
  }

  const existing = await pool.query(
    `
    SELECT v.vaccination_id
    FROM vaccinations v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE v.vaccination_id = $1 AND c.user_id = $2
    `,
    [vaccinationId, userId]
  );

  if (existing.rows.length === 0) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Vaccination not found." }
    };
  }

  await pool.query(`DELETE FROM vaccinations WHERE vaccination_id = $1`, [
    vaccinationId
  ]);

  return {
    statusCode: 200,
    json: { ok: true, data: { deleted: true } }
  };
}

module.exports = {
  listForUser,
  createForUser,
  updateForUser,
  deleteForUser
};
