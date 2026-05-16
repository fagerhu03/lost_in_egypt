#!/usr/bin/env node
/**
 * tune_accuracy.js
 * ────────────────
 * Patch-and-rerun harness for trying scoring tweaks WITHOUT editing
 * recommendation.js. Monkey-patches the pure scoring helpers, runs the
 * persona suite, and prints a comparison table.
 *
 * Usage:
 *   cd functions
 *   node scripts/tune_accuracy.js
 */

const path = require("path");
const Module = require("module");

// We need to deep-clone the module each run because we monkey-patch its constants.
// Easiest: clear the require cache before each variant.
function freshLoad() {
  delete require.cache[require.resolve("../recommendation")];
  return require("../recommendation");
}

// Identical persona suite from evaluate_accuracy.js — we just want a function
// that returns the metrics for a given module state.
function buildPersonaSuite(_internal) {
  const { applySignalToVector, rankCandidates, SIGNAL_WEIGHTS } = _internal;

  const CANDIDATES = [
    { placeId: "egmuseum",  name: "Egyptian Museum",        types: ["museum"],              tags: ["cultural","historical","ancient","pharaonic"], rating: 4.6, userRatingCount: 95000, lat: 30.0478, lng: 31.2336 },
    { placeId: "karnak",    name: "Karnak Temple",          types: ["archaeological_site","monument"], tags: ["ancient","pharaonic","historical"],   rating: 4.7, userRatingCount: 65000, lat: 25.7188, lng: 32.6573 },
    { placeId: "azharmosq", name: "Al-Azhar Mosque",        types: ["mosque"],              tags: ["religious","islamic","historical","cultural"], rating: 4.6, userRatingCount: 12000, lat: 30.0457, lng: 31.2624 },
    { placeId: "khanelk",   name: "Khan el-Khalili",        types: ["market"],              tags: ["shopping","islamic","cultural","historical"],  rating: 4.5, userRatingCount: 55000, lat: 30.0476, lng: 31.2624 },
    { placeId: "redseab",   name: "Hurghada Beach",         types: ["beach"],               tags: ["natural","relaxation","luxury"],               rating: 4.4, userRatingCount: 9500,  lat: 27.2579, lng: 33.8116 },
    { placeId: "kvalley",   name: "Valley of the Kings",    types: ["archaeological_site"], tags: ["ancient","pharaonic","historical"],            rating: 4.6, userRatingCount: 41000, lat: 25.7402, lng: 32.6014 },
    { placeId: "cairozoo",  name: "Cairo Zoo",              types: ["zoo"],                 tags: ["family","entertainment","relaxation"],         rating: 3.9, userRatingCount: 15000, lat: 30.0259, lng: 31.2160 },
    { placeId: "azharpark", name: "Al-Azhar Park",          types: ["park"],                tags: ["relaxation","family","natural"],               rating: 4.5, userRatingCount: 38000, lat: 30.0410, lng: 31.2645 },
    { placeId: "fsspa",     name: "Four Seasons Spa",       types: ["spa"],                 tags: ["luxury","relaxation"],                         rating: 4.7, userRatingCount: 1200,  lat: 30.0567, lng: 31.2192 },
    { placeId: "cairoclub", name: "Cairo Jazz Club",        types: ["night_club"],          tags: ["entertainment","modern"],                      rating: 4.3, userRatingCount: 3500,  lat: 30.0644, lng: 31.2007 },
  ];

  function buildVector(picks, dismissed = []) {
    const v = {};
    for (const p of picks) applySignalToVector(v, p.types || [], p.tags || [], SIGNAL_WEIGHTS.visit);
    for (const p of dismissed) applySignalToVector(v, p.types || [], p.tags || [], SIGNAL_WEIGHTS.dismiss);
    return v;
  }

  return [
    {
      name: "History Lover", context: "solo", hasEnoughSignals: true,
      userLat: 30.0444, userLng: 31.2357,
      tasteVector: buildVector(
        [{ types: ["museum","archaeological_site"], tags: ["historical","ancient","pharaonic","cultural"] }],
        [{ types: ["beach"], tags: ["natural"] }],
      ),
      relevance: { egmuseum: 3, karnak: 3, kvalley: 3, azharmosq: 2, khanelk: 2, azharpark: 1, cairozoo: 1, fsspa: 0, cairoclub: 0, redseab: 0 },
      assertions: { topShouldContain: ["egmuseum","karnak","kvalley"], bottomShouldContain: ["redseab"], minScoreGap: 0.05, minNdcg: 0.75 },
    },
    {
      name: "Beach Seeker", context: "solo", hasEnoughSignals: true,
      userLat: 27.2579, userLng: 33.8116,
      tasteVector: buildVector(
        [{ types: ["beach"], tags: ["natural","relaxation"] }, { types: ["spa"], tags: ["luxury","relaxation"] }],
        [{ types: ["museum"], tags: ["historical"] }],
      ),
      relevance: { redseab: 3, fsspa: 3, azharpark: 2, cairozoo: 1, khanelk: 1, cairoclub: 1, egmuseum: 0, karnak: 0, kvalley: 0, azharmosq: 0 },
      assertions: { topShouldContain: ["redseab","fsspa"], bottomShouldContain: ["egmuseum"], minScoreGap: 0.05, minNdcg: 0.75 },
    },
    {
      name: "Family Planner", context: "nearby", hasEnoughSignals: true,
      userLat: 30.0259, userLng: 31.2160,
      tasteVector: buildVector(
        [{ types: ["zoo"], tags: ["family","entertainment"] }, { types: ["park"], tags: ["family","relaxation","natural"] }],
        [{ types: ["night_club"], tags: ["entertainment"] }],
      ),
      relevance: { cairozoo: 3, azharpark: 3, khanelk: 2, redseab: 1, egmuseum: 1, karnak: 0, kvalley: 0, azharmosq: 1, fsspa: 0, cairoclub: 0 },
      assertions: { topShouldContain: ["cairozoo","azharpark"], bottomShouldContain: ["cairoclub"], minScoreGap: 0.05, minNdcg: 0.75 },
    },
    {
      name: "New User (cold-start)", context: "home", hasEnoughSignals: false,
      userLat: 30.0444, userLng: 31.2357,
      tasteVector: {},
      countryPrior: { museum: 2.5, archaeological_site: 2.8, monument: 2.2, historical_landmark: 2.1, cultural: 3.0, historical: 3.0, ancient: 2.7, pharaonic: 2.5, mosque: 1.5, islamic: 1.3, religious: 1.2 },
      relevance: { egmuseum: 3, karnak: 3, kvalley: 3, azharmosq: 2, khanelk: 2, azharpark: 1, cairozoo: 1, fsspa: 0, cairoclub: 0, redseab: 1 },
      assertions: { topShouldContain: ["egmuseum","karnak","kvalley"], bottomShouldContain: ["cairoclub"], minScoreGap: 0.05, minNdcg: 0.70 },
    },
    {
      name: "Neutral Baseline", context: "home", hasEnoughSignals: false,
      userLat: 30.0444, userLng: 31.2357,
      tasteVector: {},
      countryPrior: null,
      relevance: { egmuseum: 3, karnak: 3, kvalley: 2, khanelk: 2, azharpark: 2, azharmosq: 2, redseab: 1, cairozoo: 1, fsspa: 1, cairoclub: 1 },
      assertions: { topShouldContain: ["egmuseum","karnak"], bottomShouldContain: ["cairoclub","fsspa"], minScoreGap: 0.05, minNdcg: 0.70 },
    },
  ];
}

