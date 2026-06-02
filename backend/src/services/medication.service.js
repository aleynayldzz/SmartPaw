const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");

const MED_NAME_MIN = 2;
const MED_NAME_MAX = 80;
const DOSAGE_MIN = 1;
const DOSAGE_MAX = 80;
const FREQ_MIN = 2;
const FREQ_MAX = 40;
const NOTES_MAX = 2000;

function mapScheduleRow(row) {
  if (!row) return null;
  return {
    schedule_id: row.schedule_id,
    reminder_time: row.reminder_time, // HH:MM:SS
    is_active: Boolean(row.is_active),
    is_taken_today: Boolean(row.is_taken_today)
  };
}

function mapMedicationRow(row) {
  if (!row) return null;
  return {
    medication_id: row.medication_id,
    cat_id: row.cat_id,
    cat_name: row.cat_name ?? undefined,
    medication_name: row.medication_name,
    dosage: row.dosage,
    frequency: row.frequency,
    start_date: row.start_date,
    end_date: row.end_date,
    is_active: Boolean(row.is_active),
    notes: row.notes ?? "",
    schedules: Array.isArray(row.schedules) ? row.schedules : undefined,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

function parseCatId(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: "Kedi seçimi zorunludur." };
  }
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    return { valid: false, error: "Kedi seçimi geçersiz." };
  }
  return { valid: true, value: id };
}

function validateMedicationName(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "İlaç adı zorunludur." };
  }
  const t = value.trim();
  if (t.length < MED_NAME_MIN || t.length > MED_NAME_MAX) {
    return {
      valid: false,
      error: `İlaç adı ${MED_NAME_MIN} ile ${MED_NAME_MAX} karakter arasında olmalıdır.`
    };
  }
  return { valid: true, value: t };
}

function validateDosage(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "Dozaj zorunludur." };
  }
  const t = value.trim();
  if (t.length < DOSAGE_MIN || t.length > DOSAGE_MAX) {
    return {
      valid: false,
      error: `Dozaj ${DOSAGE_MIN} ile ${DOSAGE_MAX} karakter arasında olmalıdır.`
    };
  }
  return { valid: true, value: t };
}

function validateFrequency(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "Sıklık zorunludur." };
  }
  const t = value.trim();
  // Preferred canonical keys
  if (t === "daily" || t === "weekly" || t === "asNeeded") {
    return { valid: true, value: t };
  }
  // Backward-compatible: allow existing free-text values
  if (t.length < FREQ_MIN || t.length > FREQ_MAX) {
    return {
      valid: false,
      error: `Sıklık ${FREQ_MIN} ile ${FREQ_MAX} karakter arasında olmalıdır.`
    };
  }
  return { valid: true, value: t };
}

function parseNotes(value) {
  if (value === undefined || value === null) {
    return { valid: true, value: "" };
  }
  if (typeof value !== "string") {
    return { valid: false, error: "Notlar metin olmalıdır." };
  }
  const t = value.trim();
  if (t.length > NOTES_MAX) {
    return { valid: false, error: `Notlar en fazla ${NOTES_MAX} karakter olabilir.` };
  }
  return { valid: true, value: t };
}

function parseDateOnly(value, label, { required = true } = {}) {
  if (!isNonEmptyString(value)) {
    if (!required) return { valid: true, value: null };
    return { valid: false, error: `${label} zorunludur.` };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: `${label} YYYY-AA-GG formatında olmalıdır.` };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: `${label} geçersiz.` };
  }
  return { valid: true, value: s };
}

// schedule_times are intentionally not used (day/week based tracking).

async function assertCatOwner(userId, catId) {
  const r = await pool.query(
    `SELECT cat_id, name FROM cats WHERE cat_id = $1 AND user_id = $2`,
    [catId, userId]
  );
  return r.rows[0] ?? null;
}

function todayUtcDateString() {
  return new Date().toISOString().slice(0, 10);
}

function startOfIsoWeekUtc(dateStr) {
  const d = new Date(`${dateStr}T12:00:00.000Z`);
  const day = d.getUTCDay(); // 0=Sun..6=Sat
  const isoDay = day === 0 ? 7 : day; // 1..7
  d.setUTCDate(d.getUTCDate() - (isoDay - 1));
  return d.toISOString().slice(0, 10);
}

async function listForUser(userId) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const res = await pool.query(
    `
    SELECT
      m.medication_id,
      m.cat_id,
      c.name AS cat_name,
      m.medication_name,
      m.dosage,
      m.frequency,
      m.start_date,
      m.end_date,
      m.is_active,
      m.notes,
      m.created_at,
      m.updated_at
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE c.user_id = $1
    ORDER BY m.created_at DESC, m.medication_id DESC
    `,
    [userId]
  );

  return {
    statusCode: 200,
    json: { ok: true, data: { medications: res.rows.map(mapMedicationRow) } }
  };
}

