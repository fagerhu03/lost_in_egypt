#!/usr/bin/env node
/**
 * evaluate_accuracy.js
 * ────────────────────
 * Reproduces (and verifies) the accuracy claims in Chapter III of the
 * graduation report against the *actual* code in functions/recommendation.js.
 *
 * Implements the 5 personas + 10-place candidate pool described in §3.2.3–3.2.4
 * of the report, and computes:
 *   • Top-k Precision  (k=3)
 *   • Bottom-k Precision  (disliked types in lower half)
 *   • Score gap (top − median)
 *   • NDCG@5
 *
 * Run:
 *   cd functions
 *   node scripts/evaluate_accuracy.js
 */

const { _internal } = require("../recommendation");
const { rankCandidates, applySignalToVector, scoreCandidate, SIGNAL_WEIGHTS } = _internal;

// ── 10-place candidate pool (Egypt) ──────────────────────────────────────────
// Coordinates pulled from Google Maps.
const CANDIDATES = [
  { placeId: "egmuseum",  name: "Egyptian Museum",        types: ["museum"],              tags: ["cultural","historical","ancient","pharaonic"], rating: 4.6, userRatingCount: 95000, lat: 30.0478, lng: 31.2336 },
  { placeId: "karnak",    name: "Karnak Temple",          types: ["archaeological_site","monument"], tags: ["ancient","pharaonic","historical"],   rating: 4.7, userRatingCount: 65000, lat: 25.7188, lng: 32.6573 },
  { placeId: "azharmosq", name: "Al-Azhar Mosque",        types: ["mosque"],              tags: ["religious","islamic","historical","cultural"], rating: 4.6, userRatingCount: 12000, lat: 30.0457, lng: 31.2624 },
  { placeId: "khanelk",   name: "Khan el-Khalili",        types: ["market"],              tags: ["shopping","islamic","cultural","historical"],  rating: 4.5, userRatingCount: 55000, lat: 30.0476, lng: 31.2624 },
  { placeId: "redseab",   name: "Hurghada Beach",         types: ["beach"],               tags: ["natural","relaxation","luxury"],               rating: 4.4, userRatingCount: 9500,  lat: 27.2579, lng: 33.8116 },
  { placeId: "kvalley",   name: "Valley of the Kings",    types: ["archaeological_site"], tags: ["ancient","pharaonic","historical"],            rating: 4.6, userRatingCount: 41000, lat: 25.7402, lng: 32.6014 },
  { placeId: "cairozoo",  name: "Cairo Zoo",              types: ["zoo"],                 tags: ["family","entertainment","relaxation"],         rating: 3.9, userRatingCount: 15000, lat: 30.0259, lng: 31.2160 },
  { placeId: "azharpark", name: "Al-Azhar Park",          types: ["park"],                tags: ["relaxation","family","natural"],               rating: 4.5, userRatingCount: 38000, lat: 30.0410, lng: 31.2645 },
  { placeId: "fsspa",     name: "Four Seasons Spa",       types: ["spa"],                 tags: ["luxury","relaxation"],                          rating: 4.7, userRatingCount: 1200,  lat: 30.0567, lng: 31.2192 },
  { placeId: "cairoclub", name: "Cairo Jazz Club",        types: ["night_club"],          tags: ["entertainment","modern"],                      rating: 4.3, userRatingCount: 3500,  lat: 30.0644, lng: 31.2007 },
];

// ── Helpers ──────────────────────────────────────────────────────────────────
function buildVector(quizPicks, dismissed = []) {
  const v = {};
  for (const p of quizPicks) {
    applySignalToVector(v, p.types || [], p.tags || [], SIGNAL_WEIGHTS.visit);
  }
  for (const p of dismissed) {
    applySignalToVector(v, p.types || [], p.tags || [], SIGNAL_WEIGHTS.dismiss);
  }
  return v;
}

function ndcg(ranked, relevance, k = 5) {
  // relevance: map placeId → relevance score in [0,3]; missing = 0
  const dcg = (arr) =>
    arr.slice(0, k).reduce((s, r, i) => s + ((Math.pow(2, r) - 1) / Math.log2(i + 2)), 0);
  const actualRel  = ranked.map((r) => relevance[r.placeId] || 0);
  const idealRel   = Object.values(relevance).sort((a, b) => b - a);
  const idcg = dcg(idealRel);
  return idcg === 0 ? 0 : dcg(actualRel) / idcg;
}

