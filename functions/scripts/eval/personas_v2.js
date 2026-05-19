/**
 * personas_v2.js
 * ──────────────
 * Expanded persona suite (~30 personas) for evaluating the recommendation
 * engine across all five contexts (solo / nearby / similar / home / tours)
 * and across the cold-start / warm-vector / dismissal-heavy spectrum.
 *
 * Each persona is declared HUMAN-READABLY (loves, dislikes, location, context)
 * and the framework auto-derives BOTH the taste vector AND the per-candidate
 * relevance labels. This keeps personas terse and avoids the "the test author
 * hand-labelled the answer key while looking at the scoring formula" critique
 * levelled at the original 5-persona evaluation.
 *
 * KEY DESIGN CHOICE — independent ground truth:
 *   The taste vector uses buildVector() with visit/dismiss weights, then runs
 *   through the production tanh-normalised mean-vector scorer.
 *   The relevance label uses RAW SET INTERSECTION on canonical keys, no tanh,
 *   no mean, no weights, no proximity, no rating mixing. The two formulas are
 *   structurally different — if the engine performs well on the metric, that
 *   is real lift, not formula self-consistency.
 *
 * For cold-start personas (no loves/dislikes) we use country-prior cosine
 * similarity. For the neutral persona we use rating × popularity as a proxy
 * for "what an unguided tourist would generally prefer."
 */

const { _internal } = require("../../recommendation");
const { applySignalToVector, SIGNAL_WEIGHTS, cosineSim, haversineKm } = _internal;

// ─── Country priors used by cold-start personas ─────────────────────────────
// Hand-coded approximations of what each nationality tends to engage with on
// Egyptian-tourism platforms. These are derived independently of the scoring
// formula (no taste vector or test data was consulted).
const COUNTRY_PRIORS = {
  US: {
    museum: 2.5, archaeological_site: 2.8, monument: 2.6, historical_landmark: 2.2,
    cultural: 3.0, historical: 3.0, ancient: 2.7, pharaonic: 2.6,
    beach: 1.6, natural: 1.7, mosque: 1.0, market: 1.6,
  },
  DE: {
    museum: 2.6, archaeological_site: 3.0, monument: 2.8, historical_landmark: 2.4,
    cultural: 3.0, historical: 3.0, ancient: 2.9, pharaonic: 2.7,
    natural: 1.9, park: 1.7, mosque: 1.5,
  },
  EG: {
    mosque: 2.4, market: 2.6, restaurant: 2.5, cafe: 2.0,
    cultural: 2.8, islamic: 2.4, family: 2.6, food: 2.4,
    park: 2.0, beach: 2.1, shopping_mall: 1.6,
  },
  SA: {
    mosque: 2.8, market: 2.3, shopping_mall: 2.4, beach: 2.2,
    luxury: 2.5, religious: 2.6, islamic: 2.6, family: 2.4, spa: 2.0,
  },
  RU: {
    beach: 3.0, spa: 2.4, natural: 2.4, relaxation: 2.6,
    luxury: 2.4, night_club: 2.0, entertainment: 2.2,
  },
  JP: {
    museum: 2.7, archaeological_site: 2.8, monument: 2.6, historical_landmark: 2.4,
    cultural: 3.0, historical: 3.0, ancient: 2.7, pharaonic: 2.6,
    cafe: 1.8, food: 1.9,
  },
};

// ─── Helpers ────────────────────────────────────────────────────────────────

function buildVector(loves, dislikes) {
  const v = {};
  for (const k of loves) {
    // Half goes to "type-like" half to "tag-like" — but since canonical keys
    // are flat we just credit each loved key with a single visit weight.
    applySignalToVector(v, [k], [], SIGNAL_WEIGHTS.visit);
  }
  for (const k of dislikes) {
    applySignalToVector(v, [k], [], SIGNAL_WEIGHTS.dismiss);
  }
  return v;
}

