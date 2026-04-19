/**
 * Recommendation Engine — Lost in Egypt
 *
 * Exports Cloud Functions (HTTPS Callables + schedulers) and a pure scoring
 * core that can be unit-tested or run locally via scripts/sample_recommendation.js
 * without deploying anything.
 *
 * See project_recommendation_engine.md in memory for the full design doc.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

// Lazy-init admin — index.js calls initializeApp() before requiring this module.
function db() {
  return admin.firestore();
}

// ── Canonical taste vector keys ──────────────────────────────────────────────
const CANONICAL_TYPES = [
  "museum", "historical_landmark", "tourist_attraction", "mosque", "church",
  "park", "restaurant", "cafe", "shopping_mall", "market", "beach", "zoo",
  "art_gallery", "amusement_park", "aquarium", "monument",
  "archaeological_site", "night_club", "spa", "stadium",
];
const CANONICAL_TAGS = [
  "cultural", "historical", "religious", "natural", "modern", "ancient",
  "islamic", "coptic", "pharaonic", "luxury", "budget", "family", "adventure",
  "relaxation", "food", "shopping", "entertainment",
];
const CANONICAL_KEYS = new Set([...CANONICAL_TYPES, ...CANONICAL_TAGS]);

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

const RATE_LIMITS = {
  recommendPlaces: 60,
  recordTasteSignal: 300,
  warmStartTasteVector: 1,
};

// ── Rate limiting (mirrors pattern from index.js) ────────────────────────────
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

// ── Pure helpers (no Firebase deps — unit-testable) ──────────────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function clamp(x, lo, hi) {
  return Math.max(lo, Math.min(hi, x));
}

function normalizeKeys(keys) {
  if (!Array.isArray(keys)) return [];
  return keys
    .map((k) => String(k).toLowerCase().trim())
    .filter((k) => CANONICAL_KEYS.has(k));
}

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

// ── Scoring core ─────────────────────────────────────────────────────────────
/**
 * Score a single candidate against a user taste vector + context.
 * Pure function — returns { score, breakdown, reasons[] }.
 */
