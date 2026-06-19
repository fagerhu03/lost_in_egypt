/**
 * ╔══════════════════════════════════════════════════════════════════════════════╗
 * ║              Lost in Egypt — Recommendation Engine                          ║
 * ║              functions/recommendation.js                                    ║
 * ╚══════════════════════════════════════════════════════════════════════════════╝
 *
 * ─── FOR TEAMMATES REVIEWING THIS FILE ────────────────────────────────────────
 *
 * The original design was a Python/FastAPI + XGBoost model. That approach was
 * rejected because Firebase Cloud Functions runs Node.js — there is no Python
 * runtime in this project. We kept all the ideas from the original design
 * (hybrid scoring, collaborative filtering, ε-greedy exploration, quiz signals)
 * and reimplemented everything from scratch in Node.js without any ML training
 * dependency.
 *
 * XGBoost CAN be reintroduced later as a trained scoring model once we have
 * enough interaction data. The current hand-crafted weights are a starting point
 * that we can replace with learned weights as data grows.
 *
 * ─── WHAT THIS FILE DOES ──────────────────────────────────────────────────────
 *
 * This file exports 4 Cloud Functions the Flutter app calls directly:
 *   1. recordTasteSignal  — records a user action (visit, save, like, etc.)
 *   2. recommendPlaces    — scores and ranks candidate places for a user
 *   3. applyQuizAnswers   — applies quiz selections to the user's taste profile
 *   4. warmStartTasteVector — bootstraps new users from existing Firestore data
 *
 * Plus 3 scheduled background jobs:
 *   5. decayTasteVectors    — slowly fades old signals (runs nightly 3 AM UTC)
 *   6. rebuildPlaceNeighbors — item-item collaborative filtering (nightly 4 AM)
 *   7. rebuildCountryPriors  — country-level taste averages (weekly Sunday 2 AM)
 *
 * And the _internal export for local testing without Firebase credentials:
 *   node scripts/sample_recommendation.js --user=history --context=solo
 *
 * ─── THE CORE IDEA IN ONE PARAGRAPH ──────────────────────────────────────────
 *
 * Every user has a "taste vector" — a map from place category/tag names to
 * float values representing how much they like that type of place. When a user
 * visits the Egyptian Museum we add +1.0 to their "museum", "cultural", and
 * "historical" keys. When they dismiss a beach card we subtract 0.3 from "beach"
 * and "natural". Over time this vector becomes a fingerprint of their interests.
 *
 * When we want to recommend places, we score each candidate by combining:
 *   • How well the candidate's types/tags match the user's taste vector
 *   • How close the candidate is to the user's current location
 *   • How highly rated the candidate is
 *   • Whether other similar users also liked it (collaborative filtering)
 *   • How popular it is generally
 *
 * We add ε-greedy exploration (15% random picks) for serendipity, and apply
 * MMR diversity penalties so results don't all look the same.
 *
 * ─── FILE STRUCTURE ───────────────────────────────────────────────────────────
 *
 *   1. Constants: canonical keys, signal weights, rate limits
 *   2. Rate limiter helper
 *   3. Pure math helpers: haversine, cosine similarity, etc.
 *   4. scoreCandidate()  — score ONE place against a user's taste vector
 *   5. rankCandidates()  — score ALL candidates + diversity + exploration
 *   6. applySignalToVector() — update taste vector from a signal
 *   7. Cloud Function: recordTasteSignal
 *   8. Cloud Function: recommendPlaces
 *   9. Cloud Function: warmStartTasteVector
 *  10. Cloud Function: applyQuizAnswers
 *  11. Scheduled: decayTasteVectors
 *  12. Scheduled: rebuildPlaceNeighbors
 *  13. Scheduled: rebuildCountryPriors
 *  14. _internal exports for local testing
 *
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Secret used by sendDailyDiscovery (Groq fact generation)
const groqApiKey = defineSecret("GROQ_API_KEY");

// Lazy-init admin — index.js calls initializeApp() before requiring this module,
// so we access Firestore through a getter instead of module-level assignment.
function db() {
  return admin.firestore();
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════

/**
 * THE TASTE VECTOR SCHEMA
 * ────────────────────────
 * Every user's taste profile is stored as users/{uid}.tasteVector in Firestore.
 * It is a plain JavaScript/JSON object where:
 *   key   = one of the 37 canonical strings below
 *   value = float, typically in the range [-5, 10], unbounded in theory
 *
 * Positive values mean the user likes that type of place.
 * Negative values mean they dislike or have dismissed that type.
 * Missing keys are treated as 0 (neutral, no preference expressed yet).
 *
 * The 37 canonical keys are split into:
 *   - CANONICAL_TYPES (20) — place categories from Google Places API
 *   - CANONICAL_TAGS  (17) — descriptive content tags
 *
 * WHY THESE 37 KEYS?
 * They cover every major type of attraction in Egypt while staying small
 * enough to be human-interpretable and fast to compute over. We deliberately
 * exclude very generic Google Places types (establishment, point_of_interest)
 * and only keep ones that carry real preference signal.
 *
 * The Flutter client maps raw Google Places API types to these canonical keys
 * in lib/core/services/recommendation_mappings.dart before sending any signal.
 */
const CANONICAL_TYPES = [
  "museum",             // Egyptian Museum, Nubian Museum, Luxor Museum, etc.
  "historical_landmark",// Citadel, Abu Simbel, Valley of the Kings
  "tourist_attraction", // Generic well-known sites — fallback type
  "mosque",             // Al-Azhar, Ibn Tulun, Muhammad Ali Mosque
  "church",             // Hanging Church, St. Simon, Coptic churches
  "park",               // Al-Azhar Park, Orman Garden, national parks
  "restaurant",         // Dining, food halls, traditional Egyptian cuisine
  "cafe",               // Coffee shops, tea houses, juice bars
  "shopping_mall",      // City Stars, Mall of Egypt, modern retail
  "market",             // Khan el-Khalili, Aswan Souk, local bazaars
  "beach",              // Red Sea, Mediterranean, Nile Corniche beaches
  "zoo",                // Giza Zoo, Zoological Gardens
  "art_gallery",        // Cairo Opera House galleries, contemporary art
  "amusement_park",     // Dream Park, family entertainment
  "aquarium",           // Hurghada Aquarium, marine experiences
  "monument",           // Pyramids, obelisks, colossi — free-standing structures
  "archaeological_site",// Karnak, Luxor Temple, Dendera, Kom Ombo
  "night_club",         // Cairo nightlife, Zamalek clubs, Red Sea resort clubs
  "spa",                // Resort spas, wellness centers, hammams
  "stadium",            // Cairo Stadium, Alexandria stadium — events + sports
];

const CANONICAL_TAGS = [
  "cultural",     // Connected to Egyptian culture broadly
  "historical",   // Has historical significance or tells a historical story
  "religious",    // Religious site or tied to a religious tradition
  "natural",      // Natural environment: desert, sea, wildlife, landscape
  "modern",       // Contemporary, recently built, modern Egypt
  "ancient",      // Pharaonic, ancient Egypt (pre-Islamic)
  "islamic",      // Islamic Cairo, Fatimid architecture, Islamic art
  "coptic",       // Coptic Christianity, old Cairo churches and monasteries
  "pharaonic",    // Temples, tombs, pyramids — ancient pharaonic Egypt
  "luxury",       // High-end experience: fine dining, resort, premium service
  "budget",       // Affordable, local, backpacker-friendly
  "family",       // Suitable for families with children
  "adventure",    // Active, physical: diving, desert safari, hiking
  "relaxation",   // Calm, unwinding: beach, spa, garden
  "food",         // Primarily about eating or tasting local food
  "shopping",     // Shopping-oriented experience
  "entertainment",// Concerts, shows, night entertainment, events
];

// Combine into a single Set for O(1) validation when normalising API types
const CANONICAL_KEYS = new Set([...CANONICAL_TYPES, ...CANONICAL_TAGS]);

/**
 * SIGNAL WEIGHTS
 * ──────────────
 * Each user action generates a "signal" that updates the taste vector.
 * The weight controls how much each action shifts the taste vector.
 *
 * Design rationale (from the original Python design, preserved here):
 *   - visit (+1.0)    : Strongest signal — user physically went there
 *   - booking (+0.8)  : Very strong — user paid money to go
 *   - save (+0.6)     : Intent signal — user wants to go in future
 *   - quiz (+0.5)     : Explicit preference statement (from onboarding quiz)
 *   - post (+0.5)     : User shared the experience publicly
 *   - like (+0.4)     : Mild positive reaction to content about this type
 *   - dismiss (-0.3)  : User swiped away — mild negative signal
 *   - view (-0.1)     : Saw it but did nothing — slight negative (not strong)
 *
 * These weights are applied to ALL canonical keys that the place belongs to.
 * Example: visiting the Egyptian Museum (types: [museum], tags: [cultural, historical])
 *   → tasteVector.museum    += 1.0
 *   → tasteVector.cultural  += 1.0
 *   → tasteVector.historical += 1.0
 */
const SIGNAL_WEIGHTS = {
  visit: 1.0,
  booking: 0.8,
  save: 0.6,
  post: 0.5,
  like: 0.4,
  quiz: 0.5,
  dismiss: -0.3,
  view: -0.1,
};

/**
 * RATE LIMITS (calls per hour per user)
 * ──────────────────────────────────────
 * recommendPlaces: 60/hr — generous, called on every screen load in recommendation surfaces
 * recordTasteSignal: 300/hr — very generous, fire-and-forget from many touchpoints
 * warmStartTasteVector: 1/day (1/hr effectively — the scheduled nightly decay is the true limit)
 */
const RATE_LIMITS = {
  recommendPlaces: 60,
  recordTasteSignal: 300,
  warmStartTasteVector: 1,
};

