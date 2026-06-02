const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");

const REASON_MIN = 2;
const REASON_MAX = 120;
const DOCTOR_NOTES_MAX = 1000;
const WEIGHT_MIN = 0.5;
const WEIGHT_MAX = 25;

function mapVetVisitRow(row) {
  if (!row) return null;
  return {
    visit_id: row.visit_id,
    cat_id: row.cat_id,
    cat_name: row.cat_name ?? undefined,
    visit_date: row.visit_date,
    weight: row.weight != null ? Number(row.weight) : null,
    reason: row.reason,
    doctor_notes: row.doctor_notes ?? "",
    next_visit_date: row.next_visit_date,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

function parseDateOnly(value, { required = true, allowFuture = false } = {}) {
  if (!isNonEmptyString(value)) {
    if (!required) return { valid: true, value: null };
    return { valid: false, error: "Visit date is required." };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "Visit date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "Visit date is invalid." };
  }
  if (!allowFuture) {
    const today = new Date();
    today.setUTCHours(23, 59, 59, 999);
    if (d.getTime() > today.getTime()) {
      return { valid: false, error: "Visit date cannot be in the future." };
    }
  }
  return { valid: true, value: s };
}

function parseOptionalNextVisitDate(value, visitDateStr) {
  if (value === undefined || value === null || value === "") {
    return { valid: true, value: null };
  }
  const parsed = parseDateOnly(value, { required: true, allowFuture: true });
  if (!parsed.valid) {
    return { valid: false, error: "Next visit date must be YYYY-MM-DD." };
  }
  const next = new Date(`${parsed.value}T12:00:00.000Z`);
  const visit = new Date(`${visitDateStr}T12:00:00.000Z`);
  if (next.getTime() <= visit.getTime()) {
    return {
      valid: false,
      error: "Next visit date must be later than visit date."
    };
  }
  return { valid: true, value: parsed.value };
}

function validateReason(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "Reason is required." };
  }
  const t = value.trim();
  if (t.length < REASON_MIN || t.length > REASON_MAX) {
    return {
      valid: false,
      error: `Reason must be between ${REASON_MIN} and ${REASON_MAX} characters.`
    };
  }
  return { valid: true, value: t };
}

function parseDoctorNotes(value) {
  if (value === undefined || value === null) {
    return { valid: true, value: "" };
  }
  if (typeof value !== "string") {
    return { valid: false, error: "Doctor notes must be text." };
  }
  const t = value.trim();
  if (t.length > DOCTOR_NOTES_MAX) {
    return {
      valid: false,
      error: `Doctor notes must be at most ${DOCTOR_NOTES_MAX} characters.`
    };
  }
  return { valid: true, value: t };
}

function parseWeight(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: "Weight is required." };
  }
  const n = Number(value);
  if (!Number.isFinite(n)) {
    return { valid: false, error: "Weight must be a number." };
  }
  if (n < WEIGHT_MIN || n > WEIGHT_MAX) {
    return {
      valid: false,
      error: `Weight must be between ${WEIGHT_MIN} and ${WEIGHT_MAX} kg.`
    };
  }
  return { valid: true, value: Math.round(n * 100) / 100 };
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
      v.visit_id,
      v.cat_id,
      c.name AS cat_name,
      v.visit_date,
      v.weight,
      v.reason,
      v.doctor_notes,
      v.next_visit_date,
      v.created_at,
      v.updated_at
    FROM vet_visits v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE c.user_id = $1
    ORDER BY v.visit_date DESC, v.visit_id DESC
    `,
    [userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        vet_visits: res.rows.map(mapVetVisitRow)
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

  const dateParsed = parseDateOnly(body?.visit_date, {
    required: true,
    allowFuture: false
  });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  const weightParsed = parseWeight(body?.weight);
  if (!weightParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: weightParsed.error } };
  }

  const reasonParsed = validateReason(body?.reason);
  if (!reasonParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: reasonParsed.error } };
  }

  const notesParsed = parseDoctorNotes(body?.doctor_notes);
  if (!notesParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: notesParsed.error } };
  }

  const nextParsed = parseOptionalNextVisitDate(
    body?.next_visit_date,
    dateParsed.value
  );
  if (!nextParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: nextParsed.error } };
  }

  const insert = await pool.query(
    `
    INSERT INTO vet_visits (
      cat_id,
      visit_date,
      weight,
      reason,
      doctor_notes,
      next_visit_date
    )
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING visit_id, cat_id, visit_date, weight, reason, doctor_notes,
              next_visit_date, created_at, updated_at
    `,
    [
      catParsed.value,
      dateParsed.value,
      weightParsed.value,
      reasonParsed.value,
      notesParsed.value,
      nextParsed.value
    ]
  );

  const row = mapVetVisitRow({
    ...insert.rows[0],
    cat_name: cat.name
  });

  return {
    statusCode: 201,
    json: { ok: true, data: { vet_visit: row } }
  };
}

async function updateForUser(userId, visitIdRaw, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const visitId = Number(visitIdRaw);
  if (!Number.isInteger(visitId) || visitId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid visit id." }
    };
  }

  const existing = await pool.query(
    `
    SELECT v.visit_id
    FROM vet_visits v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE v.visit_id = $1 AND c.user_id = $2
    `,
    [visitId, userId]
  );

  if (existing.rows.length === 0) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Vet visit not found." }
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

  const dateParsed = parseDateOnly(body?.visit_date, {
    required: true,
    allowFuture: false
  });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  const weightParsed = parseWeight(body?.weight);
  if (!weightParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: weightParsed.error } };
  }

  const reasonParsed = validateReason(body?.reason);
  if (!reasonParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: reasonParsed.error } };
  }

  const notesParsed = parseDoctorNotes(body?.doctor_notes);
  if (!notesParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: notesParsed.error } };
  }

  const nextParsed = parseOptionalNextVisitDate(
    body?.next_visit_date,
    dateParsed.value
  );
  if (!nextParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: nextParsed.error } };
  }

  const updated = await pool.query(
    `
    UPDATE vet_visits
    SET
      cat_id = $1,
      visit_date = $2,
      weight = $3,
      reason = $4,
      doctor_notes = $5,
      next_visit_date = $6,
      updated_at = NOW()
    WHERE visit_id = $7
    RETURNING visit_id, cat_id, visit_date, weight, reason, doctor_notes,
              next_visit_date, created_at, updated_at
    `,
    [
      catParsed.value,
      dateParsed.value,
      weightParsed.value,
      reasonParsed.value,
      notesParsed.value,
      nextParsed.value,
      visitId
    ]
  );

  const row = mapVetVisitRow({
    ...updated.rows[0],
    cat_name: cat.name
  });

  return {
    statusCode: 200,
    json: { ok: true, data: { vet_visit: row } }
  };
}

async function deleteForUser(userId, visitIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const visitId = Number(visitIdRaw);
  if (!Number.isInteger(visitId) || visitId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid visit id." }
    };
  }

  const existing = await pool.query(
    `
    SELECT v.visit_id
    FROM vet_visits v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE v.visit_id = $1 AND c.user_id = $2
    `,
    [visitId, userId]
  );

  if (existing.rows.length === 0) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Vet visit not found." }
    };
  }

  await pool.query(`DELETE FROM vet_visits WHERE visit_id = $1`, [visitId]);

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
