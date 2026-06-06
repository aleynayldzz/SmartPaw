const { pool, dbNotConfiguredPayload } = require("../db");
const { toCalendarDateString } = require("../utils/date");
const { isNonEmptyString } = require("../utils/validators");

const VALID_FREQUENCY_DAYS = new Set([14, 21, 28]);

function formatDateOnly(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function todayDateOnly() {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 12, 0, 0)
  );
}

function parseLastCleaningDate(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "last_cleaning_date is required." };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "last_cleaning_date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "last_cleaning_date is invalid." };
  }
  const today = todayDateOnly();
  if (d.getTime() > today.getTime()) {
    return {
      valid: false,
      error: "last_cleaning_date cannot be in the future."
    };
  }
  return { valid: true, value: s };
}

function parseFrequencyDays(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: "frequency_days is required." };
  }
  const n = Number(value);
  if (!Number.isInteger(n) || !VALID_FREQUENCY_DAYS.has(n)) {
    return {
      valid: false,
      error: "frequency_days must be 14, 21, or 28."
    };
  }
  return { valid: true, value: n };
}

function nextCleaningDateStr(lastCleaningDateStr, frequencyDays) {
  const last = new Date(`${lastCleaningDateStr}T12:00:00.000Z`);
  const next = new Date(last);
  next.setUTCDate(next.getUTCDate() + frequencyDays);
  return formatDateOnly(next);
}

function daysRemaining(lastCleaningDateStr, frequencyDays, referenceDateStr) {
  const today = new Date(`${referenceDateStr}T12:00:00.000Z`);
  const next = new Date(
    `${nextCleaningDateStr(lastCleaningDateStr, frequencyDays)}T12:00:00.000Z`
  );
  return Math.floor((next - today) / (24 * 60 * 60 * 1000));
}

function daysElapsed(lastCleaningDateStr, referenceDateStr) {
  const today = new Date(`${referenceDateStr}T12:00:00.000Z`);
  const last = new Date(`${lastCleaningDateStr}T12:00:00.000Z`);
  const diff = Math.floor((today - last) / (24 * 60 * 60 * 1000));
  return Math.max(0, Math.min(diff, 99999));
}

function intervalProgress(lastCleaningDateStr, frequencyDays, referenceDateStr) {
  if (frequencyDays <= 0) return 0;
  const elapsed = daysElapsed(lastCleaningDateStr, referenceDateStr);
  return Math.max(0, Math.min(1, elapsed / frequencyDays));
}

function litterCleaningStatus(lastCleaningDateStr, frequencyDays, referenceDateStr) {
  const remaining = daysRemaining(
    lastCleaningDateStr,
    frequencyDays,
    referenceDateStr
  );
  if (remaining < 0) return "overdue";
  if (remaining <= 3) return "warning";
  return "ok";
}

function computeDerivedFields(
  row,
  referenceDateStr = formatDateOnly(todayDateOnly())
) {
  const frequencyDays = Number(row.frequency_days);
  const lastCleaningDate = row.last_cleaning_date;
  const remaining = daysRemaining(
    lastCleaningDate,
    frequencyDays,
    referenceDateStr
  );

  return {
    next_cleaning_date: nextCleaningDateStr(lastCleaningDate, frequencyDays),
    days_remaining: remaining,
    days_elapsed: daysElapsed(lastCleaningDate, referenceDateStr),
    interval_progress:
      Math.round(
        intervalProgress(lastCleaningDate, frequencyDays, referenceDateStr) * 10000
      ) / 10000,
    status: litterCleaningStatus(
      lastCleaningDate,
      frequencyDays,
      referenceDateStr
    )
  };
}

function mapLitterTrackingRow(row) {
  if (!row) return null;
  const lastCleaningDate = toCalendarDateString(row.last_cleaning_date);
  const derived = computeDerivedFields({
    ...row,
    last_cleaning_date: lastCleaningDate
  });
  return {
    litter_id: row.litter_id,
    last_cleaning_date: lastCleaningDate,
    frequency_days: Number(row.frequency_days),
    next_cleaning_date: derived.next_cleaning_date,
    days_remaining: derived.days_remaining,
    days_elapsed: derived.days_elapsed,
    interval_progress: derived.interval_progress,
    status: derived.status,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

const LITTER_SELECT = `
  SELECT
    litter_id,
    to_char(last_cleaning_date, 'YYYY-MM-DD') AS last_cleaning_date,
    frequency_days,
    created_at,
    updated_at
  FROM litter_tracking
`;

async function assertLitterOwner(userId, litterId) {
  const r = await pool.query(
    `${LITTER_SELECT} WHERE litter_id = $1 AND user_id = $2`,
    [litterId, userId]
  );
  return r.rows[0] ?? null;
}

async function getCurrentForUser(userId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const res = await pool.query(
    `${LITTER_SELECT} WHERE user_id = $1 LIMIT 1`,
    [userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        litter_tracking: res.rows[0] ? mapLitterTrackingRow(res.rows[0]) : null
      }
    }
  };
}

async function getForUser(userId, litterIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const litterId = Number(litterIdRaw);
  if (!Number.isInteger(litterId) || litterId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid litter id." }
    };
  }

  const row = await assertLitterOwner(userId, litterId);
  if (!row) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Litter tracking record not found." }
    };
  }

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { litter_tracking: mapLitterTrackingRow(row) }
    }
  };
}