function scoreCandidate({
  candidate,       // { placeId, name, types[], tags[], rating, userRatingCount, lat, lng }
  tasteVector,     // Map<string, number>
  userLat, userLng,
  context,         // 'solo'|'nearby'|'similar'|'home'
  neighbors,       // Map<placeId, similarity> for the user's recent seed places (may be empty)
  countryPrior,    // Map<string, number> or null
  hasEnoughSignals,// true once user has ≥5 non-quiz signals
}) {
  const keys = [...normalizeKeys(candidate.types), ...normalizeKeys(candidate.tags)];

  // 1. taste match (average over keys present)
  let tasteMatch = 0;
  if (keys.length > 0) {
    const sum = keys.reduce((acc, k) => acc + (tasteVector[k] || 0), 0);
    tasteMatch = sum / keys.length;
  }
  // Squash into roughly [-1, 1]
  tasteMatch = clamp(tasteMatch / 3, -1, 1);

  // 2. rating
  const rating = typeof candidate.rating === "number" ? candidate.rating : 3.5;
  const ratingScore = clamp((rating - 3.5) / 1.5, -1, 1);

  // 3. proximity
  let proximity = 0;
  let distanceKm = null;
  if (typeof userLat === "number" && typeof userLng === "number" &&
      typeof candidate.lat === "number" && typeof candidate.lng === "number") {
    distanceKm = haversineKm(userLat, userLng, candidate.lat, candidate.lng);
    proximity = 1 / (1 + distanceKm / 5);
  }

  // 4. popularity
  const urc = Number(candidate.userRatingCount || 0);
  const popularity = clamp(Math.log10(1 + urc) / 4, 0, 1);

  // 5. collab
  const collab = neighbors && neighbors[candidate.placeId] ? neighbors[candidate.placeId] : 0;

  // 6. country prior (cold-start fallback)
  let priorScore = 0;
  if (countryPrior && !hasEnoughSignals) {
    const cPrior = {};
    for (const k of keys) cPrior[k] = 1;
    priorScore = cosineSim(cPrior, countryPrior);
  }

  // Default weights
  let w = { taste: 0.40, rating: 0.15, proximity: 0.20, popularity: 0.10, collab: 0.15 };
  if (context === "nearby")  w = { ...w, proximity: 0.30, taste: 0.30 };
  if (context === "similar") w = { ...w, collab: 0.30, taste: 0.30 };
  if (context === "home")    w = { ...w, popularity: 0.15, proximity: 0.15 };

  // Cold-start: swap taste weight onto country prior
  if (!hasEnoughSignals && countryPrior) {
    w = { ...w, taste: 0.10 };
  }

  const score =
    w.taste * tasteMatch +
    w.rating * ratingScore +
    w.proximity * proximity +
    w.popularity * popularity +
    w.collab * collab +
    (!hasEnoughSignals && countryPrior ? 0.30 * priorScore : 0);

  // Build reasons (top 2 contributors)
  const contributions = [
    { key: "taste", value: w.taste * tasteMatch,
      text: tasteMatch > 0.1 ? interestReason(keys, tasteVector) : null },
    { key: "proximity", value: w.proximity * proximity,
      text: distanceKm != null && distanceKm < 10 ? `${distanceKm.toFixed(1)} km away` : null },
    { key: "rating", value: w.rating * ratingScore,
      text: rating >= 4.3 ? `Highly rated (${rating.toFixed(1)}★)` : null },
    { key: "popularity", value: w.popularity * popularity,
      text: urc > 500 ? "Popular with travelers" : null },
    { key: "collab", value: w.collab * collab,
      text: collab > 0.2 ? "Similar to places you liked" : null },
    { key: "country", value: (!hasEnoughSignals && countryPrior ? 0.30 * priorScore : 0),
      text: priorScore > 0.2 ? "Popular with travelers from your country" : null },
  ];
  const reasons = contributions
    .filter((c) => c.text && c.value > 0)
    .sort((a, b) => b.value - a.value)
    .slice(0, 2)
    .map((c) => c.text);

  return {
    score,
    breakdown: { tasteMatch, ratingScore, proximity, popularity, collab, priorScore, distanceKm },
    reasons,
  };
}

function interestReason(keys, tasteVector) {
  let best = null, bestVal = 0;
  for (const k of keys) {
    const v = tasteVector[k] || 0;
    if (v > bestVal) { best = k; bestVal = v; }
  }
  if (!best) return null;
  const label = best.replace(/_/g, " ");
  return `Matches your interest in ${label}`;
}

/**
 * Rank a list of candidates.
 * Pure function — returns sorted recommendation list with MMR diversity
 * penalty and ε-greedy exploration applied.
 */
function rankCandidates({
  candidates, tasteVector, userLat, userLng, context,
  neighbors = {}, countryPrior = null, hasEnoughSignals = false,
  seenSet = new Set(), limit = 10, epsilon = 0.15, rng = Math.random,
}) {
  const fresh = candidates.filter((c) => c.placeId && !seenSet.has(c.placeId));

  // ε-greedy: 15% chance to just shuffle and return
  if (rng() < epsilon && fresh.length > 0) {
    const shuffled = [...fresh].sort(() => rng() - 0.5);
    return shuffled.slice(0, limit).map((c, i) => ({
      placeId: c.placeId,
      name: c.name,
      score: 0,
      rank: i,
      reasons: ["Fresh discovery"],
      breakdown: {},
      exploration: true,
    }));
  }

  const scored = fresh.map((c) => ({
    candidate: c,
    ...scoreCandidate({
      candidate: c, tasteVector, userLat, userLng, context,
      neighbors, countryPrior, hasEnoughSignals,
    }),
  }));

  scored.sort((a, b) => b.score - a.score);

  // MMR diversity: penalize consecutive picks sharing primary type
  const picked = [];
  const typeCounts = {};
  for (const s of scored) {
    const primary = (s.candidate.types && s.candidate.types[0]) || "unknown";
    const penalty = (typeCounts[primary] || 0) * 0.05;
    s.adjustedScore = s.score - penalty;
    picked.push(s);
    typeCounts[primary] = (typeCounts[primary] || 0) + 1;
  }
  picked.sort((a, b) => b.adjustedScore - a.adjustedScore);

  return picked.slice(0, limit).map((s, i) => ({
    placeId: s.candidate.placeId,
    name: s.candidate.name,
    score: Number(s.adjustedScore.toFixed(4)),
    rank: i,
    reasons: s.reasons,
    breakdown: s.breakdown,
    exploration: false,
  }));
}