// ══════════════════════════════════════════════════════════════════════════════
// 2. RATE LIMITER
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Per-user, per-function rate limiter using Firestore transactions.
 * Each "slot" is a 1-hour window identified by: uid + functionName + hourSlot.
 * The transaction ensures no race condition when the same user calls concurrently.
 *
 * The _rate_limits collection is an internal Firestore collection — documents
 * are never read by the Flutter client.
 */
async function checkRateLimit(uid, functionName) {
  const hourSlot = Math.floor(Date.now() / (1000 * 60 * 60));
  const ref = db()
    .collection("_rate_limits")
    .doc(`${uid}_${functionName}_${hourSlot}`);
  const limit = RATE_LIMITS[functionName];
  return db().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const count = doc.exists ? doc.data().count : 0;
    if (count >= limit) return false;
    tx.set(ref, { count: count + 1, uid, updatedAt: Date.now() }, { merge: true });
    return true;
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. PURE MATH HELPERS (no Firebase deps — fully unit-testable)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Haversine formula: great-circle distance between two lat/lng coordinates.
 * Returns distance in kilometres.
 *
 * Used in scoreCandidate() to compute proximity score. We use this instead of
 * a Maps API call because it's instant and accurate enough for scoring purposes
 * (error is <0.5% for distances under 100 km, which covers all Egyptian cities).
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Clamp x to [lo, hi]. Used to keep all partial scores in a consistent range. */
function clamp(x, lo, hi) {
  return Math.max(lo, Math.min(hi, x));
}

/**
 * Normalise a list of raw key strings to canonical form.
 * Converts to lowercase, trims whitespace, filters out any key not in CANONICAL_KEYS.
 * This prevents the taste vector from being polluted by unknown/arbitrary strings.
 */
function normalizeKeys(keys) {
  if (!Array.isArray(keys)) return [];
  return keys
    .map((k) => String(k).toLowerCase().trim())
    .filter((k) => CANONICAL_KEYS.has(k));
}

/**
 * Cosine similarity between two taste vector objects.
 * Returns a value in [0, 1] — 1 means identical taste fingerprints, 0 means no overlap.
 *
 * Used in the collaborative filtering step (country prior comparison) and internally
 * in rebuildPlaceNeighbors for item-item similarity (though Jaccard is used there).
 *
 * Formula: cos(θ) = (A · B) / (|A| × |B|)
 *   where A · B is the dot product and |A| is the Euclidean norm.
 */
function cosineSim(a, b) {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  let dot = 0, na = 0, nb = 0;
  for (const k of keys) {
    const va = a[k] || 0;
    const vb = b[k] || 0;
    dot += va * vb;
    na += va * va;
    nb += vb * vb;
  }
  if (na === 0 || nb === 0) return 0;
  return dot / (Math.sqrt(na) * Math.sqrt(nb));
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. SCORING CORE — scoreCandidate()
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Score a single candidate place against a user's taste vector.
 *
 * This is a pure function — no Firebase calls, no side effects.
 * It can be called directly in unit tests via the _internal export.
 *
 * ─── THE SCORING FORMULA ─────────────────────────────────────────────────────
 *
 * score = w.taste × tasteMatch
 *       + w.rating × ratingScore
 *       + w.proximity × proximity
 *       + w.popularity × popularity
 *       + w.collab × collab
 *       + (cold-start only) 0.30 × priorScore
 *
 * DEFAULT WEIGHTS (context = 'solo' or 'home'):
 *   taste     0.40  ← dominant: personal preference is what matters most
 *   rating    0.15  ← quality signal from Google ratings
 *   proximity 0.20  ← how close the place is to the user right now
 *   popularity 0.10 ← log-scaled review count (how many people have been)
 *   collab    0.15  ← collaborative filtering from similar users' history
 *
 * CONTEXT OVERRIDES:
 *   'nearby'  → proximity 0.30, taste 0.30  (map "near me" panel — distance matters more)
 *   'similar' → collab 0.30,   taste 0.30  (after a visit — "people who liked X also liked Y")
 *   'home'    → popularity 0.15, proximity 0.15  (home feed — slightly more discovery-oriented)
 *
 * COLD-START (user has fewer than 5 signals):
 *   We don't have enough personal data yet, so we substitute 30% of the taste
 *   weight with a country-prior score (average taste vector of other users from
 *   the same nationality). The taste weight drops to 10% so the prior dominates.
 *
 * ─── EACH COMPONENT ──────────────────────────────────────────────────────────
 *
 * 1. TASTE MATCH
 *    Average the taste vector values for all canonical keys this place belongs to.
 *    Squash through clamp(x/3, -1, 1) to normalise the range.
 *    Example: user loves museums (vector.museum = 4.5), place is a museum →
 *             tasteMatch = clamp(4.5/3, -1, 1) = 1.0 (full match)
 *
 * 2. RATING SCORE
 *    Linear remap of Google star rating [2.0–5.0] to [-1, +1].
 *    Baseline is 3.5 stars — a place rated 5.0 gets +1.0, rated 2.0 gets −1.0.
 *    Formula: clamp((rating - 3.5) / 1.5, -1, 1)
 *
 * 3. PROXIMITY
 *    Soft inverse-distance decay: 1 / (1 + distanceKm / 5)
 *    At 0 km → 1.0 (full score), at 5 km → 0.5, at 20 km → 0.2.
 *    The /5 factor was tuned for Egyptian city scale (Cairo, Luxor, Aswan).
 *    If no user location is provided, proximity contributes 0.
 *
 * 4. POPULARITY
 *    Log-scaled user rating count from Google.
 *    clamp(log10(1 + reviewCount) / 4, 0, 1)
 *    At 0 reviews → 0.0, at 10 reviews → 0.27, at 1000 reviews → 0.75,
 *    at 10000 reviews → 1.0. This prevents super-popular tourist traps from
 *    completely dominating without ignoring them either.
 *
 * 5. COLLABORATIVE FILTERING (collab)
 *    The nightly rebuildPlaceNeighbors job computes which places tend to be
 *    liked by the same users (item-item Jaccard similarity). If a place is
 *    a "neighbor" of something this user has positively interacted with, its
 *    collab score is that Jaccard similarity value (0–1).
 *
 * 6. COUNTRY PRIOR (cold-start only)
 *    For new users with <5 signals, we look up the average tasteVector of all
 *    users from the same country (stored in country_priors/{code}). We compute
 *    cosine similarity between that average and the candidate's type/tag profile.
 *    This bootstraps recommendations before any personal data exists.
 *
 * @param {object} params
 * @param {object} params.candidate - { placeId, name, types[], tags[], rating, userRatingCount, lat, lng }
 * @param {object} params.tasteVector - Map<string, number> from users/{uid}.tasteVector
 * @param {number|undefined} params.userLat - User's current latitude (optional)
 * @param {number|undefined} params.userLng - User's current longitude (optional)
 * @param {string} params.context - 'solo'|'nearby'|'similar'|'home'|'tours' — shifts weight distribution
 * @param {object} params.neighbors - Map<placeId, similarity> for collaborative filtering
 * @param {object|null} params.countryPrior - Country-level average tasteVector (null if unavailable)
 * @param {boolean} params.hasEnoughSignals - true once user has ≥5 non-quiz signals
 * @returns {{ score: number, breakdown: object, reasons: string[] }}
 */
// Place types considered outdoor or semi-outdoor for weather scoring.
const OUTDOOR_TYPES = new Set([
  "park", "beach", "archaeological_site", "monument", "historical_landmark",
  "zoo", "stadium", "amusement_park", "tourist_attraction", "national_park",
]);
const SEMI_OUTDOOR_TYPES = new Set(["market", "street_market", "bazaar"]);

function scoreCandidate({
  candidate,
  tasteVector,
  userLat, userLng,
  context,
  neighbors,
  countryPrior,
  hasEnoughSignals,
  weatherContext = null,
}) {
  // Combine types and tags into a single list of canonical keys for this place
  const keys = [...normalizeKeys(candidate.types), ...normalizeKeys(candidate.tags)];

  // ── Component 1: Taste match ──────────────────────────────────────────────
  // How well does this place's category/tag profile match the user's taste vector?
  let tasteMatch = 0;
  if (keys.length > 0) {
    const sum = keys.reduce((acc, k) => acc + (tasteVector[k] || 0), 0);
    tasteMatch = sum / keys.length; // average over all relevant keys
  }
  // tanh normalises to (-1, 1) smoothly — unlike hard clamp it never saturates,
  // so the gradient stays non-zero even when the vector value is large.
  // /2 keeps the midpoint steep: a value of 2.0 → ~0.76, 4.0 → ~0.96.
  tasteMatch = Math.tanh(tasteMatch / 2);

  // ── Component 2: Rating score ─────────────────────────────────────────────
  // Remap Google star rating to [-1, +1] with 3.5 as neutral midpoint
  const rating = typeof candidate.rating === "number" ? candidate.rating : 3.5;
  const ratingScore = clamp((rating - 3.5) / 1.5, -1, 1);

  // ── Component 3: Proximity ────────────────────────────────────────────────
  // Exponential decay — drops sharply beyond ~50 km so distant places can't
  // beat local ones on taste alone. Half-score at ~70 km, near-zero at ~400 km.
  let proximity = 0;
  let distanceKm = null;
  if (typeof userLat === "number" && typeof userLng === "number" &&
      typeof candidate.lat === "number" && typeof candidate.lng === "number") {
    distanceKm = haversineKm(userLat, userLng, candidate.lat, candidate.lng);
    proximity = Math.exp(-distanceKm / 100); // 0 km→1.0, 100 km→0.37, 400 km→0.018
  }

  // ── Component 4: Popularity ───────────────────────────────────────────────
  // Log-scale review count so viral tourist traps don't totally dominate
  const urc = Number(candidate.userRatingCount || 0);
  const popularity = clamp(Math.log10(1 + urc) / 4, 0, 1);

  // ── Component 5: Collaborative filtering ─────────────────────────────────
  // If this place is a Jaccard neighbor of something the user liked, score it up.
  // The neighbors map is built nightly by rebuildPlaceNeighbors and fetched once
  // per recommendPlaces call (not per candidate).
  const collab = neighbors && neighbors[candidate.placeId] ? neighbors[candidate.placeId] : 0;

  // ── Component 6: Country prior (cold-start fallback) ─────────────────────
  // For new users, compare the candidate's profile to the country average taste vector.
  // This is only active when the user has fewer than 5 personal signals.
  let priorScore = 0;
  if (countryPrior && !hasEnoughSignals) {
    // Build a binary profile vector for this candidate (1 for each key it has)
    const cPrior = {};
    for (const k of keys) cPrior[k] = 1;
    // Cosine similarity between candidate profile and country average
    priorScore = cosineSim(cPrior, countryPrior);
  }

  // ── Weight distribution (context-dependent) ───────────────────────────────
  // All five base weights sum to 1.00 within every context. Solo proximity is
  // deliberately light (0.10) because users with real taste history should be
  // shown what they love regardless of distance — the existence of Karnak
  // shouldn't be hidden from a history lover in Cairo just because Luxor is
  // 600 km away. The freed weight goes to taste (0.50), which is the primary
  // signal for users with recorded preferences. Proximity dominates in the
  // "nearby" and "home" contexts which are explicitly about local discovery.
  let w = { taste: 0.50, rating: 0.15, proximity: 0.10, popularity: 0.10, collab: 0.15 };

  if (context === "nearby") {
    // Map "near me" panel — user wants to know what's physically close right now.
    // Sums to 1.00: 0.30 + 0.15 + 0.30 + 0.10 + 0.15
    w = { taste: 0.30, rating: 0.15, proximity: 0.30, popularity: 0.10, collab: 0.15 };
  }
  if (context === "similar") {
    // "Places similar to X you visited" — collaborative signal matters most.
    // Sums to 1.00: 0.30 + 0.15 + 0.10 + 0.15 + 0.30
    w = { taste: 0.30, rating: 0.15, proximity: 0.10, popularity: 0.15, collab: 0.30 };
  }
  if (context === "home") {
    // Home feed — proximity is the dominant signal; taste breaks ties among nearby places.
    // This prevents distant places from winning solely on taste match.
    w = { taste: 0.25, rating: 0.10, proximity: 0.45, popularity: 0.05, collab: 0.15 };
  }
  if (context === "tours") {
    // Tours are intentional, planned activities — taste dominates. Rating + collab
    // still matter because a guided tour's quality is a real signal. Proximity is
    // reduced because tours have set meeting points and users will travel to them.
    w = { taste: 0.40, rating: 0.20, proximity: 0.10, popularity: 0.15, collab: 0.15 };
  }

  // Cold-start adjustment: reduce personal taste weight, let country prior fill the gap.
  // Also hard-cap proximity to 0.10 — a new tourist hasn't told us if they want
  // "near me" results, and the country prior signals interest in distant heritage
  // sites (Karnak, Valley of the Kings) that a proximity-heavy home weight would
  // otherwise crush. The remaining ~0.30 comes from priorScore added explicitly below.
  if (!hasEnoughSignals && countryPrior) {
    w = { ...w, taste: 0.10 };
    if (w.proximity > 0.10) w.proximity = 0.10;
  }

  // ── Final weighted sum ────────────────────────────────────────────────────
  const score =
    w.taste * tasteMatch +
    w.rating * ratingScore +
    w.proximity * proximity +
    w.popularity * popularity +
    w.collab * collab +
    (!hasEnoughSignals && countryPrior ? 0.30 * priorScore : 0);

  // ── Reason generation (human-readable chips shown on result cards) ─────────
  // Compute each component's actual contribution to the score, then pick the
  // top 2 positive contributors to show as text chips to the user.
  const contributions = [
    {
      key: "taste",
      value: w.taste * tasteMatch,
      text: tasteMatch > 0.1 ? interestReason(keys, tasteVector) : null,
    },
    {
      key: "proximity",
      value: w.proximity * proximity,
      text: distanceKm != null && distanceKm < 10 ? `${distanceKm.toFixed(1)} km away` : null,
    },
    {
      key: "rating",
      value: w.rating * ratingScore,
      text: rating >= 4.3 ? `Highly rated (${rating.toFixed(1)}★)` : null,
    },
    {
      key: "popularity",
      value: w.popularity * popularity,
      text: urc > 500 ? "Popular with travelers" : null,
    },
    {
      key: "collab",
      value: w.collab * collab,
      text: collab > 0.2 ? "Similar to places you liked" : null,
    },
    {
      key: "country",
      value: (!hasEnoughSignals && countryPrior ? 0.30 * priorScore : 0),
      text: priorScore > 0.2 ? "Popular with travelers from your country" : null,
    },
  ];
  const reasons = contributions
    .filter((c) => c.text && c.value > 0)
    .sort((a, b) => b.value - a.value)
    .slice(0, 2)
    .map((c) => c.text);

  // ── Weather penalty (outdoor places scored down in bad conditions) ────────
  // Applied after reasons are built so the weather warning can prepend itself.
  let weatherPenalty = 0;
  if (weatherContext) {
    const allTypes = [...(candidate.types || []), ...(candidate.tags || [])];
    const isOutdoor = allTypes.some((t) => OUTDOOR_TYPES.has(t));
    const isSemi   = !isOutdoor && allTypes.some((t) => SEMI_OUTDOOR_TYPES.has(t));
    if (isOutdoor || isSemi) {
      const m = isSemi ? 0.5 : 1.0;
      if (weatherContext.isSandstorm) {
        weatherPenalty = 0.80 * m;
        reasons.unshift("⚠ Sandstorm warning — avoid outdoors");
      } else if (weatherContext.isExtremeHeat) {
        weatherPenalty = 0.45 * m;
        reasons.unshift(`⚠ Extreme heat (${(weatherContext.feelsLikeC || 0).toFixed(0)}°C) — best before 9am`);
      } else if (weatherContext.isVeryHot) {
        weatherPenalty = 0.20 * m;
        reasons.unshift(`Stay hydrated — feels ${(weatherContext.feelsLikeC || 0).toFixed(0)}°C`);
      } else if (weatherContext.isExtremeUV) {
        weatherPenalty = 0.15 * m;
        reasons.unshift(`UV index ${(weatherContext.uvIndex || 0).toFixed(0)} — wear sunscreen`);
      }
    }
  }
  const finalScore = score - weatherPenalty;

  return {
    score: finalScore,
    breakdown: { tasteMatch, ratingScore, proximity, popularity, collab, priorScore, distanceKm, weatherPenalty },
    reasons: reasons.slice(0, 3),
  };
}

/**
 * Generates a human-readable "Matches your interest in X" reason string.
 * Finds the key in the candidate's canonical key list that has the highest
 * value in the user's taste vector, then formats it as a display label.
 *
 * Example: keys = ["museum", "cultural"], vector.museum = 3.2, vector.cultural = 1.5
 *   → "Matches your interest in museum" → displayed as "Matches your interest in museum"
 */
function interestReason(keys, tasteVector) {
  let best = null, bestVal = 0;
  for (const k of keys) {
    const v = tasteVector[k] || 0;
    if (v > bestVal) { best = k; bestVal = v; }
  }
  if (!best) return null;
  const label = best.replace(/_/g, " "); // archaeological_site → "archaeological site"
  return `Matches your interest in ${label}`;
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. RANKING — rankCandidates()
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Rank a full list of candidate places for a user.
 *
 * This wraps scoreCandidate() and adds two additional mechanisms:
 *
 * ─── ε-GREEDY EXPLORATION (serendipity) ───────────────────────────────────────
 *
 * With probability ε (default 0.15 = 15%), instead of returning the top-scored
 * candidates we shuffle randomly and return that shuffled order.
 *
 * WHY? A pure recommender creates a "filter bubble" — the user only ever sees
 * the same types of places they already like, and never discovers anything new.
 * ε-greedy is the classic bandit algorithm fix: 85% exploitation (best score),
 * 15% exploration (random). This is exactly what the original Python design
 * proposed, and we kept it here.
 *
 * Exploration picks are marked exploration: true in the response so the UI can
 * optionally show a "Fresh discovery" label instead of a taste-match reason.
 *
 * ─── MMR DIVERSITY PENALTY ────────────────────────────────────────────────────
 *
 * MMR = Maximum Marginal Relevance. Without this, the top 10 results might all
 * be museums (because the user loves museums and Cairo has lots of them).
 *
 * Implementation: track how many times each primary type has been picked so far.
 * Each additional pick of the same type gets a 0.05 penalty per repeat.
 * Example: 1st museum = no penalty, 2nd museum = -0.05, 3rd = -0.10, etc.
 * This is soft (not a hard filter) — the user can still see 3 museums if they're
 * significantly better than anything else.
 *
 * ─── SEEN SET FILTERING ───────────────────────────────────────────────────────
 *
 * We maintain users/{uid}.soloPlanSeen — a list (capped at 200) of placeIds the
 * user has already seen in solo plan recommendations. When excludeSeen=true, we
 * filter those out before scoring so the user always sees fresh recommendations.
 *
 * @param {object} params
 * @param {object[]} params.candidates - raw candidate place objects from Places API
 * @param {object} params.tasteVector - user's taste vector
 * @param {number|undefined} params.userLat
 * @param {number|undefined} params.userLng
 * @param {string} params.context - 'solo'|'nearby'|'similar'|'home'|'tours'
 * @param {object} params.neighbors - collaborative filtering neighbor map
 * @param {object|null} params.countryPrior
 * @param {boolean} params.hasEnoughSignals
 * @param {Set<string>} params.seenSet - placeIds to exclude from results
 * @param {number} params.limit - max results to return
 * @param {number} params.epsilon - exploration probability (default 0.15)
 * @param {function} params.rng - random number generator (injectable for testing)
 * @returns {Array<{placeId, name, score, rank, reasons, breakdown, exploration}>}
 */
function rankCandidates({
  candidates, tasteVector, userLat, userLng, context,
  neighbors = {}, countryPrior = null, hasEnoughSignals = false,
  seenSet = new Set(), limit = 10, epsilon = 0.15, rng = Math.random,
  weatherContext = null,
}) {
  // Filter out places the user has already seen in this surface
  const fresh = candidates.filter((c) => c.placeId && !seenSet.has(c.placeId));

  // Score every fresh candidate
  const scored = fresh.map((c) => ({
    candidate: c,
    ...scoreCandidate({
      candidate: c, tasteVector, userLat, userLng, context,
      neighbors, countryPrior, hasEnoughSignals, weatherContext,
    }),
  }));

  // Sort descending by raw score before applying diversity penalty
  scored.sort((a, b) => b.score - a.score);

  // MMR diversity pass: penalise repeated picks of the same primary type
  const picked = [];
  const typeCounts = {}; // how many times has each primary type been picked so far?
  for (const s of scored) {
    const primary = (s.candidate.types && s.candidate.types[0]) || "unknown";
    const penalty = (typeCounts[primary] || 0) * 0.05; // 5% per repeat
    s.adjustedScore = s.score - penalty;
    picked.push(s);
    typeCounts[primary] = (typeCounts[primary] || 0) + 1;
  }

  // Re-sort by adjusted (diversity-penalised) score and take top `limit` results
  picked.sort((a, b) => b.adjustedScore - a.adjustedScore);
  const ranked = picked.slice(0, limit);

  // ε-greedy (item-level): 15% chance to splice 2 serendipity picks into the
  // ranked list at slots 4 and 9 (instead of replacing the entire result set).
  // Users still see mostly relevant results; exploration never dominates a page.
  if (rng() < epsilon && picked.length > limit) {
    const pool = picked.slice(limit); // candidates that didn't make the top-limit cut
    const shuffled = [...pool].sort(() => rng() - 0.5);
    const insertAt = [Math.min(4, ranked.length - 1), ranked.length - 1];
    for (let i = 0; i < Math.min(2, shuffled.length); i++) {
      shuffled[i]._exploration = true;
      ranked[insertAt[i]] = shuffled[i];
    }
  }

  return ranked.map((s, i) => ({
    placeId: s.candidate.placeId,
    name: s.candidate.name,
    score: Number(s.adjustedScore.toFixed(4)),
    rank: i,
    reasons: s._exploration ? ["Fresh discovery"] : s.reasons,
    breakdown: s._exploration ? {} : s.breakdown,
    exploration: !!s._exploration,
  }));
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. TASTE VECTOR UPDATE — applySignalToVector()
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Apply a single interaction signal to a taste vector in-place.
 *
 * For each canonical key in types + tags, we add `weight` to the vector's value
 * for that key. Missing keys start at 0 (neutral).
 *
 * This is the core learning mechanism. Every visit, save, booking, dismiss, etc.
 * runs through this function to shift the taste vector.
 *
 * @param {object} vector - the taste vector to mutate (from tasteVector or {})
 * @param {string[]} types - canonical type keys for the place
 * @param {string[]} tags - canonical tag keys for the place
 * @param {number} weight - the SIGNAL_WEIGHTS value for this interaction type
 * @returns {object} the mutated vector (same reference, mutated in-place)
 */
function applySignalToVector(vector, types, tags, weight) {
  const keys = [...normalizeKeys(types), ...normalizeKeys(tags)];
  for (const k of keys) {
    vector[k] = (vector[k] || 0) + weight;
  }
  return vector;
}

// ══════════════════════════════════════════════════════════════════════════════
// 7. CLOUD FUNCTION: recordTasteSignal
// ══════════════════════════════════════════════════════════════════════════════

/**
 * HTTPS Callable: recordTasteSignal
 * ──────────────────────────────────
 * Called by the Flutter app fire-and-forget (no await in UI path) whenever a
 * user interacts with a place. Updates the user's tasteVector in Firestore.
 *
 * Input (from Flutter RecommendationService.recordSignal):
 *   { placeId, placeName?, types[], tags[], signalType, source? }
 *
 * What it does in a single Firestore transaction:
 *   1. Reads the current tasteVector from users/{uid}
 *   2. Applies the signal weight to all relevant canonical keys
 *   3. Writes the updated tasteVector back to users/{uid}
 *   4. Appends placeId to users/{uid}.soloPlanSeen (capped at 200)
 *   5. Increments users/{uid}.signalCount
 *   6. Writes a signal document to users/{uid}/signals/{auto-id} (for collab later)
 *   7. Updates place_affinity/{placeId} with aggregate interaction counts
 *
 * Rate limit: 300/hour per user
 */
exports.recordTasteSignal = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const allowed = await checkRateLimit(request.auth.uid, "recordTasteSignal");
  if (!allowed) {
    throw new HttpsError("resource-exhausted", "Too many signals. Slow down.");
  }

  const uid = request.auth.uid;
  const {
    placeId, placeName, types = [], tags = [],
    signalType, source = "client",
  } = request.data || {};

  // Validate inputs
  if (!placeId || typeof placeId !== "string" || placeId.length > 200) {
    throw new HttpsError("invalid-argument", "Valid placeId required.");
  }
  if (!SIGNAL_WEIGHTS.hasOwnProperty(signalType)) {
    throw new HttpsError("invalid-argument", `Unknown signalType: ${signalType}`);
  }

  const weight = SIGNAL_WEIGHTS[signalType];
  const safeTypes = normalizeKeys(types);
  const safeTags = normalizeKeys(tags);

  const userRef = db().collection("users").doc(uid);
  const signalRef = userRef.collection("signals").doc(); // auto-ID
  const affinityRef = db().collection("place_affinity").doc(placeId);

  await db().runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.exists ? userSnap.data() : {};
    const vector = { ...(userData.tasteVector || {}) };

    // Apply the signal to the taste vector
    applySignalToVector(vector, safeTypes, safeTags, weight);

    // Maintain the "seen" set for this user (prevents showing the same place repeatedly)
    // We put the new placeId at the front and keep the most recent 200.
    const seen = Array.isArray(userData.soloPlanSeen) ? userData.soloPlanSeen : [];
    const newSeen = [placeId, ...seen.filter((p) => p !== placeId)].slice(0, 200);

    // Atomic write: taste vector + seen list + signal count
    tx.set(userRef, {
      tasteVector: vector,
      tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      soloPlanSeen: newSeen,
      signalCount: admin.firestore.FieldValue.increment(1),
    }, { merge: true });

    // Individual signal document — used by rebuildPlaceNeighbors for collab
    tx.set(signalRef, {
      placeId, placeName: placeName || null,
      types: safeTypes, tags: safeTags,
      signalType, weight, source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Aggregate affinity for this place across all users — used for analytics
    // and could power future "trending in Egypt" features.
    const affinityUpdate = {
      placeId,
      name: placeName || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (safeTypes.length) affinityUpdate.types = safeTypes;
    if (safeTags.length) affinityUpdate.tags = safeTags;
    const countField = `${signalType}Count`; // e.g., "visitCount", "saveCount"
    affinityUpdate[countField] = admin.firestore.FieldValue.increment(1);

    // Breakdown by nationality — powers the country_priors rebuild and future
    // "popular with Egyptian tourists" type labels.
    const nationality = userData.nationalityCode || userData.nationality || null;
    if (nationality && typeof nationality === "string") {
      affinityUpdate[`byCountry.${nationality.slice(0, 3).toUpperCase()}`] =
        admin.firestore.FieldValue.increment(1);
    }
    tx.set(affinityRef, affinityUpdate, { merge: true });

    // Crowd meter: bucket visits by hour-of-day (0–23). Each bucket key is
    // "h0"…"h23" so the Flutter client can read the last 2 hours without a CF call.
    if (signalType === "visit") {
      const hourKey = `h${new Date().getUTCHours()}`;
      tx.set(affinityRef, { crowdBuckets: { [hourKey]: admin.firestore.FieldValue.increment(1) } }, { merge: true });
    }
  });

  return { status: "ok" };
});

// ══════════════════════════════════════════════════════════════════════════════
// 7b. CLOUD FUNCTION: getCrowdLevel  (lightweight — reads place_affinity only)
// ══════════════════════════════════════════════════════════════════════════════
exports.getCrowdLevel = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");
  const { placeId } = request.data || {};
  if (!placeId) throw new HttpsError("invalid-argument", "placeId required.");

  const doc = await db().collection("place_affinity").doc(placeId).get();
  if (!doc.exists) return { level: "quiet", count: 0 };

  const buckets = doc.data().crowdBuckets || {};
  const now = new Date();
  const h = now.getUTCHours();
  const prev = (h - 1 + 24) % 24;
  const count = (buckets[`h${h}`] || 0) + (buckets[`h${prev}`] || 0);
  const level = count <= 2 ? "quiet" : count <= 8 ? "moderate" : "busy";
  return { level, count };
});

// ══════════════════════════════════════════════════════════════════════════════
// 8. CLOUD FUNCTION: recommendPlaces
// ══════════════════════════════════════════════════════════════════════════════

/**
 * HTTPS Callable: recommendPlaces
 * ─────────────────────────────────
 * The main recommendation function. Takes a list of candidate places (from the
 * Google Places API on the Flutter client) and returns them ranked by the
 * hybrid scoring formula.
 *
 * The Flutter client is responsible for fetching candidates from Google Places
 * API (nearby search by selected areas/radius) before calling this function.
 * This keeps Google Places API calls client-side (where the billing is already
 * set up) and reduces Cloud Function cold-start latency.
 *
 * Input:
 *   { candidates[], context, userLat?, userLng?, limit, excludeSeen, weatherContext? }
 *
 * What it does:
 *   1. Reads the user's tasteVector, signalCount, and soloPlanSeen from Firestore
 *   2. If new user (<5 signals): fetches country prior from country_priors/{code}
 *   3. Fetches Jaccard neighbors for the user's last 10 positively-signaled places
 *   4. Runs rankCandidates() with all the above context
 *   5. Returns ranked list with reasons[] + metadata
 *
 * Output:
 *   { recommendations: [...], meta: { signalCount, hasEnoughSignals, usedCountryPrior, candidatesEvaluated } }
 *
 * Rate limit: 60/hour per user
 */
exports.recommendPlaces = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const allowed = await checkRateLimit(request.auth.uid, "recommendPlaces");
  if (!allowed) {
    throw new HttpsError("resource-exhausted", "Recommendation rate limit hit.");
  }

  const uid = request.auth.uid;
  const {
    candidates, userLat, userLng,
    context = "solo", limit = 10, excludeSeen = true,
    weatherContext = null,
  } = request.data || {};

  if (!Array.isArray(candidates) || candidates.length === 0) {
    throw new HttpsError("invalid-argument", "Candidates array required.");
  }
  if (candidates.length > 200) {
    // Client should pre-filter to a reasonable set; 200 is generous
    throw new HttpsError("invalid-argument", "Too many candidates (max 200).");
  }

  // ── Fetch user data ────────────────────────────────────────────────────────
  const userSnap = await db().collection("users").doc(uid).get();
  const userData = userSnap.exists ? userSnap.data() : {};
  const tasteVector = userData.tasteVector || {};
  const signalCount = userData.signalCount || 0;
  const hasEnoughSignals = signalCount >= 5; // threshold: 5 non-quiz signals for personal mode

  // The "seen" set excludes places already recommended to this user
  const seenSet = excludeSeen && Array.isArray(userData.soloPlanSeen)
    ? new Set(userData.soloPlanSeen)
    : new Set();

  // ── Country prior (cold-start) ────────────────────────────────────────────
  // Only fetched when user has <5 signals AND we know their nationality.
  // nationalityCode is written to Firestore by EditProfileScreenEnhanced (and
  // ideally by signup — see roadmap audit #7) when the user picks a country.
  // Format: ISO 3166-1 alpha-2 (e.g. "EG", "US"). The slice(0, 3) below is a
  // defensive cap that also handles any legacy alpha-3 values.
  let countryPrior = null;
  if (!hasEnoughSignals && userData.nationalityCode) {
    const priorSnap = await db()
      .collection("country_priors")
      .doc(String(userData.nationalityCode).slice(0, 3).toUpperCase())
      .get();
    if (priorSnap.exists) countryPrior = priorSnap.data().tasteVector || null;
  }

  // ── Collaborative filtering neighbors ─────────────────────────────────────
  // For each of the user's last 10 positively-signaled places, look up their
  // Jaccard neighbors (other places co-liked by similar users). The neighbors
  // map is pre-built nightly by rebuildPlaceNeighbors — this is just a read.
  const neighbors = {};
  try {
    // Fetch the 30 most recent signals, then filter to positive ones in JS.
    // Ordering by createdAt (not weight) means recent saves/bookings seed the
    // collab component instead of being permanently overshadowed by old visits.
    const seedSnap = await db()
      .collection("users").doc(uid).collection("signals")
      .orderBy("createdAt", "desc")
      .limit(30)
      .get();
    const seedIds = seedSnap.docs
      .map((d) => d.data())
      .filter((d) => (d.weight || 0) > 0)
      .map((d) => d.placeId)
      .filter(Boolean)
      .slice(0, 10);
    if (seedIds.length) {
      // Fetch neighbor lists for all seed places in parallel
      const neighborDocs = await Promise.all(
        seedIds.map((id) => db().collection("place_neighbors").doc(id).get())
      );
      // Merge into a flat map: placeId → highest similarity across all seeds
      for (const nd of neighborDocs) {
        if (!nd.exists) continue;
        const list = nd.data().neighbors || [];
        for (const n of list) {
          // Take the max similarity if the same place appears as neighbor of multiple seeds
          neighbors[n.placeId] = Math.max(neighbors[n.placeId] || 0, n.similarity || 0);
        }
      }
    }
  } catch (e) {
    // Non-fatal — collaborative filtering just contributes 0 if this fails.
    // The recommendation still works, just without the collab component.
    console.warn("Neighbor lookup failed:", e.message);
  }

  // ── Run the ranking algorithm ─────────────────────────────────────────────
  const recommendations = rankCandidates({
    candidates, tasteVector, userLat, userLng, context,
    neighbors, countryPrior, hasEnoughSignals, seenSet, limit,
    weatherContext,
  });

  return {
    recommendations,
    meta: {
      signalCount,
      hasEnoughSignals,
      usedCountryPrior: !!countryPrior,
      candidatesEvaluated: candidates.length,
    },
  };
});