function scoreGap(ranked) {
  if (ranked.length < 2) return 0;
  const top = ranked[0].score;
  const median = ranked[Math.floor(ranked.length / 2)].score;
  return top - median;
}

// ── Personas (from PDF §3.2.3) ───────────────────────────────────────────────
const PERSONAS = [
  {
    name: "History Lover",
    context: "solo",
    hasEnoughSignals: true,
    userLat: 30.0444, userLng: 31.2357, // Cairo
    tasteVector: buildVector(
      [{ types: ["museum","archaeological_site"], tags: ["historical","ancient","pharaonic","cultural"] }],
      [{ types: ["beach"], tags: ["natural"] }],
    ),
    // Expected relevance for NDCG (0=irrelevant, 3=perfect)
    relevance: {
      egmuseum: 3, karnak: 3, kvalley: 3, azharmosq: 2, khanelk: 2,
      azharpark: 1, cairozoo: 1, fsspa: 0, cairoclub: 0, redseab: 0,
    },
    assertions: {
      // 4 assertions per persona, as in PDF
      topShouldContain: ["egmuseum","karnak","kvalley"], // any in top-3
      bottomShouldContain: ["redseab"],                  // disliked in lower half
      minScoreGap: 0.05,
      minNdcg: 0.75,
    },
  },
  {
    name: "Beach Seeker",
    context: "solo",
    hasEnoughSignals: true,
    userLat: 27.2579, userLng: 33.8116, // Hurghada
    tasteVector: buildVector(
      [
        { types: ["beach"], tags: ["natural","relaxation"] },
        { types: ["spa"], tags: ["luxury","relaxation"] },
      ],
      [{ types: ["museum"], tags: ["historical"] }],
    ),
    relevance: {
      redseab: 3, fsspa: 3, azharpark: 2, cairozoo: 1, khanelk: 1,
      cairoclub: 1, egmuseum: 0, karnak: 0, kvalley: 0, azharmosq: 0,
    },
    assertions: {
      topShouldContain: ["redseab","fsspa"],
      bottomShouldContain: ["egmuseum"],
      minScoreGap: 0.05,
      minNdcg: 0.75,
    },
  },
  {
    name: "Family Planner",
    context: "nearby",
    hasEnoughSignals: true,
    userLat: 30.0259, userLng: 31.2160, // adjacent Cairo Zoo
    tasteVector: buildVector(
      [
        { types: ["zoo"], tags: ["family","entertainment"] },
        { types: ["park"], tags: ["family","relaxation","natural"] },
      ],
      [{ types: ["night_club"], tags: ["entertainment"] }],
    ),
    relevance: {
      cairozoo: 3, azharpark: 3, khanelk: 2, redseab: 1, egmuseum: 1,
      karnak: 0, kvalley: 0, azharmosq: 1, fsspa: 0, cairoclub: 0,
    },
    assertions: {
      topShouldContain: ["cairozoo","azharpark"],
      bottomShouldContain: ["cairoclub"],
      minScoreGap: 0.05,
      minNdcg: 0.75,
    },
  },
  {
    name: "New User (cold-start)",
    context: "home",
    hasEnoughSignals: false,
    userLat: 30.0444, userLng: 31.2357,
    tasteVector: {}, // no signals
    countryPrior: {
      // Egyptian-tourist priors: high on heritage/cultural categories
      museum: 2.5, archaeological_site: 2.8, monument: 2.2, historical_landmark: 2.1,
      cultural: 3.0, historical: 3.0, ancient: 2.7, pharaonic: 2.5,
      mosque: 1.5, islamic: 1.3, religious: 1.2,
    },
    relevance: {
      egmuseum: 3, karnak: 3, kvalley: 3, azharmosq: 2, khanelk: 2,
      azharpark: 1, cairozoo: 1, fsspa: 0, cairoclub: 0, redseab: 1,
    },
    assertions: {
      topShouldContain: ["egmuseum","karnak","kvalley"],
      bottomShouldContain: ["cairoclub"],
      minScoreGap: 0.05,
      minNdcg: 0.70,
    },
  },
  {
    name: "Neutral Baseline",
    context: "home",
    hasEnoughSignals: false,
    userLat: 30.0444, userLng: 31.2357,
    tasteVector: {},
    countryPrior: null, // no prior — rating + popularity govern
    relevance: {
      // Without taste, ground-truth relevance is essentially rating + popularity
      egmuseum: 3, karnak: 3, kvalley: 2, khanelk: 2, azharpark: 2,
      azharmosq: 2, redseab: 1, cairozoo: 1, fsspa: 1, cairoclub: 1,
    },
    assertions: {
      topShouldContain: ["egmuseum","karnak"],
      bottomShouldContain: ["cairoclub","fsspa"],
      minScoreGap: 0.05,
      minNdcg: 0.70,
    },
  },
];

