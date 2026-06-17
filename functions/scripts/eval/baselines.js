/**
 * baselines.js
 * ────────────
 * Reference ranking strategies used to demonstrate lift of the hybrid model.
 *
 *   random       — shuffle deterministically with a seeded LCG
 *   popularity   — rating × log10(1 + userRatingCount)
 *   rating       — raw star rating
 *   tasteOnly    — re-uses scoreCandidate's tasteMatch component (all other
 *                  weights zeroed out). This isolates the contribution of the
 *                  taste vector independent of geography, ratings, and collab.
 *   hybrid       — production rankCandidates(), epsilon=0 to keep it deterministic
 *
 * Each ranker has the same signature:
 *   rank(candidates, persona) -> Array<{placeId, name, score}>
 *
 * Persona shape (subset relevant to ranking):
 *   { tasteVector, userLat, userLng, context, countryPrior, hasEnoughSignals }
 */

const {
  rankCandidates,
  scoreCandidate,
} = require("../../recommendation")._internal;

// Mulberry32 — small, fast, well-behaved seeded PRNG. Plenty good for shuffles.
function seededRng(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function randomRanker(seed = 42) {
  return function (candidates /* , persona */) {
    const rng = seededRng(seed);
    const shuffled = [...candidates].sort(() => rng() - 0.5);
    return shuffled.map((c, i) => ({
      placeId: c.placeId,
      name: c.name,
      score: 1 - i / shuffled.length, // monotonically decreasing so score-gap is non-zero
    }));
  };
}

function popularityRanker() {
  return function (candidates /* , persona */) {
    const scored = candidates.map((c) => ({
      placeId: c.placeId,
      name: c.name,
      score: (c.rating || 0) * Math.log10(1 + (c.userRatingCount || 0)),
    }));
    scored.sort((a, b) => b.score - a.score);
    return scored;
  };
}

function ratingRanker() {
  return function (candidates /* , persona */) {
    const scored = candidates.map((c) => ({
      placeId: c.placeId,
      name: c.name,
      score: c.rating || 0,
    }));
    scored.sort((a, b) => b.score - a.score);
    return scored;
  };
}

function tasteOnlyRanker() {
  return function (candidates, persona) {
    // Re-use scoreCandidate to get breakdown.tasteMatch, then rank on that
    // value alone. This gives the same canonical key normalisation and tanh
    // shaping as the hybrid scorer but isolates the taste component.
    const scored = candidates.map((c) => {
      const r = scoreCandidate({
        candidate: c,
        tasteVector: persona.tasteVector || {},
        userLat: persona.userLat,
        userLng: persona.userLng,
        context: persona.context,
        neighbors: {},
        countryPrior: null,
        hasEnoughSignals: persona.hasEnoughSignals,
      });
      return {
        placeId: c.placeId,
        name: c.name,
        score: r.breakdown.tasteMatch,
      };
    });
    scored.sort((a, b) => b.score - a.score);
    return scored;
  };
}

function hybridRanker() {
  return function (candidates, persona) {
    return rankCandidates({
      candidates,
      tasteVector: persona.tasteVector || {},
      userLat: persona.userLat,
      userLng: persona.userLng,
      context: persona.context,
      neighbors: {},
      countryPrior: persona.countryPrior || null,
      hasEnoughSignals: persona.hasEnoughSignals,
      seenSet: new Set(),
      limit: candidates.length,
      epsilon: 0, // deterministic
    });
  };
}

const BASELINES = {
  random: randomRanker(42),
  popularity: popularityRanker(),
  rating: ratingRanker(),
  tasteOnly: tasteOnlyRanker(),
  hybrid: hybridRanker(),
};

module.exports = {
  BASELINES,
  seededRng,
  randomRanker,
  popularityRanker,
  ratingRanker,
  tasteOnlyRanker,
  hybridRanker,
};
