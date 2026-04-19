#!/usr/bin/env node
/**
 * Sample-output runner for the recommendation engine.
 *
 * Runs the pure scoring core against a hardcoded fake user + a slice of
 * assets/final_places_clean_v2.json — no Firebase credentials, no deploy,
 * no emulator needed. Proves the engine works end-to-end.
 *
 * Usage:
 *   cd functions
 *   node scripts/sample_recommendation.js
 *
 * Optional flags:
 *   --context=nearby|solo|similar|home   (default: solo)
 *   --user=history|foodie|family|chill   (preset taste profile)
 *   --lat=30.0444 --lng=31.2357          (default: central Cairo)
 *   --limit=10
 */

const fs = require("fs");
const path = require("path");
const { _internal } = require("../recommendation");

const { rankCandidates, applySignalToVector, SIGNAL_WEIGHTS } = _internal;

// ── CLI args ─────────────────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v === undefined ? true : v];
  })
);
const CONTEXT = args.context || "solo";
const USER = args.user || "history";
const USER_LAT = Number(args.lat || 30.0444);
const USER_LNG = Number(args.lng || 31.2357);
const LIMIT = Number(args.limit || 10);

// ── Preset taste profiles (simulates a completed quiz) ───────────────────────
const PROFILES = {
  history: [
    { types: ["museum", "archaeological_site", "monument"], tags: ["historical", "ancient", "pharaonic", "cultural"] },
    { types: ["historical_landmark"], tags: ["cultural"] },
  ],
  foodie: [
    { types: ["restaurant", "cafe", "market"], tags: ["food", "cultural"] },
    { types: ["shopping_mall", "market"], tags: ["shopping"] },
  ],
  family: [
    { types: ["zoo", "amusement_park", "aquarium", "park"], tags: ["family", "entertainment", "relaxation"] },
    { types: ["beach"], tags: ["natural", "relaxation"] },
  ],
  chill: [
    { types: ["park", "beach", "spa"], tags: ["relaxation", "natural", "luxury"] },
  ],
};

function buildTasteVector(presetKey) {
  const picks = PROFILES[presetKey];
  if (!picks) throw new Error(`Unknown user preset: ${presetKey}`);
  const v = {};
  for (const pick of picks) {
    applySignalToVector(v, pick.types, pick.tags, SIGNAL_WEIGHTS.quiz);
  }
  return v;
}

// ── Load candidates from the JSON fallback dataset ───────────────────────────
const jsonPath = path.resolve(__dirname, "../../assets/final_places_clean_v2.json");
if (!fs.existsSync(jsonPath)) {
  console.error(`Cannot find ${jsonPath}. Run from repo root or adjust path.`);
  process.exit(1);
}
const rawPlaces = JSON.parse(fs.readFileSync(jsonPath, "utf8"));

// Map JSON category to canonical Places API types
const CATEGORY_MAP = {
  tourism: ["tourist_attraction"],
  education: ["museum"],
  religious: ["mosque", "church"],
  shopping: ["shopping_mall", "market"],
  food: ["restaurant", "cafe"],
  entertainment: ["night_club", "amusement_park"],
  nature: ["park", "beach"],
  culture: ["art_gallery", "museum"],
};

// Deterministic hash so repeated runs produce identical fake ratings.
function seededFloat(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return ((h >>> 0) % 10000) / 10000; // 0..1
}

// JSON file has rating==4.5 for every place — useless for a demo. Synthesize
// varied but deterministic ratings/review-counts from id + importance so the
// engine's rating+popularity signals actually differentiate results.
function syntheticRating(p) {
  const base = 2.8 + seededFloat(p.id + "_r") * 1.8; // 2.8..4.6
  const bump = Math.min((p.importance || 5) / 25, 0.4); // up to +0.4 for famous sites
  return Math.min(5.0, Math.round((base + bump) * 10) / 10);
}
function syntheticReviewCount(p) {
  const pop = Math.floor(seededFloat(p.id + "_c") * 4000); // 0..4000
  const importanceBoost = (p.importance || 5) * 50;
  return pop + importanceBoost;
}

function toCandidate(p) {
  const categoryRaw = (p.category || "").toLowerCase();
  const types = CATEGORY_MAP[categoryRaw] || ["tourist_attraction"];
  return {
    placeId: p.id,
    name: p.title,
    types,
    tags: Array.isArray(p.tags) ? p.tags : [],
    rating: syntheticRating(p),
    userRatingCount: syntheticReviewCount(p),
    lat: p.coordinate?.latitude,
    lng: p.coordinate?.longitude,
  };
}

const candidates = rawPlaces
  .filter((p) => p.coordinate && typeof p.coordinate.latitude === "number")
  .slice(0, 150)
  .map(toCandidate);

// ── Run scoring ──────────────────────────────────────────────────────────────
const tasteVector = buildTasteVector(USER);
const result = rankCandidates({
  candidates,
  tasteVector,
  userLat: USER_LAT,
  userLng: USER_LNG,
  context: CONTEXT,
  neighbors: {},
  countryPrior: null,
  hasEnoughSignals: true,   // simulate post-quiz user
  seenSet: new Set(),
  limit: LIMIT,
  epsilon: 0,               // disable randomness for deterministic demo
});

// ── Pretty-print ─────────────────────────────────────────────────────────────
console.log("");
console.log("═══ Lost in Egypt — Recommendation Engine Sample Output ═══");
console.log(`User preset   : ${USER}`);
console.log(`Context       : ${CONTEXT}`);
console.log(`Location      : (${USER_LAT}, ${USER_LNG})`);
console.log(`Candidates    : ${candidates.length}`);
console.log(`Returning top : ${LIMIT}`);
console.log("");
console.log("Taste vector (non-zero keys):");
const nonZero = Object.entries(tasteVector).sort((a, b) => b[1] - a[1]);
for (const [k, v] of nonZero) {
  console.log(`   ${k.padEnd(22)} ${v.toFixed(2)}`);
}
console.log("");
console.log("Recommendations:");
console.log("─".repeat(80));
for (const r of result) {
  const km = r.breakdown.distanceKm != null ? `${r.breakdown.distanceKm.toFixed(1)} km` : "—";
  console.log(`#${String(r.rank + 1).padStart(2)}  [${r.score.toFixed(3)}]  ${r.name}`);
  console.log(`     ${km.padEnd(10)}  ${r.reasons.join(" · ") || "(no strong signals)"}`);
  console.log(`     taste=${r.breakdown.tasteMatch?.toFixed(2)} ` +
              `rating=${r.breakdown.ratingScore?.toFixed(2)} ` +
              `prox=${r.breakdown.proximity?.toFixed(2)} ` +
              `pop=${r.breakdown.popularity?.toFixed(2)}`);
  console.log("");
}