// ── Signal → tasteVector update ──────────────────────────────────────────────
function applySignalToVector(vector, types, tags, weight) {
  const keys = [...normalizeKeys(types), ...normalizeKeys(tags)];
  for (const k of keys) {
    vector[k] = (vector[k] || 0) + weight;
  }
  return vector;
}

// ── HTTPS Callable: recordTasteSignal ─────────────────────────────────────────
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
  const signalRef = userRef.collection("signals").doc();
  const affinityRef = db().collection("place_affinity").doc(placeId);

  await db().runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.exists ? userSnap.data() : {};
    const vector = { ...(userData.tasteVector || {}) };
    applySignalToVector(vector, safeTypes, safeTags, weight);

    // Track seen set (cap 200)
    const seen = Array.isArray(userData.soloPlanSeen) ? userData.soloPlanSeen : [];
    const newSeen = [placeId, ...seen.filter((p) => p !== placeId)].slice(0, 200);

    tx.set(userRef, {
      tasteVector: vector,
      tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      soloPlanSeen: newSeen,
      signalCount: admin.firestore.FieldValue.increment(1),
    }, { merge: true });

    tx.set(signalRef, {
      placeId, placeName: placeName || null,
      types: safeTypes, tags: safeTags,
      signalType, weight, source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Aggregate affinity (best-effort, skip on missing types)
    const affinityUpdate = {
      placeId,
      name: placeName || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (safeTypes.length) affinityUpdate.types = safeTypes;
    if (safeTags.length) affinityUpdate.tags = safeTags;
    const countField = `${signalType}Count`;
    affinityUpdate[countField] = admin.firestore.FieldValue.increment(1);

    const nationality = userData.nationalityCode || userData.nationality || null;
    if (nationality && typeof nationality === "string") {
      affinityUpdate[`byCountry.${nationality.slice(0, 3).toUpperCase()}`] =
        admin.firestore.FieldValue.increment(1);
    }
    tx.set(affinityRef, affinityUpdate, { merge: true });
  });

  return { status: "ok" };
});

