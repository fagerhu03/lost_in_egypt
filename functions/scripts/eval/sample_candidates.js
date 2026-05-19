/**
 * sample_candidates.js
 * ────────────────────
 * Loads the fixture pool used by the evaluation harness. Today the fixture is
 * a hand-curated set of ~80 Egyptian places with canonical types/tags
 * (`candidates_fixture.json` in this directory). The hand-curation step is
 * deliberate — it avoids the noise of normalising the offline asset
 * `assets/final_places_clean_v2.json`, whose category labels are not in the
 * scoring engine's canonical key set.
 *
 * When the team wants to swap in a Places-API snapshot exported from the
 * `places_snapshot/v1_shard_*` Firestore collection, drop a JSON file with the
 * same shape into this directory and call `loadFromFile(path)` instead.
 *
 * Shape expected per item:
 *   { placeId, name, types[], tags[], rating, userRatingCount, lat, lng, region? }
 *
 * `region` is an evaluation-only field used by some persona definitions to
 * pre-filter the candidate set (e.g. "Luxor nearby" persona only sees
 * candidates within ~50 km of Luxor). The production scorer does NOT read it.
 */

const fs = require("fs");
const path = require("path");

const DEFAULT_FIXTURE = path.join(__dirname, "candidates_fixture.json");

function loadFromFile(filePath = DEFAULT_FIXTURE) {
  const raw = fs.readFileSync(filePath, "utf8");
  const arr = JSON.parse(raw);
  if (!Array.isArray(arr)) {
    throw new Error(`Expected an array in ${filePath}, got ${typeof arr}`);
  }
  return arr;
}

/**
 * Stratified sample by primary type. Useful if the caller wants a smaller
 * working set but doesn't want to drop entire categories.
 */
function stratifiedSample(candidates, targetSize, rng = Math.random) {
  if (candidates.length <= targetSize) return [...candidates];
  const byType = {};
  for (const c of candidates) {
    const primary = (c.types && c.types[0]) || "unknown";
    if (!byType[primary]) byType[primary] = [];
    byType[primary].push(c);
  }
  const types = Object.keys(byType);
  const perTypeQuota = Math.max(1, Math.floor(targetSize / types.length));
  const out = [];
  for (const t of types) {
    const pool = byType[t];
    const shuffled = [...pool].sort(() => rng() - 0.5);
    for (const item of shuffled.slice(0, perTypeQuota)) out.push(item);
  }
  // Fill remaining slots randomly across leftover items
  const remaining = candidates.filter((c) => !out.includes(c));
  const shuffledRem = remaining.sort(() => rng() - 0.5);
  while (out.length < targetSize && shuffledRem.length > 0) {
    out.push(shuffledRem.pop());
  }
  return out.slice(0, targetSize);
}

module.exports = {
  DEFAULT_FIXTURE,
  loadFromFile,
  stratifiedSample,
};