async function createForUser(userId, body) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const catParsed = parseCatId(body?.cat_id);
  if (!catParsed.valid) return { statusCode: 400, json: { ok: false, message: catParsed.error } };

  const cat = await assertCatOwner(userId, catParsed.value);
  if (!cat) return { statusCode: 404, json: { ok: false, message: "Cat not found." } };

  const nameParsed = validateMedicationName(body?.medication_name);
  if (!nameParsed.valid) return { statusCode: 400, json: { ok: false, message: nameParsed.error } };

  const dosageParsed = validateDosage(body?.dosage);
  if (!dosageParsed.valid) return { statusCode: 400, json: { ok: false, message: dosageParsed.error } };

  const freqParsed = validateFrequency(body?.frequency);
  if (!freqParsed.valid) return { statusCode: 400, json: { ok: false, message: freqParsed.error } };

  const startParsed = parseDateOnly(body?.start_date, "Start date", { required: true });
  if (!startParsed.valid) return { statusCode: 400, json: { ok: false, message: startParsed.error } };

  const endParsed = parseDateOnly(body?.end_date, "End date", { required: true });
  if (!endParsed.valid) return { statusCode: 400, json: { ok: false, message: endParsed.error } };

  const startD = new Date(`${startParsed.value}T12:00:00.000Z`);
  const endD = new Date(`${endParsed.value}T12:00:00.000Z`);
  if (endD.getTime() < startD.getTime()) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Bitiş tarihi başlangıç tarihinden önce olamaz." }
    };
  }

  const notesParsed = parseNotes(body?.notes);
  if (!notesParsed.valid) return { statusCode: 400, json: { ok: false, message: notesParsed.error } };

  const insert = await pool.query(
    `
    INSERT INTO medications (
      cat_id, medication_name, dosage, frequency, start_date, end_date, is_active, notes
    )
    VALUES ($1, $2, $3, $4, $5::date, $6::date, true, $7)
    RETURNING medication_id, cat_id, medication_name, dosage, frequency, start_date, end_date, is_active, notes, created_at, updated_at
    `,
    [
      catParsed.value,
      nameParsed.value,
      dosageParsed.value,
      freqParsed.value,
      startParsed.value,
      endParsed.value,
      notesParsed.value
    ]
  );

  const med = insert.rows[0];

  return {
    statusCode: 201,
    json: {
      ok: true,
      data: {
        medication: mapMedicationRow({ ...med, cat_name: cat.name })
      }
    }
  };
}

async function updateForUser(userId, medicationIdRaw, body) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const medicationId = Number(medicationIdRaw);
  if (!Number.isInteger(medicationId) || medicationId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Geçersiz ilaç kaydı." } };
  }

  const existing = await pool.query(
    `
    SELECT m.medication_id
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE m.medication_id = $1 AND c.user_id = $2
    `,
    [medicationId, userId]
  );
  if (existing.rows.length === 0) {
    return { statusCode: 404, json: { ok: false, message: "İlaç kaydı bulunamadı." } };
  }

  const catParsed = parseCatId(body?.cat_id);
  if (!catParsed.valid) return { statusCode: 400, json: { ok: false, message: catParsed.error } };

  const cat = await assertCatOwner(userId, catParsed.value);
  if (!cat) return { statusCode: 404, json: { ok: false, message: "Kedi bulunamadı." } };

  const nameParsed = validateMedicationName(body?.medication_name);
  if (!nameParsed.valid) return { statusCode: 400, json: { ok: false, message: nameParsed.error } };

  const dosageParsed = validateDosage(body?.dosage);
  if (!dosageParsed.valid) return { statusCode: 400, json: { ok: false, message: dosageParsed.error } };

  const freqParsed = validateFrequency(body?.frequency);
  if (!freqParsed.valid) return { statusCode: 400, json: { ok: false, message: freqParsed.error } };

  const startParsed = parseDateOnly(body?.start_date, "Start date", { required: true });
  if (!startParsed.valid) return { statusCode: 400, json: { ok: false, message: startParsed.error } };

  const endParsed = parseDateOnly(body?.end_date, "End date", { required: true });
  if (!endParsed.valid) return { statusCode: 400, json: { ok: false, message: endParsed.error } };

  const startD = new Date(`${startParsed.value}T12:00:00.000Z`);
  const endD = new Date(`${endParsed.value}T12:00:00.000Z`);
  if (endD.getTime() < startD.getTime()) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Bitiş tarihi başlangıç tarihinden önce olamaz." }
    };
  }

  const notesParsed = parseNotes(body?.notes);
  if (!notesParsed.valid) return { statusCode: 400, json: { ok: false, message: notesParsed.error } };

  const updated = await pool.query(
    `
    UPDATE medications
    SET
      cat_id = $1,
      medication_name = $2,
      dosage = $3,
      frequency = $4,
      start_date = $5::date,
      end_date = $6::date,
      is_active = true,
      notes = $7,
      updated_at = NOW()
    WHERE medication_id = $8
    RETURNING medication_id, cat_id, medication_name, dosage, frequency, start_date, end_date, is_active, notes, created_at, updated_at
    `,
    [
      catParsed.value,
      nameParsed.value,
      dosageParsed.value,
      freqParsed.value,
      startParsed.value,
      endParsed.value,
      notesParsed.value,
      medicationId
    ]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        medication: mapMedicationRow({ ...updated.rows[0], cat_name: cat.name })
      }
    }
  };
}

