const { pool, dbNotConfiguredPayload } = require("../db");
const { isNonEmptyString } = require("../utils/validators");

const NAME_MIN = 2;
const NAME_MAX = 30;
const WEIGHT_MIN = 0.5;
const WEIGHT_MAX = 25;

function mapCatRow(row) {
  if (!row) return null;
  return {
    cat_id: row.cat_id,
    user_id: row.user_id,
    breed_id: row.breed_id,
    name: row.name,
    birth_date: row.birth_date,
    weight: row.weight != null ? Number(row.weight) : null,
    gender: row.gender,
    is_neutered: row.is_neutered,
    notes: row.notes,
    created_at: row.created_at,
    updated_at: row.updated_at,
    breed_name: row.breed_name,
    slug: row.slug,
    avatar_url: row.avatar_url
  };
}

function validateName(name) {
  if (!isNonEmptyString(name)) {
    return { valid: false, error: "Name is required." };
  }
  const t = name.trim();
  if (t.length < NAME_MIN || t.length > NAME_MAX) {
    return {
      valid: false,
      error: `Name must be between ${NAME_MIN} and ${NAME_MAX} characters.`
    };
  }
  return { valid: true, value: t };
}

function parseDateOnly(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "Birth date is required." };
  }
  const s = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    return { valid: false, error: "Birth date must be YYYY-MM-DD." };
  }
  const d = new Date(`${s}T12:00:00.000Z`);
  if (Number.isNaN(d.getTime())) {
    return { valid: false, error: "Birth date is invalid." };
  }
  const today = new Date();
  today.setUTCHours(23, 59, 59, 999);
  if (d.getTime() > today.getTime()) {
    return { valid: false, error: "Birth date cannot be in the future." };
  }
  return { valid: true, value: s };
}

function parseGender(value) {
  if (!isNonEmptyString(value)) {
    return { valid: false, error: "Gender is required." };
  }
  const g = value.trim().toLowerCase();
  if (g !== "male" && g !== "female") {
    return { valid: false, error: "Gender must be male or female." };
  }
  return { valid: true, value: g };
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

function parseNeutered(value) {
  if (value === undefined || value === null) {
    return { valid: false, error: "Neutered status is required." };
  }
  if (typeof value === "boolean") {
    return { valid: true, value };
  }
  if (value === "true" || value === "false") {
    return { valid: true, value: value === "true" };
  }
  return { valid: false, error: "is_neutered must be a boolean." };
}

function parseBreedId(value) {
  if (value === undefined || value === null || value === "") {
    return { valid: false, error: "breed_id is required." };
  }
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    return { valid: false, error: "breed_id must be a positive integer." };
  }
  return { valid: true, value: id };
}

async function breedExists(breedId) {
  const r = await pool.query(`SELECT breed_id FROM cat_breeds WHERE breed_id = $1`, [breedId]);
  return r.rows.length > 0;
}

async function assertCatOwner(userId, catId) {
  const r = await pool.query(
    `SELECT * FROM cats WHERE cat_id = $1 AND user_id = $2`,
    [catId, userId]
  );
  return r.rows[0] ?? null;
}

/** Migration uygulanmadıysa `slug` sütunu olmayabilir; sorgu hata vermesin. */
let _catBreedsHasSlug = null;

async function catBreedsHasSlugColumn() {
  if (_catBreedsHasSlug !== null) return _catBreedsHasSlug;
  if (!pool) {
    _catBreedsHasSlug = false;
    return false;
  }
  try {
    const r = await pool.query(
      `SELECT 1
       FROM information_schema.columns
       WHERE table_schema = current_schema()
         AND table_name = 'cat_breeds'
         AND column_name = 'slug'
       LIMIT 1`
    );
    _catBreedsHasSlug = r.rows.length > 0;
  } catch {
    _catBreedsHasSlug = false;
  }
  return _catBreedsHasSlug;
}

function buildJoinSelect(hasSlug) {
  const slugExpr = hasSlug ? "b.slug AS slug" : "NULL::text AS slug";
  return `
  SELECT
    c.cat_id,
    c.user_id,
    c.breed_id,
    c.name,
    c.birth_date,
    c.weight,
    c.gender,
    c.is_neutered,
    c.notes,
    c.created_at,
    c.updated_at,
    b.breed_name AS breed_name,
    ${slugExpr},
    b.avatar_url AS avatar_url
  FROM cats c
  LEFT JOIN cat_breeds b ON c.breed_id = b.breed_id
`;
}

async function listBreeds() {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const hasSlug = await catBreedsHasSlugColumn();
  const sql = hasSlug
    ? `SELECT breed_id, slug, breed_name, avatar_url
       FROM cat_breeds
       ORDER BY breed_name ASC`
    : `SELECT breed_id, breed_name, avatar_url
       FROM cat_breeds
       ORDER BY breed_name ASC`;
  const r = await pool.query(sql);
  const breeds = hasSlug ? r.rows : r.rows.map((row) => ({ ...row, slug: null }));
  return {
    statusCode: 200,
    json: { ok: true, data: { breeds } }
  };
}

