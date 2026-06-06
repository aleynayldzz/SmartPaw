const { pool, dbNotConfiguredPayload } = require("../db");
const { toCalendarDateString } = require("../utils/date");

const DEFAULT_MONTHS = 6;

function formatDateOnly(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function monthsAgoDateStr(months = DEFAULT_MONTHS) {
  const now = new Date();
  const d = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - months, now.getUTCDate())
  );
  return formatDateOnly(d);
}

function parseCatIdQuery(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: true, value: null };
  }
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    return { valid: false, error: "cat_id must be a positive integer." };
  }
  return { valid: true, value: id };
}

function parseMonthsQuery(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: true, value: DEFAULT_MONTHS };
  }
  const n = Number(value);
  if (!Number.isInteger(n) || n < 1 || n > 24) {
    return { valid: false, error: "months must be between 1 and 24." };
  }
  return { valid: true, value: n };
}

function mapWeightHistoryRow(row) {
  if (!row) return null;
  return {
    weight_id: row.visit_id,
    cat_id: row.cat_id,
    cat_name: row.cat_name ?? undefined,
    weight_kg: Number(row.weight),
    recorded_date: toCalendarDateString(row.recorded_date)
  };
}

async function listForUser(userId, query = {}) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const catParsed = parseCatIdQuery(query.cat_id);
  if (!catParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: catParsed.error } };
  }

  const monthsParsed = parseMonthsQuery(query.months);
  if (!monthsParsed.valid) {
    return { statusCode: 400, json: { ok: false, message: monthsParsed.error } };
  }

  const sinceDate = monthsAgoDateStr(monthsParsed.value);
  const params = [userId, sinceDate];
  let sql = `
    SELECT
      v.visit_id,
      v.cat_id,
      c.name AS cat_name,
      v.weight,
      to_char(v.visit_date, 'YYYY-MM-DD') AS recorded_date
    FROM vet_visits v
    INNER JOIN cats c ON c.cat_id = v.cat_id
    WHERE c.user_id = $1
      AND v.visit_date >= $2
      AND v.weight IS NOT NULL
      AND v.weight > 0
  `;

  if (catParsed.value != null) {
    params.push(catParsed.value);
    sql += ` AND v.cat_id = $${params.length}`;
  }

  sql += ` ORDER BY v.visit_date ASC, v.visit_id ASC`;

  const res = await pool.query(sql, params);

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        weight_history: res.rows.map(mapWeightHistoryRow)
      }
    }
  };
}

module.exports = {
  listForUser
};
