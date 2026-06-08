const { pool, dbNotConfiguredPayload } = require("../db");
const { toCalendarDateString } = require("../utils/date");
const { isNonEmptyString } = require("../utils/validators");

const DAILY_GRAMS_MIN = 1;
const DAILY_GRAMS_MAX = 5000;
const PACKAGE_KG_MIN = 0.01;
const PACKAGE_KG_MAX = 50;

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

function parseOpeningDate(value, { allowFuture = false } = {}) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "opening_date is required." };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "opening_date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "opening_date is invalid." };
  }
  if (!allowFuture) {
    const today = todayDateOnly();
    if (d.getTime() > today.getTime()) {
      return { valid: false, error: "opening_date cannot be in the future." };
    }
  }
  return { valid: true, value: s };
}

function parsePositiveDecimal(value, fieldName, { min, max }) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: `${fieldName} is required.` };
  }
  const n = Number(value);
  if (!Number.isFinite(n)) {
    return { valid: false, error: `${fieldName} must be a number.` };
  }
  if (n < min || n > max) {
    return {
      valid: false,
      error: `${fieldName} must be between ${min} and ${max}.`
    };
  }
  return { valid: true, value: Math.round(n * 100) / 100 };
}

function daysElapsed(openingDateStr, referenceDateStr) {
  const today = new Date(`${referenceDateStr}T12:00:00.000Z`);
  const opened = new Date(`${openingDateStr}T12:00:00.000Z`);
  const diff = Math.floor((today - opened) / (24 * 60 * 60 * 1000));
  return Math.max(0, Math.min(diff, 99999));
}

function remainingGrams(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  const packageGrams = packageWeightKg * 1000;
  if (packageGrams <= 0) return 0;
  const consumed = daysElapsed(openingDateStr, ref) * dailyFoodGrams;
  return Math.max(0, Math.min(packageGrams - consumed, packageGrams));
}

function remainingPercent(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  const packageGrams = packageWeightKg * 1000;
  if (packageGrams <= 0) return 0;
  return remainingGrams(packageWeightKg, dailyFoodGrams, openingDateStr, ref) / packageGrams;
}

function estimatedFinishDateStr(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  const plannedDays = plannedPackageDurationDays(packageWeightKg, dailyFoodGrams);
  const plannedFinish = addCalendarDays(openingDateStr, plannedDays);
  const remaining = remainingGrams(
    packageWeightKg,
    dailyFoodGrams,
    openingDateStr,
    ref
  );

  if (dailyFoodGrams <= 0) return ref;
  if (remaining <= 0) {
    return plannedFinish <= ref ? plannedFinish : ref;
  }

  const daysLeft = Math.ceil(remaining / dailyFoodGrams);
  const finish = new Date(`${ref}T12:00:00.000Z`);
  finish.setUTCDate(finish.getUTCDate() + daysLeft);
  return formatDateOnly(finish);
}

function daysUntilFinish(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  const finish = estimatedFinishDateStr(
    packageWeightKg,
    dailyFoodGrams,
    openingDateStr,
    ref
  );
  const today = new Date(`${ref}T12:00:00.000Z`);
  const finishDate = new Date(`${finish}T12:00:00.000Z`);
  return Math.floor((finishDate - today) / (24 * 60 * 60 * 1000));
}

function foodSupplyStatus(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  if (dailyFoodGrams <= 0) return "ok";
  const days = daysUntilFinish(packageWeightKg, dailyFoodGrams, openingDateStr, ref);
  const remaining = remainingGrams(
    packageWeightKg,
    dailyFoodGrams,
    openingDateStr,
    ref
  );
  if (days <= 0 || remaining <= 0) return "critical";
  if (days >= 1 && days <= 7) return "warning";
  return "ok";
}

function canAddNewPackage(packageWeightKg, dailyFoodGrams, openingDateStr, ref) {
  if (dailyFoodGrams <= 0) return false;
  return daysUntilFinish(packageWeightKg, dailyFoodGrams, openingDateStr, ref) <= 0;
}