// ══════════════════════════════════════════════════════════════════════════════
// 9. CLOUD FUNCTION: warmStartTasteVector
// ══════════════════════════════════════════════════════════════════════════════

/**
 * HTTPS Callable: warmStartTasteVector
 * ──────────────────────────────────────
 * Bootstrap a new user's taste vector from data they've already generated
 * in the app before the recommendation engine was wired up.
 *
 * Called once after the user completes the quiz for the first time. The Flutter
 * client checks if users/{uid}.quizCompletedAt was previously null before calling.
 *
 * It reads three existing Firestore collections:
 *   - users/{uid}.savedPlaces → infer "save" signals (weight +0.6 per place)
 *   - bookings/{bookingId} for this user → infer "booking" signals (weight +0.8)
 *   - community_posts for this user with locationId → infer "post" signals (weight +0.5)
 *
 * For each of these, it looks up the place in the `places` collection to get
 * its category and tags, then applies the corresponding signal weight.
 *
 * Rate limited to 1/hour per user (server-side). Safe to call speculatively;
 * if already called today the rate limit silently returns "resource-exhausted"
 * which RecommendationService.warmStart() catches and ignores.
 */
exports.warmStartTasteVector = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const allowed = await checkRateLimit(request.auth.uid, "warmStartTasteVector");
  if (!allowed) {
    throw new HttpsError("resource-exhausted", "Already warm-started recently.");
  }

  const uid = request.auth.uid;
  const userRef = db().collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "User doc not found.");
  }
  const userData = userSnap.data();

  // Start from the existing tasteVector (may already have quiz signals)
  const vector = { ...(userData.tasteVector || {}) };
  let derived = 0; // count how many derived signals we add

  // ── Saved places → save signals ────────────────────────────────────────────
  const savedPlaces = Array.isArray(userData.savedPlaces) ? userData.savedPlaces : [];
  for (const placeId of savedPlaces.slice(0, 50)) { // cap at 50 to stay under 10s timeout
    const pSnap = await db().collection("places").doc(String(placeId)).get();
    if (!pSnap.exists) continue;
    const p = pSnap.data();
    applySignalToVector(vector, [p.category], p.tags || [], SIGNAL_WEIGHTS.save);
    derived++;
  }

  // ── Tour bookings → booking signals ───────────────────────────────────────
  // We don't have individual place types for tour destinations, so we use generic
  // tourist_attraction + cultural/historical as a proxy. Tours imply adventure intent.
  const bookingsSnap = await db()
    .collection("bookings")
    .where("userId", "==", uid)
    .limit(20)
    .get();
  for (const b of bookingsSnap.docs) {
    const destinations = Array.isArray(b.data().destinations) ? b.data().destinations : [];
    applySignalToVector(
      vector,
      ["tourist_attraction"],
      ["cultural", "historical"].concat(destinations.length ? ["adventure"] : []),
      SIGNAL_WEIGHTS.booking,
    );
    derived++;
  }

  // ── Community posts with locationId → post signals ────────────────────────
  // Users who posted about a place implicitly signal strong interest in it.
  const postsSnap = await db()
    .collection("community_posts")
    .where("userId", "==", uid)
    .limit(20)
    .get();
  for (const post of postsSnap.docs) {
    const locId = post.data().locationId;
    if (!locId) continue; // skip posts without a tagged location
    const pSnap = await db().collection("places").doc(String(locId)).get();
    if (!pSnap.exists) continue;
    const p = pSnap.data();
    applySignalToVector(vector, [p.category], p.tags || [], SIGNAL_WEIGHTS.post);
    derived++;
  }

  // Write the enriched vector back to Firestore
  await userRef.set({
    tasteVector: vector,
    tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    signalCount: admin.firestore.FieldValue.increment(derived),
    warmStartedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return { status: "ok", signalsDerived: derived, vectorSize: Object.keys(vector).length };
});

