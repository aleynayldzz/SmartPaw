const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");

/**
 * Sabit günlük rutin maddeleri (sıra home ekranı ile aynı).
 * key = veritabanı/API kimliği (Türkçe değil; kodda sabit, anlamlı İngilizce snake_case).
 * title = kullanıcıya görünen metin.
 */
const ROUTINE_TASKS = [
  { key: "give_malt_supplement", title: "Malt Takviyesi Ver" },
  { key: "refresh_food_and_water", title: "Mama ve Suyu Tazele" },
  { key: "brush_fur", title: "Tüylerini Tara" },
  { key: "clean_ears_nose_eyes", title: "Kulak, Burun ve Göz Temizliği" },
  { key: "clean_litter_box", title: "Kum Kabını Temizle" },
  { key: "play_time", title: "Oyun Zamanı" }
];

const VALID_TASK_KEYS = new Set(ROUTINE_TASKS.map((t) => t.key));

function todayUtcDateString() {
  return new Date().toISOString().slice(0, 10);
}

function parseRoutineDate(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "date is required (YYYY-MM-DD)." };
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

function applicableTasks() {
  return ROUTINE_TASKS;
}

function routinePayload(dateStr, applicable, rows) {
  const doneByKey = new Map();
  for (const row of rows) {
    if (row.task_key) {
      doneByKey.set(String(row.task_key), Boolean(row.is_done));
    }
  }

  const tasks = applicable.map((def) => ({
    key: def.key,
    title: def.title,
    isDone: doneByKey.get(def.key) === true
  }));

  const completedCount = tasks.filter((t) => t.isDone).length;

  return {
    date: dateStr,
    totalApplicable: tasks.length,
    completedCount,
    tasks
  };
}

/**
 * GET — Uygulanabilir görevler + tamamlanma durumu (ilerleme çubuğu oranı için).
 */
async function getRoutine(userId, dateInput) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const rawDate = isNonEmptyString(dateInput)
    ? String(dateInput).trim()
    : todayUtcDateString();
  const parsed = parseRoutineDate(rawDate);
  if (!parsed.valid) {
    return { statusCode: 400, json: { ok: false, message: parsed.error } };
  }

  const uid = Number(userId);
  if (!Number.isFinite(uid) || uid <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid user." } };
  }

  const applicable = applicableTasks();

  const res = await pool.query(
    `
    SELECT task_key, is_done
    FROM user_daily_routine_checks
    WHERE user_id = $1 AND check_date = $2::date
    ORDER BY task_key
    `,
    [uid, parsed.value]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: routinePayload(parsed.value, applicable, res.rows)
    }
  };
}

/**
 * PUT — Tek görevi günceller; yanıtta güncel liste ve completedCount döner.
 */
async function putRoutineTask(userId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const uid = Number(userId);
  if (!Number.isFinite(uid) || uid <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid user." } };
  }

  const parsed = parseRoutineDate(body?.date);
  if (!parsed.valid) {
    return { statusCode: 400, json: { ok: false, message: parsed.error } };
  }

  const taskKey = String(body?.taskKey ?? "").trim();
  if (!VALID_TASK_KEYS.has(taskKey)) {
    return {
      statusCode: 400,
      json: {
        ok: false,
        message: `taskKey must be one of: ${[...VALID_TASK_KEYS].join(", ")}.`
      }
    };
  }

  if (typeof body?.isDone !== "boolean") {
    return {
      statusCode: 400,
      json: { ok: false, message: "isDone must be a boolean." }
    };
  }

  const applicable = applicableTasks();
  if (!applicable.some((t) => t.key === taskKey)) {
    return {
      statusCode: 400,
      json: {
        ok: false,
        message:
          "Task is not applicable for this date."
      }
    };
  }

  const completedAt = body.isDone ? new Date() : null;

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
    [uid, parsed.value, taskKey, body.isDone, completedAt]
  );

  const res = await pool.query(
    `
    SELECT task_key, is_done
    FROM user_daily_routine_checks
    WHERE user_id = $1 AND check_date = $2::date
    ORDER BY task_key
    `,
    [uid, parsed.value]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: routinePayload(parsed.value, applicable, res.rows)
    }
  };
}

module.exports = {
  ROUTINE_TASKS,
  getRoutine,
  putRoutineTask
};