function computeDerivedFields(row, referenceDateStr = formatDateOnly(todayDateOnly())) {
  const packageWeightKg = Number(row.package_weight_kg);
  const dailyFoodGrams = Number(row.daily_food_grams);
  const openingDate = row.opening_date;
  const remaining = remainingGrams(
    packageWeightKg,
    dailyFoodGrams,
    openingDate,
    referenceDateStr
  );

  return {
    remaining_grams: Math.round(remaining * 100) / 100,
    remaining_weight_kg: Math.round((remaining / 1000) * 1000) / 1000,
    remaining_percent: Math.round(
      remainingPercent(packageWeightKg, dailyFoodGrams, openingDate, referenceDateStr) * 10000
    ) / 10000,
    estimated_finish_date: estimatedFinishDateStr(
      packageWeightKg,
      dailyFoodGrams,
      openingDate,
      referenceDateStr
    ),
    days_until_finish: daysUntilFinish(
      packageWeightKg,
      dailyFoodGrams,
      openingDate,
      referenceDateStr
    ),
    status: foodSupplyStatus(
      packageWeightKg,
      dailyFoodGrams,
      openingDate,
      referenceDateStr
    ),
    can_add_new_package: canAddNewPackage(
      packageWeightKg,
      dailyFoodGrams,
      openingDate,
      referenceDateStr
    )
  };
}