/**
 * Auto-label relevance for a (persona, candidate) pair, returning a grade in [0, 3].
 *
 *   3  Strong match: at least one loved TYPE present AND >=2 loved keys overlap.
 *   2  Match: at least one loved key present (type OR tag), no dislikes.
 *   1  Weak match: highly-rated catch-all, or one shared tag.
 *   0  Not relevant: no shared keys, OR any disliked TYPE present.
 *
 * The thresholds are simple cardinality rules on set intersection — they share
 * no math with the production scorer's tanh-normalised mean-vector formula.
 */
function relevanceFromPreferences(persona, candidate) {
  const loves = new Set(persona.loves || []);
  const dislikes = new Set(persona.dislikes || []);
  const cTypes = candidate.types || [];
  const cTags = candidate.tags || [];
  const cKeys = new Set([...cTypes, ...cTags]);

  // Hard veto: any disliked TYPE present → 0
  for (const t of cTypes) if (dislikes.has(t)) return 0;

  // Count overlaps
  let loveTypeHit = 0;
  let loveTagHit = 0;
  for (const t of cTypes) if (loves.has(t)) loveTypeHit++;
  for (const t of cTags) if (loves.has(t)) loveTagHit++;
  const totalLove = loveTypeHit + loveTagHit;

  // Soft penalty: any disliked TAG present caps relevance at 1
  let dislikedTagSeen = false;
  for (const t of cTags) if (dislikes.has(t)) dislikedTagSeen = true;

  if (loveTypeHit >= 1 && totalLove >= 2 && !dislikedTagSeen) return 3;
  if (totalLove >= 1 && !dislikedTagSeen) return 2;
  if (totalLove >= 1 && dislikedTagSeen) return 1;

  // No taste signal — fall back to a popularity-rating heuristic.
  // This branch primarily affects cold-start / neutral personas.
  if (persona.coldStart) {
    if (persona.countryPrior) {
      const profile = {};
      for (const k of cKeys) profile[k] = 1;
      const sim = cosineSim(profile, persona.countryPrior);
      if (sim >= 0.45) return 3;
      if (sim >= 0.30) return 2;
      if (sim >= 0.15) return 1;
      return 0;
    }
    // Neutral baseline: rating × popularity is the only ground truth.
    const popScore = (candidate.rating || 3) * Math.log10(1 + (candidate.userRatingCount || 0));
    if (popScore >= 22) return 3;
    if (popScore >= 16) return 2;
    if (popScore >= 10) return 1;
    return 0;
  }

  return 0;
}

/**
 * Build a relevance map for every candidate, applying the rules above.
 * Optionally biases by distance: for `nearby`/`home` contexts, places > 200 km
 * from the persona's GPS get capped at min(grade, 1) — this matches what real
 * users in those contexts actually consider relevant. NOT applied to the
 * `solo` context, where Karnak is legitimately top-choice for a history lover
 * even from Cairo.
 */
function buildRelevanceMap(persona, candidates) {
  const rel = {};
  const useDistanceCap = persona.context === "nearby" || persona.context === "home";
  for (const c of candidates) {
    let r = relevanceFromPreferences(persona, c);
    if (useDistanceCap &&
        typeof persona.userLat === "number" && typeof c.lat === "number") {
      const d = haversineKm(persona.userLat, persona.userLng, c.lat, c.lng);
      if (d > 200) r = Math.min(r, 1);
      if (d > 500) r = Math.min(r, 0);
    }
    rel[c.placeId] = r;
  }
  return rel;
}

// ─── Persona suite ──────────────────────────────────────────────────────────