// ══════════════════════════════════════════════════════════════════════════════
// 10. CLOUD FUNCTION: applyQuizAnswers
// ══════════════════════════════════════════════════════════════════════════════

/**
 * HTTPS Callable: applyQuizAnswers
 * ──────────────────────────────────
 * Called when the user taps "Finish" at the end of the solo trip quiz.
 * Applies all quiz answer selections to the user's taste vector in one batch.
 *
 * Input:
 *   { answers: [{ optionId, types[], tags[] }, ...] }
 *
 * The Flutter client builds this answers[] list using
 * RecommendationMappings.answersFromSelections() from the user's quiz selections.
 * Both interest picks (Monuments, Beaches, etc.) and area picks (Luxor, Dahab,
 * etc.) generate answer entries — area picks carry implicit taste signals
 * (Luxor → historical/ancient, Dahab → natural/adventure).
 *
 * Each answer contributes SIGNAL_WEIGHTS.quiz (+0.5) to all its types and tags.
 * All answers are merged atomically so the vector never has partial state.
 * After this call, the client should also call warmStartTasteVector once to
 * bootstrap from historical Firestore data.
 */
exports.applyQuizAnswers = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const uid = request.auth.uid;
  const { answers } = request.data || {};
  if (!Array.isArray(answers) || answers.length === 0 || answers.length > 20) {
    throw new HttpsError("invalid-argument", "answers must be 1–20 items.");
  }

  // Build a combined delta vector from all quiz answers
  const userRef = db().collection("users").doc(uid);
  const vector = {};
  let picks = 0;
  for (const a of answers) {
    const types = normalizeKeys(a.types || []);
    const tags = normalizeKeys(a.tags || []);
    if (!types.length && !tags.length) continue; // skip entries with no valid keys
    applySignalToVector(vector, types, tags, SIGNAL_WEIGHTS.quiz);
    picks++;
  }
  if (picks === 0) {
    throw new HttpsError("invalid-argument", "No valid answers.");
  }

  // Merge the quiz delta into the existing tasteVector atomically.
  // Using a transaction ensures we don't overwrite signals from concurrent calls.
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const existing = snap.exists ? (snap.data().tasteVector || {}) : {};
    const merged = { ...existing };
    for (const k of Object.keys(vector)) {
      merged[k] = (merged[k] || 0) + vector[k];
    }
    tx.set(userRef, {
      tasteVector: merged,
      tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      quizCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      signalCount: admin.firestore.FieldValue.increment(picks),
    }, { merge: true });
  });

  return { status: "ok", picks };
});