function ndcg(ranked, relevance, k = 5) {
  const dcg = (arr) => arr.slice(0, k).reduce((s, r, i) => s + ((Math.pow(2, r) - 1) / Math.log2(i + 2)), 0);
  const actualRel = ranked.map((r) => relevance[r.placeId] || 0);
  const idealRel = Object.values(relevance).sort((a, b) => b - a);
  const idcg = dcg(idealRel);
  return idcg === 0 ? 0 : dcg(actualRel) / idcg;
}
function scoreGap(ranked) {
  if (ranked.length < 2) return 0;
  return ranked[0].score - ranked[Math.floor(ranked.length / 2)].score;
}

function evalSuite(_internal, personas) {
  const CANDIDATES_REF = buildPersonaSuite(_internal); // rebuild because vectors use module's SIGNAL_WEIGHTS
  let passed = 0, total = 0;
  const ndcgs = [], gaps = [];
  const perPersona = [];
  for (let i = 0; i < CANDIDATES_REF.length; i++) {
    const p = CANDIDATES_REF[i];
    const ranked = _internal.rankCandidates({
      candidates: buildCandidates(),
      tasteVector: p.tasteVector,
      userLat: p.userLat, userLng: p.userLng,
      context: p.context,
      neighbors: {},
      countryPrior: p.countryPrior || null,
      hasEnoughSignals: p.hasEnoughSignals,
      seenSet: new Set(),
      limit: 10, epsilon: 0,
    });
    const topIds = ranked.slice(0, 3).map((r) => r.placeId);
    const bottomIds = ranked.slice(Math.ceil(ranked.length / 2)).map((r) => r.placeId);
    const a = p.assertions;
    const tests = [
      a.topShouldContain.some((id) => topIds.includes(id)),
      a.bottomShouldContain.some((id) => bottomIds.includes(id)),
      scoreGap(ranked) >= a.minScoreGap,
      ndcg(ranked, p.relevance, 5) >= a.minNdcg,
    ];
    const pp = tests.filter(Boolean).length;
    passed += pp; total += 4;
    ndcgs.push(ndcg(ranked, p.relevance, 5));
    gaps.push(scoreGap(ranked));
    perPersona.push({ name: p.name, passed: pp, ndcg5: ndcg(ranked, p.relevance, 5), gap: scoreGap(ranked) });
  }
  return {
    passed, total,
    accuracy: passed / total * 100,
    avgNdcg: ndcgs.reduce((a, b) => a + b, 0) / ndcgs.length,
    avgGap: gaps.reduce((a, b) => a + b, 0) / gaps.length,
    perPersona,
  };
}