function parseCreateOrUpdateBody(body) {
  const dateParsed = parseLastCleaningDate(body?.last_cleaning_date);
  if (!dateParsed.valid) {
    return {
      error: { statusCode: 400, json: { ok: false, message: dateParsed.error } }
    };
  }

  const frequencyParsed = parseFrequencyDays(body?.frequency_days);
  if (!frequencyParsed.valid) {
    return {
      error: {
        statusCode: 400,
        json: { ok: false, message: frequencyParsed.error }
      }
    };
  }

  return {
    value: {
      lastCleaningDate: dateParsed.value,
      frequencyDays: frequencyParsed.value
    }
  };
}

async function createForUser(userId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const parsed = parseCreateOrUpdateBody(body);
  if (parsed.error) return parsed.error;

  const { lastCleaningDate, frequencyDays } = parsed.value;

  const existing = await pool.query(
    `SELECT litter_id FROM litter_tracking WHERE user_id = $1`,
    [userId]
  );
  if (existing.rows.length > 0) {
    return {
      statusCode: 409,
      json: {
        ok: false,
        message: "You already have an active litter tracking record."
      }
    };
  }

  const insert = await pool.query(
    `
    INSERT INTO litter_tracking (
      user_id,
      last_cleaning_date,
      frequency_days
    )
    VALUES ($1, $2, $3)
    RETURNING litter_id, last_cleaning_date, frequency_days, created_at, updated_at
    `,
    [userId, lastCleaningDate, frequencyDays]
  );

  return {
    statusCode: 201,
    json: {
      ok: true,
      data: { litter_tracking: mapLitterTrackingRow(insert.rows[0]) }
    }
  };
}

async function updateForUser(userId, litterIdRaw, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const litterId = Number(litterIdRaw);
  if (!Number.isInteger(litterId) || litterId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid litter id." }
    };
  }

  const existing = await assertLitterOwner(userId, litterId);
  if (!existing) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Litter tracking record not found." }
    };
  }

  const parsed = parseCreateOrUpdateBody(body);
  if (parsed.error) return parsed.error;

  const { lastCleaningDate, frequencyDays } = parsed.value;

  const updated = await pool.query(
    `
    UPDATE litter_tracking
    SET
      last_cleaning_date = $1,
      frequency_days = $2,
      updated_at = NOW()
    WHERE litter_id = $3 AND user_id = $4
    RETURNING litter_id, last_cleaning_date, frequency_days, created_at, updated_at
    `,
    [lastCleaningDate, frequencyDays, litterId, userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { litter_tracking: mapLitterTrackingRow(updated.rows[0]) }
    }
  };
}

async function saveCleaningForUser(userId, litterIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const litterId = Number(litterIdRaw);
  if (!Number.isInteger(litterId) || litterId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid litter id." }
    };
  }

  const existing = await assertLitterOwner(userId, litterId);
  if (!existing) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Litter tracking record not found." }
    };
  }

  const today = formatDateOnly(todayDateOnly());

  const updated = await pool.query(
    `
    UPDATE litter_tracking
    SET
      last_cleaning_date = $1,
      updated_at = NOW()
    WHERE litter_id = $2 AND user_id = $3
    RETURNING litter_id, last_cleaning_date, frequency_days, created_at, updated_at
    `,
    [today, litterId, userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { litter_tracking: mapLitterTrackingRow(updated.rows[0]) }
    }
  };
}

async function deleteForUser(userId, litterIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const litterId = Number(litterIdRaw);
  if (!Number.isInteger(litterId) || litterId <= 0) {
    return {
      statusCode: 400,
      json: { ok: false, message: "Invalid litter id." }
    };
  }

  const existing = await assertLitterOwner(userId, litterId);
  if (!existing) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Litter tracking record not found." }
    };
  }

  await pool.query(`DELETE FROM litter_tracking WHERE litter_id = $1 AND user_id = $2`, [
    litterId,
    userId
  ]);

  return {
    statusCode: 200,
    json: { ok: true, data: { deleted: true } }
  };
}

module.exports = {
  getCurrentForUser,
  getForUser,
  createForUser,
  updateForUser,
  saveCleaningForUser,
  deleteForUser
};