function mapFoodTrackingRow(row) {
  if (!row) return null;
  const openingDate = toCalendarDateString(row.opening_date);
  const derived = computeDerivedFields({ ...row, opening_date: openingDate });
  return {
    food_id: row.food_id,
    opening_date: openingDate,
    daily_food_grams: Number(row.daily_food_grams),
    package_weight_kg: Number(row.package_weight_kg),
    remaining_grams: derived.remaining_grams,
    remaining_weight_kg: derived.remaining_weight_kg,
    remaining_percent: derived.remaining_percent,
    estimated_finish_date: derived.estimated_finish_date,
    days_until_finish: derived.days_until_finish,
    status: derived.status,
    can_add_new_package: derived.can_add_new_package,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

function daysBetweenDates(fromStr, toStr) {
  const from = new Date(`${fromStr}T12:00:00.000Z`);
  const to = new Date(`${toStr}T12:00:00.000Z`);
  const diff = Math.floor((to - from) / (24 * 60 * 60 * 1000));
  return Math.max(0, Math.min(diff, 99999));
}

function addCalendarDays(dateStr, days) {
  const d = new Date(`${dateStr}T12:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return formatDateOnly(d);
}

function plannedPackageDurationDays(packageWeightKg, dailyFoodGrams) {
  const daily = Number(dailyFoodGrams);
  const grams = Number(packageWeightKg) * 1000;
  if (daily <= 0 || grams <= 0) return 0;
  return Math.ceil(grams / daily);
}

function completionDateForPackage(row, refDateStr) {
  const openingDate = toCalendarDateString(row.opening_date);
  const packageWeightKg = Number(row.package_weight_kg);
  const dailyFoodGrams = Number(row.daily_food_grams);
  const plannedDays = plannedPackageDurationDays(packageWeightKg, dailyFoodGrams);
  const plannedFinish = addCalendarDays(openingDate, plannedDays);
  const remaining = remainingGrams(
    packageWeightKg,
    dailyFoodGrams,
    openingDate,
    refDateStr
  );

  if (remaining <= 0) {
    return plannedFinish <= refDateStr ? plannedFinish : refDateStr;
  }

  return refDateStr;
}

function mapConsumptionRow(row) {
  const openingDate = toCalendarDateString(row.opening_date);
  const completionDate = toCalendarDateString(row.completion_date);
  return {
    consumption_id: row.consumption_id,
    opening_date: openingDate,
    completion_date: completionDate,
    days_lasted: daysBetweenDates(openingDate, completionDate)
  };
}

async function archiveCompletedPackage(
  userId,
  row,
  refDateStr = formatDateOnly(todayDateOnly()),
  nextPackageOpeningDate = null
) {
  const openingDate = toCalendarDateString(row.opening_date);
  let completionDate = completionDateForPackage(row, refDateStr);

  const nextOpen = toCalendarDateString(nextPackageOpeningDate);
  if (nextOpen && nextOpen >= openingDate) {
    completionDate = nextOpen;
  }

  if (!openingDate || !completionDate) return;

  const daysLasted = daysBetweenDates(openingDate, completionDate);
  if (daysLasted <= 0) return;

  await pool.query(
    `
    INSERT INTO food_package_consumption_history (
      user_id,
      opening_date,
      completion_date,
      package_weight_kg,
      daily_food_grams
    )
    VALUES ($1, $2::date, $3::date, $4, $5)
    `,
    [
      userId,
      openingDate,
      completionDate,
      Number(row.package_weight_kg),
      Number(row.daily_food_grams)
    ]
  );
}

async function getConsumptionHistoryForUser(userId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const historyRes = await pool.query(
    `
    SELECT
      consumption_id,
      to_char(opening_date, 'YYYY-MM-DD') AS opening_date,
      to_char(completion_date, 'YYYY-MM-DD') AS completion_date
    FROM food_package_consumption_history
    WHERE user_id = $1
    ORDER BY opening_date ASC
    `,
    [userId]
  );

  const records = historyRes.rows.map(mapConsumptionRow);

  const currentRes = await pool.query(
    `${FOOD_SELECT} WHERE user_id = $1 LIMIT 1`,
    [userId]
  );
  const current = currentRes.rows[0];

  if (current) {
    const ref = formatDateOnly(todayDateOnly());
    const derived = computeDerivedFields(current, ref);
    if (derived.can_add_new_package) {
      const completionDate = completionDateForPackage(current, ref);
      records.push(
        mapConsumptionRow({
          consumption_id: current.food_id,
          opening_date: current.opening_date,
          completion_date: completionDate
        })
      );
    }
  }

  const completed = records.filter((row) => row.days_lasted > 0);
  completed.sort((a, b) => a.opening_date.localeCompare(b.opening_date));

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { consumption_history: completed }
    }
  };
}

const FOOD_SELECT = `
  SELECT
    food_id,
    to_char(opening_date, 'YYYY-MM-DD') AS opening_date,
    daily_food_grams,
    package_weight_kg,
    created_at,
    updated_at
  FROM food_tracking
`;

async function assertFoodOwner(userId, foodId) {
  const r = await pool.query(
    `${FOOD_SELECT} WHERE food_id = $1 AND user_id = $2`,
    [foodId, userId]
  );
  return r.rows[0] ?? null;
}

async function getCurrentForUser(userId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const res = await pool.query(
    `${FOOD_SELECT} WHERE user_id = $1 LIMIT 1`,
    [userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: {
        food_tracking: res.rows[0] ? mapFoodTrackingRow(res.rows[0]) : null
      }
    }
  };
}

async function getForUser(userId, foodIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const foodId = Number(foodIdRaw);
  if (!Number.isInteger(foodId) || foodId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid food id." } };
  }

  const row = await assertFoodOwner(userId, foodId);
  if (!row) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Food tracking record not found." }
    };
  }

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { food_tracking: mapFoodTrackingRow(row) }
    }
  };
}

function parseCreateOrUpdateBody(body, { isReplace = false } = {}) {
  const dailyParsed = parsePositiveDecimal(body?.daily_food_grams, "daily_food_grams", {
    min: DAILY_GRAMS_MIN,
    max: DAILY_GRAMS_MAX
  });
  if (!dailyParsed.valid) {
    return {
      error: { statusCode: 400, json: { ok: false, message: dailyParsed.error } }
    };
  }

  const packageParsed = parsePositiveDecimal(body?.package_weight_kg, "package_weight_kg", {
    min: PACKAGE_KG_MIN,
    max: PACKAGE_KG_MAX
  });
  if (!packageParsed.valid) {
    return {
      error: { statusCode: 400, json: { ok: false, message: packageParsed.error } }
    };
  }

  const openingParsed = parseOpeningDate(body?.opening_date, {
    allowFuture: isReplace
  });
  if (!openingParsed.valid) {
    return {
      error: { statusCode: 400, json: { ok: false, message: openingParsed.error } }
    };
  }

  return {
    value: {
      dailyFoodGrams: dailyParsed.value,
      packageWeightKg: packageParsed.value,
      openingDate: openingParsed.value
    }
  };
}

async function createForUser(userId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const parsed = parseCreateOrUpdateBody(body);
  if (parsed.error) return parsed.error;

  const { dailyFoodGrams, packageWeightKg, openingDate } = parsed.value;

  const existing = await pool.query(
    `SELECT food_id FROM food_tracking WHERE user_id = $1`,
    [userId]
  );
  if (existing.rows.length > 0) {
    return {
      statusCode: 409,
      json: {
        ok: false,
        message: "You already have an active food tracking record."
      }
    };
  }

  const insert = await pool.query(
    `
    INSERT INTO food_tracking (
      user_id,
      opening_date,
      daily_food_grams,
      package_weight_kg
    )
    VALUES ($1, $2, $3, $4)
    RETURNING food_id,
              to_char(opening_date, 'YYYY-MM-DD') AS opening_date,
              daily_food_grams, package_weight_kg,
              created_at, updated_at
    `,
    [userId, openingDate, dailyFoodGrams, packageWeightKg]
  );

  return {
    statusCode: 201,
    json: {
      ok: true,
      data: { food_tracking: mapFoodTrackingRow(insert.rows[0]) }
    }
  };
}

async function updateForUser(userId, foodIdRaw, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const foodId = Number(foodIdRaw);
  if (!Number.isInteger(foodId) || foodId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid food id." } };
  }

  const existing = await assertFoodOwner(userId, foodId);
  if (!existing) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Food tracking record not found." }
    };
  }

  const parsed = parseCreateOrUpdateBody(body);
  if (parsed.error) return parsed.error;

  const { dailyFoodGrams, packageWeightKg, openingDate } = parsed.value;

  const updated = await pool.query(
    `
    UPDATE food_tracking
    SET
      opening_date = $1,
      daily_food_grams = $2,
      package_weight_kg = $3,
      updated_at = NOW()
    WHERE food_id = $4 AND user_id = $5
    RETURNING food_id,
              to_char(opening_date, 'YYYY-MM-DD') AS opening_date,
              daily_food_grams, package_weight_kg,
              created_at, updated_at
    `,
    [openingDate, dailyFoodGrams, packageWeightKg, foodId, userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { food_tracking: mapFoodTrackingRow(updated.rows[0]) }
    }
  };
}

async function replacePackageForUser(userId, foodIdRaw, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const foodId = Number(foodIdRaw);
  if (!Number.isInteger(foodId) || foodId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid food id." } };
  }

  const current = await assertFoodOwner(userId, foodId);
  if (!current) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Food tracking record not found." }
    };
  }

  const parsed = parseCreateOrUpdateBody(body, { isReplace: true });
  if (parsed.error) return parsed.error;

  const { dailyFoodGrams, packageWeightKg, openingDate } = parsed.value;

  const oldOpening = toCalendarDateString(current.opening_date);
  if (openingDate < oldOpening) {
    return {
      statusCode: 400,
      json: {
        ok: false,
        message: "Yeni paket açılış tarihi mevcut paketten önce olamaz."
      }
    };
  }

  await archiveCompletedPackage(userId, current, formatDateOnly(todayDateOnly()), openingDate);

  const updated = await pool.query(
    `
    UPDATE food_tracking
    SET
      opening_date = $1,
      daily_food_grams = $2,
      package_weight_kg = $3,
      updated_at = NOW()
    WHERE food_id = $4 AND user_id = $5
    RETURNING food_id,
              to_char(opening_date, 'YYYY-MM-DD') AS opening_date,
              daily_food_grams, package_weight_kg,
              created_at, updated_at
    `,
    [openingDate, dailyFoodGrams, packageWeightKg, foodId, userId]
  );

  return {
    statusCode: 200,
    json: {
      ok: true,
      data: { food_tracking: mapFoodTrackingRow(updated.rows[0]) }
    }
  };
}

async function deleteForUser(userId, foodIdRaw) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }

  const foodId = Number(foodIdRaw);
  if (!Number.isInteger(foodId) || foodId <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid food id." } };
  }

  const existing = await assertFoodOwner(userId, foodId);
  if (!existing) {
    return {
      statusCode: 404,
      json: { ok: false, message: "Food tracking record not found." }
    };
  }

  await pool.query(`DELETE FROM food_tracking WHERE food_id = $1 AND user_id = $2`, [
    foodId,
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
  getConsumptionHistoryForUser,
  createForUser,
  updateForUser,
  replacePackageForUser,
  deleteForUser
};