function buildCandidates() {
  return [
    { placeId: "egmuseum",  name: "Egyptian Museum",        types: ["museum"],              tags: ["cultural","historical","ancient","pharaonic"], rating: 4.6, userRatingCount: 95000, lat: 30.0478, lng: 31.2336 },
    { placeId: "karnak",    name: "Karnak Temple",          types: ["archaeological_site","monument"], tags: ["ancient","pharaonic","historical"],   rating: 4.7, userRatingCount: 65000, lat: 25.7188, lng: 32.6573 },
    { placeId: "azharmosq", name: "Al-Azhar Mosque",        types: ["mosque"],              tags: ["religious","islamic","historical","cultural"], rating: 4.6, userRatingCount: 12000, lat: 30.0457, lng: 31.2624 },
    { placeId: "khanelk",   name: "Khan el-Khalili",        types: ["market"],              tags: ["shopping","islamic","cultural","historical"],  rating: 4.5, userRatingCount: 55000, lat: 30.0476, lng: 31.2624 },
    { placeId: "redseab",   name: "Hurghada Beach",         types: ["beach"],               tags: ["natural","relaxation","luxury"],               rating: 4.4, userRatingCount: 9500,  lat: 27.2579, lng: 33.8116 },
    { placeId: "kvalley",   name: "Valley of the Kings",    types: ["archaeological_site"], tags: ["ancient","pharaonic","historical"],            rating: 4.6, userRatingCount: 41000, lat: 25.7402, lng: 32.6014 },
    { placeId: "cairozoo",  name: "Cairo Zoo",              types: ["zoo"],                 tags: ["family","entertainment","relaxation"],         rating: 3.9, userRatingCount: 15000, lat: 30.0259, lng: 31.2160 },
    { placeId: "azharpark", name: "Al-Azhar Park",          types: ["park"],                tags: ["relaxation","family","natural"],               rating: 4.5, userRatingCount: 38000, lat: 30.0410, lng: 31.2645 },
    { placeId: "fsspa",     name: "Four Seasons Spa",       types: ["spa"],                 tags: ["luxury","relaxation"],                         rating: 4.7, userRatingCount: 1200,  lat: 30.0567, lng: 31.2192 },
    { placeId: "cairoclub", name: "Cairo Jazz Club",        types: ["night_club"],          tags: ["entertainment","modern"],                      rating: 4.3, userRatingCount: 3500,  lat: 30.0644, lng: 31.2007 },
  ];
}