// ══════════════════════════════════════════════════════════════════════════════
// 10b. CLOUD FUNCTION: resetTasteVector (HTTPS Callable, debug-only)
// ══════════════════════════════════════════════════════════════════════════════
//
// Clears all personalisation state for the calling user. Used by the
// "Reset Taste Signals (Debug)" tile in Settings to recover from a corrupted
// taste vector (e.g. a few accidental dismiss signals heavily skewing
// recommendations). Per-user only — never affects other accounts.

exports.resetTasteVector = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const uid = request.auth.uid;
  await db().collection("users").doc(uid).set({
    tasteVector: {},
    signalCount: 0,
    warmStartedAt: admin.firestore.FieldValue.delete(),
    tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    quizCompletedAt: admin.firestore.FieldValue.delete(),
  }, { merge: true });
  return { status: "ok" };
});

// ══════════════════════════════════════════════════════════════════════════════
// 11. SCHEDULED: decayTasteVectors (nightly 3:00 AM UTC)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Nightly taste vector decay — prevents the model from being permanently stuck
 * on things the user liked months ago.
 *
 * WHY DECAY?
 * A user who loved museums two years ago might prefer beach holidays now.
 * Without decay, old signals accumulate forever and the recommendations become
 * stale. We apply a 2% daily decay (factor 0.98), giving a half-life of ~35 days.
 *
 * This means: a visit signal (+1.0) is worth 0.5 after 35 days, 0.25 after 70 days.
 * Recent signals always dominate over old ones naturally.
 *
 * The decayed values are written back to users/{uid}.tasteVector in 400-op batches
 * (Firestore batch limit is 500, we stay under it with headroom).
 *
 * Only users who have at least 1 signal are processed (signalCount > 0 filter).
 */
