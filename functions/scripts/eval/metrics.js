/**
 * metrics.js
 * ──────────
 * Pure metric functions for ranking-system evaluation. No side effects, no
 * Firebase dependencies — every function takes plain JS values and returns a
 * number. Designed for unit testing.
 *
 * Inputs:
 *   ranked        — array of {placeId, ...} ordered by predicted score (rank 0 = top)
 *   relevanceMap  — {placeId: grade} where grade is in [0, 3]; missing = 0
 *   relevantSet   — Set<placeId> for binary metrics (typically: grade >= 2)
 *
 * Conventions:
 *   k is 1-based length (top-k means the first k items).
 *   When |ranked| < k we score over what's available rather than padding zeros.
 */

const RELEVANCE_THRESHOLD = 2; // grades >= 2 count as "relevant" for binary metrics

function buildRelevantSet(relevanceMap, threshold = RELEVANCE_THRESHOLD) {
  const s = new Set();
  for (const [id, grade] of Object.entries(relevanceMap)) {
    if (grade >= threshold) s.add(id);
  }
  return s;
}

function precisionAtK(ranked, relevantSet, k) {
  if (k <= 0 || ranked.length === 0) return 0;
  const top = ranked.slice(0, k);
  const hit = top.reduce((n, r) => n + (relevantSet.has(r.placeId) ? 1 : 0), 0);
  return hit / Math.min(k, ranked.length);
}

function recallAtK(ranked, relevantSet, k) {
  if (relevantSet.size === 0) return 0;
  const top = ranked.slice(0, k);
  const hit = top.reduce((n, r) => n + (relevantSet.has(r.placeId) ? 1 : 0), 0);
  return hit / relevantSet.size;
}

function f1AtK(ranked, relevantSet, k) {
  const p = precisionAtK(ranked, relevantSet, k);
  const r = recallAtK(ranked, relevantSet, k);
  if (p + r === 0) return 0;
  return (2 * p * r) / (p + r);
}

function hitRateAtK(ranked, relevantSet, k) {
  const top = ranked.slice(0, k);
  return top.some((r) => relevantSet.has(r.placeId)) ? 1 : 0;
}

function reciprocalRank(ranked, relevantSet) {
  for (let i = 0; i < ranked.length; i++) {
    if (relevantSet.has(ranked[i].placeId)) return 1 / (i + 1);
  }
  return 0;
}

function averagePrecision(ranked, relevantSet, k = Infinity) {
  if (relevantSet.size === 0) return 0;
  const limit = Math.min(k, ranked.length);
  let hits = 0;
  let sumPrecision = 0;
  for (let i = 0; i < limit; i++) {
    if (relevantSet.has(ranked[i].placeId)) {
      hits++;
      sumPrecision += hits / (i + 1);
    }
  }
  return sumPrecision / relevantSet.size;
}

function ndcgAtK(ranked, relevanceMap, k = 5) {
  const dcg = (grades) =>
    grades.slice(0, k).reduce(
      (s, g, i) => s + ((Math.pow(2, g) - 1) / Math.log2(i + 2)),
      0,
    );
  const actual = ranked.map((r) => relevanceMap[r.placeId] || 0);
  const ideal = Object.values(relevanceMap).sort((a, b) => b - a);
  const idcgVal = dcg(ideal);
  if (idcgVal === 0) return 0;
  return dcg(actual) / idcgVal;
}

function spearmanRho(ranked, relevanceMap) {
  if (ranked.length < 2) return 0;
  const n = ranked.length;
  const predictedRanks = ranked.map((_, i) => i + 1);
  const relGrades = ranked.map((r) => relevanceMap[r.placeId] || 0);

  const ideal = [...relGrades].sort((a, b) => b - a);
  const idealRanks = relGrades.map((g) => ideal.indexOf(g) + 1);

  let sumDiffSq = 0;
  for (let i = 0; i < n; i++) {
    const d = predictedRanks[i] - idealRanks[i];
    sumDiffSq += d * d;
  }
  return 1 - (6 * sumDiffSq) / (n * (n * n - 1));
}

function scoreGap(ranked) {
  if (ranked.length < 2) return 0;
  const top = ranked[0].score;
  const median = ranked[Math.floor(ranked.length / 2)].score;
  return top - median;
}