// ── Variant patcher ──────────────────────────────────────────────────────────
//
// We can't easily monkey-patch private locals inside recommendation.js because
// they're not exposed. So instead, we wrap rankCandidates with a custom
// scoreCandidate replica that supports tweakable knobs. This duplicates
// scoring math — kept in lockstep with recommendation.js (lines 391–558).

function makeVariant(opts) {
  // opts: { proxDecay, ratingDiv, ratingMid, quizWeight, mmrCap,
  //         soloProxWeight, coldProxCap, popMul }
  const cfg = {
    proxDecay: 100,
    ratingDiv: 1.5,
    ratingMid: 3.5,
    quizWeight: 0.5,
    mmrCap: Infinity,
    soloProxWeight: 0.20,
    coldProxCap: 0.25,
    popMul: 1.0,
    ...opts,
  };

  function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371; const toRad = (d) => (d * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1); const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
  const clamp = (x, lo, hi) => Math.max(lo, Math.min(hi, x));
  function cosineSim(a, b) {
    const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
    let dot = 0, na = 0, nb = 0;
    for (const k of keys) { const va = a[k] || 0, vb = b[k] || 0; dot += va*vb; na += va*va; nb += vb*vb; }
    if (na === 0 || nb === 0) return 0;
    return dot / (Math.sqrt(na) * Math.sqrt(nb));
  }

  function scoreCandidate({ candidate, tasteVector, userLat, userLng, context, neighbors, countryPrior, hasEnoughSignals }) {
    const keys = [...(candidate.types || []), ...(candidate.tags || [])];
    let tasteMatch = 0;
    if (keys.length > 0) {
      const sum = keys.reduce((acc, k) => acc + (tasteVector[k] || 0), 0);
      tasteMatch = sum / keys.length;
    }
    tasteMatch = Math.tanh(tasteMatch / 2);

    const rating = typeof candidate.rating === "number" ? candidate.rating : cfg.ratingMid;
    const ratingScore = clamp((rating - cfg.ratingMid) / cfg.ratingDiv, -1, 1);

    let proximity = 0, distanceKm = null;
    if (typeof userLat === "number" && typeof userLng === "number" &&
        typeof candidate.lat === "number" && typeof candidate.lng === "number") {
      distanceKm = haversineKm(userLat, userLng, candidate.lat, candidate.lng);
      proximity = Math.exp(-distanceKm / cfg.proxDecay);
    }

    const urc = Number(candidate.userRatingCount || 0);
    const popularity = clamp((Math.log10(1 + urc) / 4) * cfg.popMul, 0, 1);

    const collab = neighbors && neighbors[candidate.placeId] ? neighbors[candidate.placeId] : 0;

    let priorScore = 0;
    if (countryPrior && !hasEnoughSignals) {
      const cPrior = {};
      for (const k of keys) cPrior[k] = 1;
      priorScore = cosineSim(cPrior, countryPrior);
    }

    let w = { taste: 0.40, rating: 0.15, proximity: cfg.soloProxWeight, popularity: 0.10, collab: 0.15 };
    if (context === "nearby") w = { ...w, proximity: 0.30, taste: 0.30 };
    if (context === "similar") w = { ...w, collab: 0.30, taste: 0.30 };
    if (context === "home")  w = { taste: 0.25, rating: 0.10, proximity: 0.45, popularity: 0.05, collab: 0.15 };
    if (context === "tours") w = { taste: 0.40, rating: 0.20, proximity: 0.10, popularity: 0.15, collab: 0.15 };

    if (!hasEnoughSignals && countryPrior) {
      w = { ...w, taste: 0.10 };
      if (w.proximity > cfg.coldProxCap) w.proximity = cfg.coldProxCap;
    }

    const score = w.taste * tasteMatch + w.rating * ratingScore +
      w.proximity * proximity + w.popularity * popularity + w.collab * collab +
      (!hasEnoughSignals && countryPrior ? 0.30 * priorScore : 0);

    return { score, breakdown: { tasteMatch, ratingScore, proximity, popularity, collab, priorScore, distanceKm }, reasons: [] };
  }

  function rankCandidates({ candidates, tasteVector, userLat, userLng, context, neighbors = {}, countryPrior = null, hasEnoughSignals = false, seenSet = new Set(), limit = 10 }) {
    const fresh = candidates.filter((c) => c.placeId && !seenSet.has(c.placeId));
    const scored = fresh.map((c) => ({ candidate: c, ...scoreCandidate({ candidate: c, tasteVector, userLat, userLng, context, neighbors, countryPrior, hasEnoughSignals }) }));
    scored.sort((a, b) => b.score - a.score);
    const typeCounts = {};
    for (const s of scored) {
      const primary = (s.candidate.types && s.candidate.types[0]) || "unknown";
      const repeats = typeCounts[primary] || 0;
      const cappedRepeats = Math.min(repeats, cfg.mmrCap);
      const penalty = cappedRepeats * 0.05;
      s.adjustedScore = s.score - penalty;
      typeCounts[primary] = repeats + 1;
    }
    scored.sort((a, b) => b.adjustedScore - a.adjustedScore);
    return scored.slice(0, limit).map((s, i) => ({
      placeId: s.candidate.placeId, name: s.candidate.name,
      score: Number(s.adjustedScore.toFixed(4)), rank: i,
    }));
  }

  // Apply quiz weight by overriding SIGNAL_WEIGHTS just-for-vector-build via closure
  const SIGNAL_WEIGHTS = { visit: 1.0, booking: 0.8, save: 0.6, post: 0.5, like: 0.4, quiz: cfg.quizWeight, dismiss: -0.3, view: -0.1 };
  function applySignalToVector(vector, types, tags, weight) {
    const keys = [...types, ...tags];
    for (const k of keys) vector[k] = (vector[k] || 0) + weight;
    return vector;
  }

  return { _internal: { rankCandidates, applySignalToVector, SIGNAL_WEIGHTS } };
}