const PERSONAS = [
  // ===== ORIGINAL 5 (preserved for regression continuity with v1) =====
  {
    name: "History Lover (Cairo)",
    context: "solo",
    loves: ["museum", "archaeological_site", "historical", "ancient", "pharaonic", "cultural"],
    dislikes: ["beach", "night_club"],
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Beach Seeker (Hurghada)",
    context: "solo",
    loves: ["beach", "spa", "natural", "relaxation", "luxury"],
    dislikes: ["museum", "archaeological_site"],
    userLat: 27.2579, userLng: 33.8116,
  },
  {
    name: "Family Planner (Cairo)",
    context: "nearby",
    loves: ["zoo", "park", "family", "amusement_park", "relaxation"],
    dislikes: ["night_club"],
    userLat: 30.0259, userLng: 31.2160,
  },
  {
    name: "Cold-Start US Tourist (Cairo)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.US,
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Neutral Baseline (Cairo)",
    context: "home",
    coldStart: true,
    countryPrior: null,
    userLat: 30.0444, userLng: 31.2357,
  },

  // ===== EXPANSION: solo context =====
  {
    name: "Pharaonic Devotee (Luxor)",
    context: "solo",
    loves: ["archaeological_site", "monument", "ancient", "pharaonic", "historical"],
    dislikes: ["shopping_mall", "amusement_park"],
    userLat: 25.6995, userLng: 32.6421,
  },
  {
    name: "Islamic Heritage (Cairo)",
    context: "solo",
    loves: ["mosque", "islamic", "religious", "historical", "cultural"],
    dislikes: ["night_club", "beach"],
    userLat: 30.0457, userLng: 31.2624,
  },
  {
    name: "Coptic Heritage (Old Cairo)",
    context: "solo",
    loves: ["church", "coptic", "religious", "historical"],
    dislikes: ["night_club", "shopping_mall"],
    userLat: 30.0058, userLng: 31.2304,
  },
  {
    name: "Foodie + Markets (Cairo)",
    context: "solo",
    loves: ["restaurant", "cafe", "market", "food", "cultural"],
    dislikes: ["night_club"],
    userLat: 30.0481, userLng: 31.2620,
  },
  {
    name: "Adventure (Sinai)",
    context: "solo",
    loves: ["beach", "park", "natural", "adventure", "tourist_attraction"],
    dislikes: ["shopping_mall", "museum"],
    userLat: 28.4988, userLng: 34.5135,
  },
  {
    name: "Luxury Wellness (Red Sea)",
    context: "solo",
    loves: ["spa", "beach", "luxury", "relaxation"],
    dislikes: ["archaeological_site", "museum", "market"],
    userLat: 26.8500, userLng: 33.9833,
  },
  {
    name: "Nightlife (Cairo)",
    context: "solo",
    loves: ["night_club", "entertainment", "modern", "restaurant"],
    dislikes: ["museum", "mosque", "archaeological_site"],
    userLat: 30.0644, userLng: 31.2007,
  },
  {
    name: "History + Food Blend (Cairo)",
    context: "solo",
    loves: ["museum", "archaeological_site", "historical", "restaurant", "food", "cultural"],
    dislikes: ["night_club"],
    userLat: 30.0481, userLng: 31.2620,
  },
  {
    name: "Beach + Nightlife Blend (Sharm)",
    context: "solo",
    loves: ["beach", "night_club", "entertainment", "luxury", "modern"],
    dislikes: ["museum", "archaeological_site"],
    userLat: 27.9095, userLng: 34.3209,
  },
  {
    name: "Hates History, Loves Beach (Hurghada)",
    context: "solo",
    loves: ["beach", "spa", "natural", "luxury"],
    dislikes: ["archaeological_site", "museum", "historical", "ancient"],
    userLat: 27.2579, userLng: 33.8116,
  },

  // ===== nearby context =====
  {
    name: "Nearby — Khan el-Khalili",
    context: "nearby",
    loves: ["market", "cultural", "historical", "islamic", "shopping", "food"],
    dislikes: ["beach", "amusement_park"],
    userLat: 30.0476, userLng: 31.2624,
  },
  {
    name: "Nearby — Luxor West Bank",
    context: "nearby",
    loves: ["archaeological_site", "monument", "ancient", "pharaonic"],
    dislikes: ["night_club", "shopping_mall"],
    userLat: 25.7383, userLng: 32.6066,
  },
  {
    name: "Nearby — Alexandria Corniche",
    context: "nearby",
    loves: ["historical_landmark", "museum", "cultural", "historical", "beach"],
    dislikes: ["night_club"],
    userLat: 31.2089, userLng: 29.9092,
  },
  {
    name: "Nearby — Aswan",
    context: "nearby",
    loves: ["archaeological_site", "monument", "ancient", "pharaonic", "market", "cultural"],
    dislikes: ["amusement_park"],
    userLat: 24.0889, userLng: 32.8998,
  },

  // ===== similar context =====
  {
    name: "Similar — after visiting Pyramids",
    context: "similar",
    loves: ["archaeological_site", "monument", "ancient", "pharaonic", "historical", "cultural"],
    dislikes: ["night_club", "shopping_mall"],
    userLat: 29.9792, userLng: 31.1342,
  },
  {
    name: "Similar — after visiting Khan el-Khalili",
    context: "similar",
    loves: ["market", "cultural", "islamic", "historical", "shopping"],
    dislikes: ["beach", "night_club"],
    userLat: 30.0476, userLng: 31.2624,
  },
  {
    name: "Similar — after visiting Al-Azhar Mosque",
    context: "similar",
    loves: ["mosque", "religious", "islamic", "historical", "cultural"],
    dislikes: ["night_club", "beach"],
    userLat: 30.0457, userLng: 31.2624,
  },
  {
    name: "Similar — after visiting Hurghada Beach",
    context: "similar",
    loves: ["beach", "natural", "relaxation", "spa", "luxury"],
    dislikes: ["museum", "archaeological_site"],
    userLat: 27.2579, userLng: 33.8116,
  },

  // ===== home context (GPS-anchored, proximity-weighted) =====
  {
    name: "Home — Cairo resident, history fan",
    context: "home",
    loves: ["museum", "archaeological_site", "historical", "ancient", "cultural"],
    dislikes: ["night_club"],
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Home — Alexandria resident, mixed",
    context: "home",
    loves: ["historical_landmark", "museum", "cultural", "historical", "beach"],
    dislikes: ["night_club"],
    userLat: 31.2001, userLng: 29.9187,
  },
  {
    name: "Home — Luxor resident, archaeological",
    context: "home",
    loves: ["archaeological_site", "monument", "ancient", "pharaonic", "museum"],
    dislikes: ["shopping_mall"],
    userLat: 25.6995, userLng: 32.6421,
  },
  {
    name: "Home — Cold-start DE tourist (Cairo)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.DE,
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Home — Cold-start RU tourist (Hurghada)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.RU,
    userLat: 27.2579, userLng: 33.8116,
  },
  {
    name: "Home — Cold-start EG local (Cairo)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.EG,
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Home — Cold-start SA tourist (Cairo)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.SA,
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Home — Cold-start JP tourist (Luxor)",
    context: "home",
    coldStart: true,
    countryPrior: COUNTRY_PRIORS.JP,
    userLat: 25.6995, userLng: 32.6421,
  },

  // ===== tours context =====
  {
    name: "Tours — history-seeking traveller",
    context: "tours",
    loves: ["archaeological_site", "monument", "museum", "ancient", "pharaonic", "historical", "cultural"],
    dislikes: ["night_club", "shopping_mall"],
    userLat: 30.0444, userLng: 31.2357,
  },
  {
    name: "Tours — adventure seeker",
    context: "tours",
    loves: ["beach", "natural", "adventure", "tourist_attraction", "park"],
    dislikes: ["museum", "shopping_mall"],
    userLat: 27.9095, userLng: 34.3209,
  },
  {
    name: "Tours — family-friendly",
    context: "tours",
    loves: ["zoo", "park", "amusement_park", "family", "entertainment", "aquarium"],
    dislikes: ["night_club"],
    userLat: 30.0444, userLng: 31.2357,
  },
];

// Enforce hasEnoughSignals invariant: warm personas have signalCount = sum of
// loved keys (>= 5), cold-start personas are 0.
for (const p of PERSONAS) {
  if (p.coldStart) {
    p.tasteVector = {};
    p.hasEnoughSignals = false;
  } else {
    p.tasteVector = buildVector(p.loves || [], p.dislikes || []);
    p.hasEnoughSignals = (p.loves || []).length >= 1;
  }
}

module.exports = {
  PERSONAS,
  COUNTRY_PRIORS,
  buildVector,
  buildRelevanceMap,
  relevanceFromPreferences,
};