function scoreStats(ranked) {
  if (ranked.length === 0) return { mean: 0, stdev: 0, min: 0, max: 0 };
  const scores = ranked.map((r) => r.score);
  const mean = scores.reduce((a, b) => a + b, 0) / scores.length;
  const variance = scores.reduce((a, b) => a + (b - mean) ** 2, 0) / scores.length;
  return {
    mean,
    stdev: Math.sqrt(variance),
    min: Math.min(...scores),
    max: Math.max(...scores),
  };
}

function jaccard(a, b) {
  const setA = new Set(a);
  const setB = new Set(b);
  let inter = 0;
  for (const x of setA) if (setB.has(x)) inter++;
  const union = setA.size + setB.size - inter;
  return union === 0 ? 0 : inter / union;
}

/**
 * Intra-list diversity (ILD): average pairwise dissimilarity in top-k.
 * Dissimilarity = 1 - Jaccard(types ∪ tags). Higher = more diverse list.
 *
 * candidateLookup: {placeId: {types[], tags[]}} so we can pull types/tags
 * from the canonical pool rather than the ranked entries.
 */
function intraListDiversity(ranked, candidateLookup, k = 5) {
  const top = ranked.slice(0, k);
  if (top.length < 2) return 0;
  let sum = 0;
  let pairs = 0;
  for (let i = 0; i < top.length; i++) {
    for (let j = i + 1; j < top.length; j++) {
      const a = candidateLookup[top[i].placeId];
      const b = candidateLookup[top[j].placeId];
      if (!a || !b) continue;
      const keysA = [...(a.types || []), ...(a.tags || [])];
      const keysB = [...(b.types || []), ...(b.tags || [])];
      sum += 1 - jaccard(keysA, keysB);
      pairs++;
    }
  }
  return pairs === 0 ? 0 : sum / pairs;
}

/**
 * Novelty: how "long-tail" the recommendations are.
 * Computed against a popularity rank across the candidate pool.
 *
 * popularityRank: {placeId: rank in [1, N]} where 1 = most popular.
 * For each recommended item, contribution = log2(rank). More popular items
 * (rank=1) contribute 0; the rarest item contributes log2(N).
 * Final score is averaged over top-k items and divided by log2(N) so it
 * stays in [0, 1] — higher = more novel.
 */
function novelty(ranked, popularityRank, k = 5) {
  const top = ranked.slice(0, k);
  if (top.length === 0) return 0;
  const N = Object.keys(popularityRank).length;
  if (N <= 1) return 0;
  const maxNovelty = Math.log2(N);
  let sum = 0;
  let counted = 0;
  for (const r of top) {
    const rank = popularityRank[r.placeId];
    if (typeof rank !== "number") continue;
    sum += Math.log2(rank);
    counted++;
  }
  return counted === 0 ? 0 : (sum / counted) / maxNovelty;
}

/**
 * Catalog coverage: across N personas, what fraction of the total candidate
 * pool is recommended in at least one persona's top-k.
 *
 * rankings: Array<Array<{placeId}>> — one ranked list per persona.
 * Returns a value in [0, 1].
 */
function catalogCoverage(rankings, totalCandidates, k = 10) {
  const seen = new Set();
  for (const ranked of rankings) {
    for (const r of ranked.slice(0, k)) {
      seen.add(r.placeId);
    }
  }
  if (totalCandidates === 0) return 0;
  return seen.size / totalCandidates;
}

/**
 * Build a popularity rank map (1 = most popular by userRatingCount).
 */
function buildPopularityRank(candidates) {
  const sorted = [...candidates].sort(
    (a, b) => (b.userRatingCount || 0) - (a.userRatingCount || 0),
  );
  const rank = {};
  sorted.forEach((c, i) => { rank[c.placeId] = i + 1; });
  return rank;
}

module.exports = {
  RELEVANCE_THRESHOLD,
  buildRelevantSet,
  precisionAtK,
  recallAtK,
  f1AtK,
  hitRateAtK,
  reciprocalRank,
  averagePrecision,
  ndcgAtK,
  spearmanRho,
  scoreGap,
  scoreStats,
  jaccard,
  intraListDiversity,
  novelty,
  catalogCoverage,
  buildPopularityRank,
};