// ── Run all variants ─────────────────────────────────────────────────────────

const VARIANTS = [
  { label: "Baseline (after cold-start fix)", opts: {} },
  { label: "B: rating /1.0, mid 4.0",         opts: { ratingDiv: 1.0, ratingMid: 4.0 } },
  { label: "B': rating /1.2, mid 3.5",        opts: { ratingDiv: 1.2 } },
  { label: "E: solo proximity 0.10",          opts: { soloProxWeight: 0.10 } },
  { label: "F: cold-start prox cap 0.10",     opts: { coldProxCap: 0.10 } },
  { label: "G: popularity ×1.5 (cap 1.0)",    opts: { popMul: 1.5 } },
  { label: "E+F: solo+cold prox lowered",     opts: { soloProxWeight: 0.10, coldProxCap: 0.10 } },
  { label: "E+F+B'",                          opts: { soloProxWeight: 0.10, coldProxCap: 0.10, ratingDiv: 1.2 } },
  { label: "E+F+B+G (aggressive)",            opts: { soloProxWeight: 0.10, coldProxCap: 0.10, ratingDiv: 1.0, ratingMid: 4.0, popMul: 1.5 } },
];

console.log("");
console.log("═══════════════════════════════════════════════════════════════════════════════");
console.log("  Variant tuning — accuracy + NDCG@5 over all 5 personas");
console.log("═══════════════════════════════════════════════════════════════════════════════");
console.log("");
console.log("Variant".padEnd(38) + " | Acc%  | NDCG@5 | Gap   | per-persona NDCG@5");
console.log("─".repeat(108));
for (const v of VARIANTS) {
  const mod = makeVariant(v.opts);
  const r = evalSuite(mod._internal);
  const perP = r.perPersona.map((p) => `${p.name.split(" ")[0]}:${p.ndcg5.toFixed(2)}`).join(" ");
  console.log(
    v.label.padEnd(38) +
    ` | ${r.accuracy.toFixed(1)}%` +
    ` | ${r.avgNdcg.toFixed(3)}` +
    `  | ${r.avgGap.toFixed(3)}` +
    ` | ${perP}`
  );
}
console.log("");