async function deleteForUser(userId, medicationIdRaw) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const medicationId = Number(medicationIdRaw);
  if (!Number.isInteger(medicationId) || medicationId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Geçersiz ilaç kaydı." } };
  }

  const existing = await pool.query(
    `
    SELECT m.medication_id
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE m.medication_id = $1 AND c.user_id = $2
    `,
    [medicationId, userId]
  );
  if (existing.rows.length === 0) {
    return { statusCode: 404, json: { ok: false, message: "İlaç kaydı bulunamadı." } };
  }

  await pool.query(`DELETE FROM medications WHERE medication_id = $1`, [medicationId]);

  return { statusCode: 200, json: { ok: true, data: { deleted: true } } };
}

async function getScheduleForUser(userId, dateInput) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const dateStr = isNonEmptyString(dateInput) ? String(dateInput).trim() : todayUtcDateString();
  const dateParsed = parseDateOnly(dateStr, "date", { required: true });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  const weekStart = startOfIsoWeekUtc(dateParsed.value);
  const res = await pool.query(
    `
    SELECT
      m.medication_id,
      m.cat_id,
      c.name AS cat_name,
      m.medication_name,
      m.dosage,
      m.frequency,
      m.start_date,
      m.end_date,
      m.is_active,
      m.notes,
      m.created_at,
      m.updated_at,
      EXISTS (
        SELECT 1
        FROM user_daily_routine_checks u
        WHERE u.user_id = $1
          AND u.check_date = (CASE WHEN m.frequency = 'weekly' THEN $3::date ELSE $2::date END)
          AND u.task_key = (CASE WHEN m.frequency = 'weekly'
                             THEN ('mw_' || m.medication_id::text)
                             ELSE ('m_' || m.medication_id::text)
                        END)
          AND u.is_done = true
      ) AS is_taken_today
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE c.user_id = $1
      AND m.is_active = true
      AND m.start_date <= $2::date
      AND m.end_date >= $2::date
    ORDER BY c.name ASC, m.medication_name ASC
    `,
    [userId, dateParsed.value, weekStart]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { date: dateParsed.value, medications: res.rows.map(mapMedicationRow) }
    }
  };
}

async function markTakenForUser(userId, medicationIdRaw, body) {
  if (!pool) return { statusCode: 500, json: dbNotConfiguredPayload() };

  const medicationId = Number(medicationIdRaw);
  if (!Number.isInteger(medicationId) || medicationId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Geçersiz ilaç kaydı." } };
  }

  const dateInput = body?.date;
  const dateStr = isNonEmptyString(dateInput) ? String(dateInput).trim() : todayUtcDateString();
  const dateParsed = parseDateOnly(dateStr, "date", { required: true });
  if (!dateParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: dateParsed.error } };
  }

  if (typeof body?.is_taken !== "boolean") {
    return { statusCode: 400, json: { ok: false, message: "is_taken must be a boolean." } };
  }

  const ownership = await pool.query(
    `
    SELECT m.medication_id
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE m.medication_id = $1 AND c.user_id = $2
    `,
    [medicationId, userId]
  );
  if (ownership.rows.length === 0) {
    return { statusCode: 404, json: { ok: false, message: "Medication not found." } };
  }

  const freqRes = await pool.query(
    `
    SELECT m.frequency
    FROM medications m
    INNER JOIN cats c ON c.cat_id = m.cat_id
    WHERE m.medication_id = $1 AND c.user_id = $2
    `,
    [medicationId, userId]
  );
  if (freqRes.rows.length === 0) {
    return { statusCode: 404, json: { ok: false, message: "Medication not found." } };
  }
  const frequency = String(freqRes.rows[0]?.frequency ?? "").trim();
  const isWeekly = frequency === "weekly";
  const effectiveDate = isWeekly ? startOfIsoWeekUtc(dateParsed.value) : dateParsed.value;
  const key = isWeekly ? `mw_${medicationId}` : `m_${medicationId}`;
  const completedAt = body.is_taken ? new Date() : null;

  await pool.query(
    `
    INSERT INTO user_daily_routine_checks (
      user_id, check_date, task_key, is_done, completed_at
    )
    VALUES ($1, $2::date, $3, $4, $5)
    ON CONFLICT (user_id, check_date, task_key)
    DO UPDATE SET
      is_done = EXCLUDED.is_done,
      completed_at = EXCLUDED.completed_at,
      updated_at = NOW()
    `,
    [Number(userId), effectiveDate, key, body.is_taken, completedAt]
  );

  return {
    statusCode: 200,
    json: { ok: true, data: { saved: true } }
  };
}

module.exports = {
  listForUser,
  createForUser,
  updateForUser,
  deleteForUser,
  getScheduleForUser,
  markTakenForUser
};