// ── HTTPS Callable: recommendPlaces ───────────────────────────────────────────
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
  } = request.data || {};

  if (!Array.isArray(candidates) || candidates.length === 0) {
    throw new HttpsError("invalid-argument", "Candidates array required.");
  }
  if (candidates.length > 200) {
    throw new HttpsError("invalid-argument", "Too many candidates (max 200).");
  }

  const userSnap = await db().collection("users").doc(uid).get();
  const userData = userSnap.exists ? userSnap.data() : {};
  const tasteVector = userData.tasteVector || {};
  const signalCount = userData.signalCount || 0;
  const hasEnoughSignals = signalCount >= 5;
  const seenSet = excludeSeen && Array.isArray(userData.soloPlanSeen)
    ? new Set(userData.soloPlanSeen)
    : new Set();

  // Country prior (cold-start)
  let countryPrior = null;
  if (!hasEnoughSignals && userData.nationalityCode) {
    const priorSnap = await db()
      .collection("country_priors")
      .doc(String(userData.nationalityCode).slice(0, 3).toUpperCase())
      .get();
    if (priorSnap.exists) countryPrior = priorSnap.data().tasteVector || null;
  }

  // Neighbors: for recent seed places (last 10 positive signals), fetch neighbor map
  const neighbors = {};
  try {
    const seedSnap = await db()
      .collection("users").doc(uid).collection("signals")
      .where("weight", ">", 0)
      .orderBy("weight", "desc")
      .limit(10)
      .get();
    const seedIds = seedSnap.docs.map((d) => d.data().placeId).filter(Boolean);
    if (seedIds.length) {
      const neighborDocs = await Promise.all(
        seedIds.map((id) => db().collection("place_neighbors").doc(id).get())
      );
      for (const nd of neighborDocs) {
        if (!nd.exists) continue;
        const list = nd.data().neighbors || [];
        for (const n of list) {
          neighbors[n.placeId] = Math.max(neighbors[n.placeId] || 0, n.similarity || 0);
        }
      }
    }
  } catch (e) {
    // Non-fatal — collab just contributes 0
    console.warn("Neighbor lookup failed:", e.message);
  }

  const recommendations = rankCandidates({
    candidates, tasteVector, userLat, userLng, context,
    neighbors, countryPrior, hasEnoughSignals, seenSet, limit,
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

// ── HTTPS Callable: warmStartTasteVector ──────────────────────────────────────
// Call once per user (typically after quiz) to bootstrap from existing
// Firestore signals: savedPlaces, bookings, community posts with locationId.
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

  const vector = { ...(userData.tasteVector || {}) };
  let derived = 0;

  // savedPlaces → save signal per place (lookup types from places collection if present)
  const savedPlaces = Array.isArray(userData.savedPlaces) ? userData.savedPlaces : [];
  for (const placeId of savedPlaces.slice(0, 50)) {
    const pSnap = await db().collection("places").doc(String(placeId)).get();
    if (!pSnap.exists) continue;
    const p = pSnap.data();
    applySignalToVector(vector, [p.category], p.tags || [], SIGNAL_WEIGHTS.save);
    derived++;
  }

  // bookings → booking signal per destination landmark tag set
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

  // Community posts with locationId → post signal
  const postsSnap = await db()
    .collection("community_posts")
    .where("userId", "==", uid)
    .limit(20)
    .get();
  for (const post of postsSnap.docs) {
    const locId = post.data().locationId;
    if (!locId) continue;
    const pSnap = await db().collection("places").doc(String(locId)).get();
    if (!pSnap.exists) continue;
    const p = pSnap.data();
    applySignalToVector(vector, [p.category], p.tags || [], SIGNAL_WEIGHTS.post);
    derived++;
  }

  await userRef.set({
    tasteVector: vector,
    tasteVectorUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    signalCount: admin.firestore.FieldValue.increment(derived),
    warmStartedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return { status: "ok", signalsDerived: derived, vectorSize: Object.keys(vector).length };
});

// ── HTTPS Callable: applyQuizAnswers ──────────────────────────────────────────
// Frontend sends { answers: [{ optionId, types, tags }] } matching quiz_schema.json.
// We bundle them into a single batched signal update and mark quiz complete.
exports.applyQuizAnswers = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const uid = request.auth.uid;
  const { answers } = request.data || {};
  if (!Array.isArray(answers) || answers.length === 0 || answers.length > 20) {
    throw new HttpsError("invalid-argument", "answers must be 1–20 items.");
  }

  const userRef = db().collection("users").doc(uid);
  const vector = {};
  let picks = 0;
  for (const a of answers) {
    const types = normalizeKeys(a.types || []);
    const tags = normalizeKeys(a.tags || []);
    if (!types.length && !tags.length) continue;
    applySignalToVector(vector, types, tags, SIGNAL_WEIGHTS.quiz);
    picks++;
  }
  if (picks === 0) {
    throw new HttpsError("invalid-argument", "No valid answers.");
  }

  // Merge vector into existing tasteVector atomically
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

// ── Scheduled: nightly taste vector decay ─────────────────────────────────────
exports.decayTasteVectors = onSchedule(
  { schedule: "0 3 * * *", timeZone: "UTC" },
  async () => {
    const snapshot = await db().collection("users")
      .where("signalCount", ">", 0)
      .get();
    const decayFactor = 0.98;
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

// ── Scheduled: nightly neighbor rebuild (item-item collab) ───────────────────
exports.rebuildPlaceNeighbors = onSchedule(
  { schedule: "0 4 * * *", timeZone: "UTC" },
  async () => {
    const sinceMs = Date.now() - 90 * 24 * 60 * 60 * 1000;
    const since = admin.firestore.Timestamp.fromMillis(sinceMs);

    // userPlaces[uid] = Set(placeId) from positive signals
    const userPlaces = new Map();
    const usersSnap = await db().collection("users").where("signalCount", ">", 0).get();
    for (const u of usersSnap.docs) {
      const sigs = await u.ref.collection("signals")
        .where("createdAt", ">=", since)
        .where("weight", ">", 0)
        .get();
      const set = new Set(sigs.docs.map((d) => d.data().placeId).filter(Boolean));
      if (set.size > 0) userPlaces.set(u.id, set);
    }

    // Build place→users inverted index
    const placeUsers = new Map(); // placeId -> Set(uid)
    for (const [uid, set] of userPlaces) {
      for (const pid of set) {
        if (!placeUsers.has(pid)) placeUsers.set(pid, new Set());
        placeUsers.get(pid).add(uid);
      }
    }

    // For each pair (A, B) with enough co-occurrence, compute Jaccard
    const neighborsByPlace = new Map(); // placeId -> [{placeId, similarity}]
    const placeIds = [...placeUsers.keys()];
    for (let i = 0; i < placeIds.length; i++) {
      const a = placeIds[i];
      const usersA = placeUsers.get(a);
      if (usersA.size < 3) continue;
      for (let j = i + 1; j < placeIds.length; j++) {
        const b = placeIds[j];
        const usersB = placeUsers.get(b);
        if (usersB.size < 3) continue;
        let intersection = 0;
        for (const u of usersA) if (usersB.has(u)) intersection++;
        if (intersection < 2) continue;
        const union = usersA.size + usersB.size - intersection;
        const sim = intersection / union;
        if (sim < 0.05) continue;
        if (!neighborsByPlace.has(a)) neighborsByPlace.set(a, []);
        if (!neighborsByPlace.has(b)) neighborsByPlace.set(b, []);
        neighborsByPlace.get(a).push({ placeId: b, similarity: sim });
        neighborsByPlace.get(b).push({ placeId: a, similarity: sim });
      }
    }

    let batch = db().batch();
    let ops = 0;
    for (const [pid, list] of neighborsByPlace) {
      list.sort((x, y) => y.similarity - x.similarity);
      const top = list.slice(0, 20);
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

// ── Scheduled: weekly country priors ──────────────────────────────────────────
exports.rebuildCountryPriors = onSchedule(
  { schedule: "0 2 * * 0", timeZone: "UTC" },
  async () => {
    const byCountry = new Map(); // code -> { sum: Map, count }
    const usersSnap = await db().collection("users")
      .where("signalCount", ">", 0)
      .get();
    for (const u of usersSnap.docs) {
      const d = u.data();
      const code = (d.nationalityCode || "").slice(0, 3).toUpperCase();
      if (!code) continue;
      const v = d.tasteVector || {};
      if (!byCountry.has(code)) byCountry.set(code, { sum: {}, count: 0 });
      const bucket = byCountry.get(code);
      for (const k of Object.keys(v)) bucket.sum[k] = (bucket.sum[k] || 0) + v[k];
      bucket.count++;
    }

    let batch = db().batch();
    let ops = 0;
    for (const [code, { sum, count }] of byCountry) {
      if (count < 3) continue; // need minimum sample size
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

// ── Exports for local testing (sample script) ────────────────────────────────
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