async function listCats(userId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const hasSlug = await catBreedsHasSlugColumn();
  const r = await pool.query(
    `${buildJoinSelect(hasSlug)}
     WHERE c.user_id = $1
     ORDER BY c.created_at DESC`,
    [userId]
  );
  return {
    statusCode: 200,
    json: { ok: true, data: { cats: r.rows.map(mapCatRow) } }
  };
}

async function getCat(userId, catId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const id = Number(catId);
  if (!Number.isInteger(id) || id <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid cat id." } };
  }
  const hasSlug = await catBreedsHasSlugColumn();
  const r = await pool.query(
    `${buildJoinSelect(hasSlug)} WHERE c.cat_id = $1 AND c.user_id = $2`,
    [id, userId]
  );
  const row = r.rows[0];
  if (!row) {
    return { statusCode: 404, json: { ok: false, message: "Cat not found." } };
  }
  return { statusCode: 200, json: { ok: true, data: { cat: mapCatRow(row) } } };
}

async function createCat(userId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const b = body ?? {};

  const nameR = validateName(b.name);
  if (!nameR.valid) {
    return { statusCode: 400, json: { ok: false, message: nameR.error } };
  }

  const breedR = parseBreedId(b.breed_id);
  if (!breedR.valid) {
    return { statusCode: 400, json: { ok: false, message: breedR.error } };
  }
  if (!(await breedExists(breedR.value))) {
    return { statusCode: 400, json: { ok: false, message: "Invalid breed_id." } };
  }

  const dateR = parseDateOnly(b.birth_date);
  if (!dateR.valid) {
    return { statusCode: 400, json: { ok: false, message: dateR.error } };
  }

  const gR = parseGender(b.gender);
  if (!gR.valid) {
    return { statusCode: 400, json: { ok: false, message: gR.error } };
  }

  const wR = parseWeight(b.weight);
  if (!wR.valid) {
    return { statusCode: 400, json: { ok: false, message: wR.error } };
  }

  const nR = parseNeutered(b.is_neutered);
  if (!nR.valid) {
    return { statusCode: 400, json: { ok: false, message: nR.error } };
  }

  const insert = await pool.query(
    `
    INSERT INTO cats (user_id, breed_id, name, birth_date, weight, gender, is_neutered)
    VALUES ($1, $2, $3, $4::date, $5, $6, $7)
    RETURNING cat_id
    `,
    [userId, breedR.value, nameR.value, dateR.value, wR.value, gR.value, nR.value]
  );
  const newId = insert.rows[0].cat_id;
  return getCat(userId, newId);
}

async function updateCat(userId, catId, body) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const id = Number(catId);
  if (!Number.isInteger(id) || id <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid cat id." } };
  }

  const existing = await assertCatOwner(userId, id);
  if (!existing) {
    return { statusCode: 404, json: { ok: false, message: "Cat not found." } };
  }

  const b = body ?? {};
  const keysWithValues = Object.keys(b).filter(
    (k) => b[k] !== undefined && b[k] !== null
  );
  const disallowed = keysWithValues.filter((k) => k !== "weight");
  if (disallowed.length > 0) {
    return {
      statusCode: 400,
      json: {
        ok: false,
        message:
          "Only weight may be updated; neutered status and other fields cannot be changed.",
        fields: disallowed
      }
    };
  }

  if (!keysWithValues.includes("weight")) {
    return {
      statusCode: 400,
      json: { ok: false, message: "weight is required." }
    };
  }

  const wR = parseWeight(b.weight);
  if (!wR.valid) {
    return { statusCode: 400, json: { ok: false, message: wR.error } };
  }

  await pool.query(
    `UPDATE cats SET weight = $1 WHERE cat_id = $2 AND user_id = $3`,
    [wR.value, id, userId]
  );

  return getCat(userId, id);
}

async function deleteCat(userId, catId) {
  if (!pool) {
    return { statusCode: 500, json: dbNotConfiguredPayload() };
  }
  const id = Number(catId);
  if (!Number.isInteger(id) || id <= 0) {
    return { statusCode: 400, json: { ok: false, message: "Invalid cat id." } };
  }
  const r = await pool.query(`DELETE FROM cats WHERE cat_id = $1 AND user_id = $2 RETURNING cat_id`, [
    id,
    userId
  ]);
  if (r.rows.length === 0) {
    return { statusCode: 404, json: { ok: false, message: "Cat not found." } };
  }
  return {
    statusCode: 200,
    json: { ok: true, message: "Cat deleted.", data: { cat_id: id } }
  };
}

module.exports = {
  listBreeds,
  listCats,
  getCat,
  createCat,
  updateCat,
  deleteCat
};