// ── Run evaluation ───────────────────────────────────────────────────────────
function evaluatePersona(persona) {
  const ranked = rankCandidates({
    candidates: CANDIDATES,
    tasteVector: persona.tasteVector,
    userLat: persona.userLat,
    userLng: persona.userLng,
    context: persona.context,
    neighbors: {},
    countryPrior: persona.countryPrior || null,
    hasEnoughSignals: persona.hasEnoughSignals,
    seenSet: new Set(),
    limit: 10,
    epsilon: 0, // deterministic for evaluation
  });

  const topIds = ranked.slice(0, 3).map((r) => r.placeId);
  const bottomIds = ranked.slice(Math.ceil(ranked.length / 2)).map((r) => r.placeId);

  const a = persona.assertions;
  const tests = {
    topContains: a.topShouldContain.some((id) => topIds.includes(id)),
    bottomContains: a.bottomShouldContain.some((id) => bottomIds.includes(id)),
    scoreGapOk: scoreGap(ranked) >= a.minScoreGap,
    ndcgOk: ndcg(ranked, persona.relevance, 5) >= a.minNdcg,
  };
  const passed = Object.values(tests).filter(Boolean).length;
  const ndcg5 = ndcg(ranked, persona.relevance, 5);
  const gap = scoreGap(ranked);

  return { persona: persona.name, ranked, tests, passed, ndcg5, scoreGap: gap };
}

console.log("");
console.log("═══ Lost in Egypt — Recommendation Engine Accuracy Evaluation ═══");
console.log("    (reproducing Chapter III §3.3 test methodology)");
console.log("");

let totalPassed = 0, totalTests = 0;
const ndcgs = [];
const gaps = [];

for (const p of PERSONAS) {
  const r = evaluatePersona(p);
  totalPassed += r.passed;
  totalTests += 4;
  ndcgs.push(r.ndcg5);
  gaps.push(r.scoreGap);

  console.log(`── ${r.persona} (context=${p.context}, hasSignals=${p.hasEnoughSignals})`);
  console.log(`   Top 3: ${r.ranked.slice(0, 3).map((x) => `${x.name}(${x.score.toFixed(3)})`).join(", ")}`);
  console.log(`   Bot 2: ${r.ranked.slice(-2).map((x) => `${x.name}(${x.score.toFixed(3)})`).join(", ")}`);
  console.log(`   NDCG@5=${r.ndcg5.toFixed(3)}   gap=${r.scoreGap.toFixed(3)}`);
  console.log(`   Tests passed: ${r.passed}/4   ` +
    Object.entries(r.tests).map(([k, v]) => `${k}=${v ? "✓" : "✗"}`).join("  "));
  console.log("");
}

const avgNdcg = ndcgs.reduce((a, b) => a + b, 0) / ndcgs.length;
const avgGap  = gaps.reduce((a, b) => a + b, 0) / gaps.length;
const accuracy = (totalPassed / totalTests) * 100;

console.log("─".repeat(60));
console.log(`OVERALL: ${totalPassed}/${totalTests} = ${accuracy.toFixed(1)}% accuracy`);
console.log(`         avg NDCG@5 = ${avgNdcg.toFixed(3)}`);
console.log(`         avg score gap = ${avgGap.toFixed(3)}`);
console.log("");
console.log("PDF claims: 90% accuracy, avg NDCG@5 0.87, avg gap 0.16");
console.log("");
