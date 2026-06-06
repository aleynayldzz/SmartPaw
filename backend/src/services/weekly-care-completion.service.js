const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");
const { ROUTINE_TASKS } = require("./daily-routine.service");
const { toCalendarDateString } = require("../utils/date");

function todayUtcDateString() {
  return new Date().toISOString().slice(0, 10);
}

function parseReferenceDate(value) {
  if (!isNonEmptyString(value)) {
    return { valid: true, value: todayUtcDateString() };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "date is invalid." };
  }
  return { valid: true, value: s };
}

function addDaysUtc(dateStr, days) {
  const d = new Date(`${dateStr}T12:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return toCalendarDateString(d);
}

function weekStartMonday(dateStr) {
  const d = new Date(`${dateStr}T12:00:00.000Z`);
  const dow = d.getUTCDay();
  const daysSinceMonday = dow === 0 ? 6 : dow - 1;
  d.setUTCDate(d.getUTCDate() - daysSinceMonday);
  return toCalendarDateString(d);
}

function completionPercent(totalCompleted, maxTasksPerDay) {
  if (maxTasksPerDay <= 0) return 0;
  const maxPossible = maxTasksPerDay * 7;
  const raw = Math.round((totalCompleted / maxPossible) * 100);
  return Math.min(100, Math.max(0, raw));
}

/**
 * GET — Mevcut haftanın (Pzt–Paz) günlük bakım tamamlama analizi.
 * `date` istemcinin yerel takvim gününü temsil eder (YYYY-MM-DD).
 */
async function getCurrentWeek(userId, dateInput) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const uid = Number(userId);
  if (!Number.isFinite(uid) || uid <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid user." } };
  }

  const parsed = parseReferenceDate(dateInput);
  if (!parsed.valid) {
    return { statusCode: 400, json: { ok: false, message: parsed.error } };
  }

  const referenceDate = parsed.value;
  const weekStart = weekStartMonday(referenceDate);
  const weekEnd = addDaysUtc(weekStart, 6);
  const maxTasksPerDay = ROUTINE_TASKS.length;

  const res = await pool.query(
    `
    SELECT
      to_char(check_date, 'YYYY-MM-DD') AS check_date,
      COUNT(*) FILTER (WHERE is_done = true)::int AS completed_count
    FROM user_daily_routine_checks
    WHERE user_id = $1
      AND check_date >= $2::date
      AND check_date <= $3::date
    GROUP BY check_date
    ORDER BY check_date
    `,
    [uid, weekStart, weekEnd]
  );

  const completedByDate = new Map();
  for (const row of res.rows) {
    const date = toCalendarDateString(row.check_date);
    if (!date) continue;
    completedByDate.set(date, Number(row.completed_count) || 0);
  }

  const days = [];
  let totalCompleted = 0;

  for (let offset = 0; offset < 7; offset += 1) {
    const date = addDaysUtc(weekStart, offset);
    const isFuture = date > referenceDate;
    const completedCount = isFuture ? 0 : completedByDate.get(date) ?? 0;

    if (!isFuture) {
      totalCompleted += completedCount;
    }

    days.push({
      date,
      completedCount,
      isToday: date === referenceDate,
      isFuture
    });
  }

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        weekStart,
        weekEnd,
        referenceDate,
        maxTasksPerDay,
        totalCompleted,
        completionPercent: completionPercent(totalCompleted, maxTasksPerDay),
        days
      }
    }
  };
}

module.exports = {
  getCurrentWeek
};