exports.decayTasteVectors = onSchedule(
  { schedule: "0 3 * * *", timeZone: "UTC", region: "europe-west1" },
  async () => {
    const snapshot = await db().collection("users")
      .where("signalCount", ">", 0)
      .get();
    const decayFactor = 0.98; // 2% decay per day → ~35-day half-life
    let batch = db().batch();
    let ops = 0;
    for (const doc of snapshot.docs) {
      const v = doc.data().tasteVector || {};
      const decayed = {};
      for (const k of Object.keys(v)) decayed[k] = v[k] * decayFactor;
      batch.update(doc.ref, { tasteVector: decayed });
      ops++;
      if (ops % 400 === 0) {
        await batch.commit();
        batch = db().batch();
      }
    }
    if (ops % 400 !== 0) await batch.commit();
    console.log(`decayTasteVectors: decayed ${ops} users`);
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 12. SCHEDULED: rebuildPlaceNeighbors (nightly 4:00 AM UTC)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Item-item collaborative filtering — the "people who liked X also liked Y" component.
 *
 * HOW IT WORKS (Jaccard similarity):
 *
 *   1. For each user who has signals, collect the set of placeIds they interacted
 *      with positively in the last 90 days.
 *
 *   2. Build an inverted index: placeId → Set of user IDs who interacted with it.
 *
 *   3. For each pair of places (A, B) that share at least 2 users in common:
 *        Jaccard(A, B) = |users_A ∩ users_B| / |users_A ∪ users_B|
 *      Only keep pairs with Jaccard ≥ 0.05 and at least 3 users per place.
 *
 *   4. For each place, keep the top 20 most-similar neighbors (sorted by Jaccard).
 *
 *   5. Write results to place_neighbors/{placeId}.neighbors = [{placeId, similarity}]
 *
 * The 90-day lookback window keeps results fresh. The minimum 3-user threshold
 * prevents noise from obscure places that only 1 person has visited.
 *
 * WHY JACCARD INSTEAD OF COSINE?
 * For binary co-occurrence (did user A also visit B? yes/no), Jaccard is simpler
 * and works well. Cosine would require full taste vectors which we already use
 * for the taste-match component. Jaccard gives a clean, interpretable similarity.
 *
 * NOTE: This is computationally expensive for large user bases (O(n²) over places).
 * At current app scale it runs fine in the nightly window. If the user base grows
 * to 100k+, we'd want to shard this or move to ALS/matrix factorisation.
 */
exports.rebuildPlaceNeighbors = onSchedule(
  { schedule: "0 4 * * *", timeZone: "UTC", region: "europe-west1" },
  async () => {
    const sinceMs = Date.now() - 90 * 24 * 60 * 60 * 1000; // 90 days ago
    const since = admin.firestore.Timestamp.fromMillis(sinceMs);

    // Step 1: Collect each user's set of positively-signaled places in the last 90 days
    const userPlaces = new Map(); // uid → Set<placeId>
    const usersSnap = await db().collection("users").where("signalCount", ">", 0).get();
    for (const u of usersSnap.docs) {
      const sigs = await u.ref.collection("signals")
        .where("createdAt", ">=", since)
        .where("weight", ">", 0)  // only positive signals (not dismiss/view)
        .get();
      const set = new Set(sigs.docs.map((d) => d.data().placeId).filter(Boolean));
      if (set.size > 0) userPlaces.set(u.id, set);
    }

    // Step 2: Build inverted index — placeId → Set<uid>
    const placeUsers = new Map();
    for (const [uid, set] of userPlaces) {
      for (const pid of set) {
        if (!placeUsers.has(pid)) placeUsers.set(pid, new Set());
        placeUsers.get(pid).add(uid);
      }
    }

    // Step 3: Compute Jaccard similarity for all place pairs with sufficient co-occurrence
    const neighborsByPlace = new Map(); // placeId → [{placeId, similarity}]
    const placeIds = [...placeUsers.keys()];
    for (let i = 0; i < placeIds.length; i++) {
      const a = placeIds[i];
      const usersA = placeUsers.get(a);
      if (usersA.size < 3) continue; // skip if fewer than 3 users visited this place

      for (let j = i + 1; j < placeIds.length; j++) {
        const b = placeIds[j];
        const usersB = placeUsers.get(b);
        if (usersB.size < 3) continue;

        // Count users in the intersection (visited both A and B)
        let intersection = 0;
        for (const u of usersA) if (usersB.has(u)) intersection++;
        if (intersection < 2) continue; // need at least 2 shared users

        const union = usersA.size + usersB.size - intersection;
        const sim = intersection / union; // Jaccard index
        if (sim < 0.05) continue; // ignore very weak similarity

        // Record bidirectional similarity (A is neighbor of B and vice versa)
        if (!neighborsByPlace.has(a)) neighborsByPlace.set(a, []);
        if (!neighborsByPlace.has(b)) neighborsByPlace.set(b, []);
        neighborsByPlace.get(a).push({ placeId: b, similarity: sim });
        neighborsByPlace.get(b).push({ placeId: a, similarity: sim });
      }
    }

    // Step 4 & 5: Sort each place's neighbors by similarity, keep top 20, write to Firestore
    let batch = db().batch();
    let ops = 0;
    for (const [pid, list] of neighborsByPlace) {
      list.sort((x, y) => y.similarity - x.similarity); // highest similarity first
      const top = list.slice(0, 20); // keep only the 20 most similar neighbors
      batch.set(
        db().collection("place_neighbors").doc(pid),
        { neighbors: top, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
      ops++;
      if (ops % 400 === 0) {
        await batch.commit();
        batch = db().batch();
      }
    }
    if (ops % 400 !== 0) await batch.commit();
    console.log(`rebuildPlaceNeighbors: wrote neighbors for ${ops} places`);
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 13. SCHEDULED: rebuildCountryPriors (weekly Sunday 2:00 AM UTC)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Country-level cold-start priors — the "what do people from your country like?" component.
 *
 * HOW IT WORKS:
 *   For each user who has a nationalityCode set, take their tasteVector and add it
 *   to a running sum for their country. After processing all users, compute the
 *   per-key average and write it to country_priors/{code}.tasteVector.
 *
 * This average vector is then used in scoreCandidate() for new users who haven't
 * accumulated 5 personal signals yet. The logic: "you haven't told us much about
 * yourself yet, but we know that users from Egypt tend to love archaeological sites,
 * users from France tend to love art galleries, etc."
 *
 * Minimum sample size of 3 users per country — below this, the average is noisy.
 *
 * WHY WEEKLY INSTEAD OF NIGHTLY?
 * Country priors are a slow-moving average that doesn't change meaningfully from
 * day to day. Weekly is sufficient and avoids running this expensive aggregate
 * every night.
 *
 * Runs the night after the nightly decay job (Sunday 2 AM = after Saturday
 * night's decay), so the averaged vectors already reflect the latest decay.
 */
exports.rebuildCountryPriors = onSchedule(
  { schedule: "0 2 * * 0", timeZone: "UTC", region: "europe-west1" }, // Sunday 2:00 AM UTC
  async () => {
    const byCountry = new Map(); // code → { sum: {key: total}, count: int }
    const usersSnap = await db().collection("users")
      .where("signalCount", ">", 0)
      .get();

    // Accumulate taste vectors per country
    for (const u of usersSnap.docs) {
      const d = u.data();
      const code = (d.nationalityCode || "").slice(0, 3).toUpperCase();
      if (!code) continue; // skip users without nationalityCode

      const v = d.tasteVector || {};
      if (!byCountry.has(code)) byCountry.set(code, { sum: {}, count: 0 });
      const bucket = byCountry.get(code);
      for (const k of Object.keys(v)) bucket.sum[k] = (bucket.sum[k] || 0) + v[k];
      bucket.count++;
    }

    // Compute per-key averages and write to country_priors collection
    let batch = db().batch();
    let ops = 0;
    for (const [code, { sum, count }] of byCountry) {
      if (count < 3) continue; // need minimum sample size to be meaningful
      const avg = {};
      for (const k of Object.keys(sum)) avg[k] = sum[k] / count;
      batch.set(db().collection("country_priors").doc(code), {
        tasteVector: avg,
        sampleSize: count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      ops++;
      if (ops % 400 === 0) { await batch.commit(); batch = db().batch(); }
    }
    if (ops % 400 !== 0) await batch.commit();
    console.log(`rebuildCountryPriors: wrote priors for ${ops} countries`);
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════════════════
// 13b. SCHEDULED: sendDailyDiscovery — personalized "Did you know?" push
//      Runs daily at 9:00 AM UTC. Picks a landmark matching each user's top
//      taste key, generates a short Groq fact, sends via FCM.
// ══════════════════════════════════════════════════════════════════════════════

// Famous Egyptian landmarks pool — Places API is the production source for live
// data; this list is the daily-push candidate set (static, curated, no API call).
//
// Keys MUST be drawn from CANONICAL_TYPES / CANONICAL_TAGS at the top of this
// file — otherwise the dot-product scoring below ignores them silently and
// personalisation degrades to random.
// `lat`/`lng` let the client deep-link the daily push straight to the pin on
// the map (the client resolves the name+coords to the real dataset entry).
const DISCOVERY_POOL = [
  { name: "Karnak Temple",              lat: 25.7188, lng: 32.6573, types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical", "religious"] },
  { name: "Abu Simbel",                 lat: 22.3372, lng: 31.6258, types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Valley of the Kings",        lat: 25.7402, lng: 32.6014, types: ["archaeological_site"],             tags: ["ancient", "pharaonic", "historical", "cultural"] },
  { name: "Bibliotheca Alexandrina",    lat: 31.2089, lng: 29.9092, types: ["museum"],                          tags: ["cultural", "modern"] },
  { name: "Siwa Oasis",                 lat: 29.2041, lng: 25.5195, types: ["park", "tourist_attraction"],      tags: ["natural", "adventure", "relaxation"] },
  { name: "Dahab Blue Hole",            lat: 28.5722, lng: 34.5375, types: ["beach"],                           tags: ["natural", "adventure"] },
  { name: "Khan el-Khalili",            lat: 30.0477, lng: 31.2622, types: ["market"],                          tags: ["islamic", "shopping", "cultural", "historical"] },
  { name: "Luxor Temple",               lat: 25.6997, lng: 32.6391, types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Citadel of Saladin",         lat: 30.0294, lng: 31.2611, types: ["historical_landmark", "monument"], tags: ["islamic", "historical", "religious"] },
  { name: "White Desert",               lat: 27.2879, lng: 28.1810, types: ["park", "tourist_attraction"],      tags: ["natural", "adventure"] },
  { name: "Edfu Temple",                lat: 24.9779, lng: 32.8732, types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Ras Muhammad National Park", lat: 27.7333, lng: 34.2500, types: ["park", "beach"],                   tags: ["natural", "adventure"] },
];

exports.sendDailyDiscovery = onSchedule(
  { schedule: "0 9 * * *", region: "europe-west1", secrets: [groqApiKey] },
  async () => {
    const usersSnap = await db().collection("users")
      .where("preferences.notifications", "==", true)
      .select("fcmToken", "tasteVector", "notificationPreferences")
      .limit(500)
      .get();

    const APP_LOGO_URL = "https://firebasestorage.googleapis.com/v0/b/lost-in-egypt-elasly.firebasestorage.app/o/logo_colorful_comp.png?alt=media&token=ab162f0f-4b26-406a-9943-f5165c972b4e";

    const tasks = usersSnap.docs.map(async (userDoc) => {
      try {
        const { fcmToken, tasteVector = {}, notificationPreferences = {} } = userDoc.data();
        if (!fcmToken) return;
        // Respect the dedicated dailyDiscovery preference (defaults true)
        if (notificationPreferences.dailyDiscovery === false) return;

        // Rank the pool by how well each entry's types+tags overlap the user's
        // taste vector (highest first; ties keep pool order).
        const scored = DISCOVERY_POOL
          .map((landmark) => {
            let score = 0;
            for (const t of landmark.types) score += tasteVector[t] || 0;
            for (const t of landmark.tags || []) score += tasteVector[t] || 0;
            return { landmark, score };
          })
          .sort((a, b) => b.score - a.score);

        // Rotate through the top matches by day-of-year so the SAME user gets a
        // DIFFERENT landmark each day instead of the single deterministic top
        // pick (the "same place every day" bug). When the user has no taste
        // signal yet (top score 0) the whole pool is in play. A per-user offset
        // keeps two identical-taste users from seeing the same pick on a day.
        const hasTaste = scored[0].score > 0;
        const rotationSize = hasTaste ? Math.min(5, scored.length) : scored.length;
        const now = new Date();
        const dayOfYear = Math.floor(
          (Date.now() - Date.UTC(now.getUTCFullYear(), 0, 0)) / 86400000
        );
        let userOffset = 0;
        for (let i = 0; i < userDoc.id.length; i++) {
          userOffset += userDoc.id.charCodeAt(i);
        }
        const bestMatch = scored[(dayOfYear + userOffset) % rotationSize].landmark;

        // Generate a short "Did you know?" fact via Groq
        const groqRes = await fetch("https://api.groq.com/openai/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${groqApiKey.value()}`,
          },
          body: JSON.stringify({
            model: "llama-3.3-70b-versatile",
            messages: [{
              role: "user",
              content: `Write one fascinating "Did you know?" fact about ${bestMatch.name} in Egypt. Max 20 words. No emojis. Just the fact, no label.`,
            }],
            max_tokens: 60,
            temperature: 0.8,
          }),
        });
        const groqData = await groqRes.json();
        const fact = groqData.choices?.[0]?.message?.content?.trim() || `Discover ${bestMatch.name} today`;

        const title = `📍 ${bestMatch.name}`;
        // Deep-link payload the client decodes to focus the pin on the map:
        // "<name>|<lat>|<lng>". Kept in deepLinkTargetId because the in-app
        // notification model only round-trips that single field.
        const deepLink = `${bestMatch.name}|${bestMatch.lat}|${bestMatch.lng}`;

        // Write in-app notification document so it appears in the notification centre
        await db().collection("users").doc(userDoc.id)
          .collection("notifications").add({
            recipientId: userDoc.id,
            senderId: "system",
            senderName: "Lost in Egypt",
            senderAvatar: APP_LOGO_URL,
            title,
            message: fact,
            type: "daily_discovery",
            deepLinkTargetId: deepLink,
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Send FCM push
        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body: fact },
          data: {
            type: "daily_discovery",
            landmark: bestMatch.name,
            lat: String(bestMatch.lat),
            lng: String(bestMatch.lng),
          },
          android: {
            notification: {
              channelId: "high_importance_channel",
              priority: "high",
              color: "#D6A00F",
              imageUrl: APP_LOGO_URL,
            },
          },
          apns: { payload: { aps: { contentAvailable: true } } },
        });
      } catch (_) { /* skip individual user errors */ }
    });

    await Promise.allSettled(tasks);
    console.log(`sendDailyDiscovery: processed ${usersSnap.docs.length} users`);
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 13a. SCHEDULED: sendWeeklyRecommendations (Sundays 10:00 UTC)
// ══════════════════════════════════════════════════════════════════════════════
//
// Weekly "here are 3 places you'd love" push notification. Sundays at 10:00 UTC
// = 12:00 Cairo local, the natural weekend-planning hour.
//
// For each user with notifications=true AND signalCount >= 1 (i.e. has at least
// some taste data) AND weeklyRecommendations pref != false, score the curated
// WEEKLY_REC_POOL against the user's tasteVector (simple dot product over
// matching types/tags), pick the top 3, and send a combined push + in-app
// notification.
//
// Why a curated pool rather than Places API? Same reasoning as sendDailyDiscovery:
// keeps the function self-contained (no extra API key/cost), and the 20-item
// pool is broad enough to surface meaningful variety for any taste profile.

// Curated 20-landmark pool — broad coverage across Egypt's main regions and
// taste profiles. Each entry has the canonical types + tags it embodies, so
// scoring is a simple dot product over the user's tasteVector.
const WEEKLY_REC_POOL = [
  { name: "Pyramids of Giza",             types: ["monument", "historical_landmark"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Grand Egyptian Museum",        types: ["museum"], tags: ["ancient", "pharaonic", "historical", "cultural", "modern"] },
  { name: "Khan el-Khalili",              types: ["market"], tags: ["islamic", "shopping", "cultural", "historical"] },
  { name: "Al-Azhar Park",                types: ["park"], tags: ["relaxation", "natural", "family"] },
  { name: "Citadel of Saladin",           types: ["historical_landmark", "monument"], tags: ["islamic", "historical"] },
  { name: "Coptic Cairo",                 types: ["church", "tourist_attraction"], tags: ["coptic", "religious", "historical"] },
  { name: "Karnak Temple",                types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Valley of the Kings",          types: ["archaeological_site"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Luxor Temple",                 types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Abu Simbel",                   types: ["archaeological_site", "monument"], tags: ["ancient", "pharaonic", "historical"] },
  { name: "Philae Temple",                types: ["archaeological_site"], tags: ["ancient", "pharaonic", "religious"] },
  { name: "Siwa Oasis",                   types: ["park", "tourist_attraction"], tags: ["natural", "adventure", "relaxation"] },
  { name: "White Desert",                 types: ["park", "tourist_attraction"], tags: ["natural", "adventure"] },
  { name: "Dahab Blue Hole",              types: ["beach"], tags: ["natural", "adventure"] },
  { name: "Ras Muhammad National Park",   types: ["park", "beach"], tags: ["natural", "adventure"] },
  { name: "Hurghada Marina",              types: ["restaurant", "shopping_mall"], tags: ["modern", "relaxation", "entertainment", "luxury"] },
  { name: "Bibliotheca Alexandrina",      types: ["museum", "art_gallery"], tags: ["modern", "cultural"] },
  { name: "Citadel of Qaitbay",           types: ["historical_landmark", "monument"], tags: ["historical", "islamic"] },
  { name: "El Sahel North Coast",         types: ["beach"], tags: ["luxury", "relaxation", "modern"] },
  { name: "Cairo Opera House",            types: ["art_gallery", "stadium"], tags: ["cultural", "modern", "entertainment"] },
];

exports.sendWeeklyRecommendations = onSchedule(
  { schedule: "0 10 * * 0", region: "europe-west1" },
  async () => {
    const usersSnap = await db().collection("users")
      .where("preferences.notifications", "==", true)
      .where("signalCount", ">=", 1)
      .select("fcmToken", "notificationPreferences")
      .limit(1000)
      .get();

    const APP_LOGO_URL = "https://firebasestorage.googleapis.com/v0/b/lost-in-egypt-elasly.firebasestorage.app/o/logo_colorful_comp.png?alt=media&token=ab162f0f-4b26-406a-9943-f5165c972b4e";

    let sent = 0;
    const tasks = usersSnap.docs.map(async (userDoc) => {
      try {
        const { fcmToken, notificationPreferences = {} } = userDoc.data();
        if (!fcmToken) return;
        // Per-user opt-out — default true (opt-in by default)
        if (notificationPreferences.weeklyRecommendations === false) return;

        // Pull the full tasteVector — we only selected a subset of fields above
        const fullDoc = await userDoc.ref.get();
        const tasteVector = fullDoc.data()?.tasteVector || {};

        // Score each pool entry as the dot product of its keys against the
        // user's tasteVector. Higher = better match.
        const scored = WEEKLY_REC_POOL.map((place) => {
          let score = 0;
          for (const k of place.types) score += tasteVector[k] || 0;
          for (const k of place.tags) score += tasteVector[k] || 0;
          return { place, score };
        }).sort((a, b) => b.score - a.score);

        // Require at least one positive-score match — if everything's 0 or
        // negative the user has no actionable preference yet; skip to avoid
        // spamming with random picks.
        if (scored[0].score <= 0) return;

        const top3 = scored.slice(0, 3).map((s) => s.place.name);
        const title = "✨ This week's picks for you";
        const body = `${top3.join(" · ")} — handpicked from what you love`;

        await userDoc.ref.collection("notifications").add({
          recipientId: userDoc.id,
          senderId: "system",
          senderName: "Lost in Egypt",
          senderAvatar: APP_LOGO_URL,
          title,
          message: body,
          type: "weekly_recommendations",
          deepLinkTargetId: "",
          isRead: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          data: { type: "weekly_recommendations", targetId: "" },
          android: {
            notification: {
              channelId: "high_importance_channel",
              priority: "high",
              color: "#D6A00F",
              imageUrl: APP_LOGO_URL,
            },
          },
          apns: { payload: { aps: { contentAvailable: true } } },
        });
        sent++;
      } catch (_) { /* skip individual errors */ }
    });

    await Promise.allSettled(tasks);
    console.log(`sendWeeklyRecommendations: processed ${usersSnap.docs.length} users, sent ${sent} pushes`);
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 13b. SCHEDULED: sendWeatherAlertForSavedPlans (nightly 18:00 UTC)
// ══════════════════════════════════════════════════════════════════════════════
//
// For every user with an ACTIVE solo plan, fetch tomorrow's forecast at the
// plan's next incomplete stop. If the forecast indicates a sandstorm,
// extreme heat (feels-like ≥ 38°C), or extreme UV (UV ≥ 10), send a
// `weather_alert` push notification + write an in-app notification.
//
// Saved (not-yet-started) plans are skipped — they have no concrete trip date,
// so an alert would be premature.
//
// Run at 18:00 UTC = 20:00 Cairo local time, so the alert hits during the
// natural evening planning window.

const SANDSTORM_WMO = new Set([30, 31, 32, 33, 34, 35, 98]);

exports.sendWeatherAlertForSavedPlans = onSchedule(
  { schedule: "0 18 * * *", region: "europe-west1" },
  async () => {
    const usersSnap = await db().collection("users")
      .where("preferences.notifications", "==", true)
      .select("fcmToken", "notificationPreferences")
      .limit(500)
      .get();

    let alertsSent = 0;

    const tasks = usersSnap.docs.map(async (userDoc) => {
      try {
        const { fcmToken, notificationPreferences = {} } = userDoc.data();
        if (!fcmToken) return;
        if (notificationPreferences.weatherAlert === false) return;

        // Active plans only — saved plans have no trip date yet
        const plansSnap = await userDoc.ref.collection("solo_plans")
          .where("status", "==", "active")
          .limit(1)
          .get();
        if (plansSnap.empty) return;
        const plan = plansSnap.docs[0];
        const planData = plan.data();

        // Find the first incomplete stop with coords across all days
        let target = null;
        for (const day of planData.days || []) {
          for (const stop of day.stops || []) {
            if (stop.completed) continue;
            if (stop.lat != null && stop.lng != null) {
              target = stop;
              break;
            }
          }
          if (target) break;
        }
        if (!target) return;

        // Open-Meteo — free, no key, no rate limit. Daily forecast for tomorrow.
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${target.lat}&longitude=${target.lng}` +
          "&daily=weather_code,apparent_temperature_max,uv_index_max" +
          "&forecast_days=2&timezone=auto";
        const res = await fetch(url);
        if (!res.ok) return;
        const data = await res.json();
        const daily = data.daily || {};
        // index 0 = today, index 1 = tomorrow
        const wmoCode = daily.weather_code?.[1];
        const feels   = daily.apparent_temperature_max?.[1];
        const uv      = daily.uv_index_max?.[1];
        if (wmoCode == null && feels == null && uv == null) return;

        let condition = null;
        let body = null;
        if (wmoCode != null && SANDSTORM_WMO.has(wmoCode)) {
          condition = "Sandstorm";
          body = `Sandstorm forecast tomorrow near ${target.name}. Consider rescheduling outdoor stops.`;
        } else if (feels != null && feels >= 38) {
          condition = "Extreme Heat";
          body = `Feels like ${Math.round(feels)}°C tomorrow at ${target.name}. Start before 9am or shift to indoor stops.`;
        } else if (uv != null && uv >= 10) {
          condition = "Extreme UV";
          body = `UV ${Math.round(uv)} forecast tomorrow at ${target.name}. Bring SPF 50+, hat, and water.`;
        }
        if (!condition) return; // No advisory — skip

        const title = `⚠ ${condition} — Tomorrow's Tour`;

        await userDoc.ref.collection("notifications").add({
          recipientId: userDoc.id,
          senderId: "system",
          senderName: "Lost in Egypt",
          senderAvatar: "",
          title,
          message: body,
          type: "weather_alert",
          deepLinkTargetId: plan.id,
          isRead: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          data: { type: "weather_alert", targetId: plan.id },
          android: {
            notification: {
              channelId: "high_importance_channel",
              priority: "high",
              color: "#D6A00F",
            },
          },
          apns: { payload: { aps: { badge: 1, sound: "default" } } },
        });
        alertsSent++;
      } catch (_) { /* skip individual user errors */ }
    });

    await Promise.allSettled(tasks);
    console.log(`sendWeatherAlertForSavedPlans: processed ${usersSnap.docs.length} users, sent ${alertsSent} alerts`);
  }
);

// 14. _internal exports — for local testing WITHOUT Firebase credentials
// ══════════════════════════════════════════════════════════════════════════════

/**
 * These are pure functions (no Firebase calls) exported for local testing.
 *
 * To run the sample script:
 *   cd functions
 *   node scripts/sample_recommendation.js --user=history --context=solo
 *   node scripts/sample_recommendation.js --user=beach --context=nearby
 *   node scripts/sample_recommendation.js --user=newuser --context=home
 *
 * Available --user profiles: history, beach, local, newuser
 * Available --context values: solo, nearby, similar, home
 *
 * The script prints a ranked list with scores, reasons, and breakdown for each
 * candidate, so you can verify the scoring formula works as expected without
 * deploying to Firebase or needing any API keys.
 */
exports._internal = {
  scoreCandidate,
  rankCandidates,
  applySignalToVector,
  haversineKm,
  cosineSim,
  normalizeKeys,
  CANONICAL_TYPES,
  CANONICAL_TAGS,
  SIGNAL_WEIGHTS,
};
