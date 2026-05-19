#!/usr/bin/env node
/**
 * metrics.test.js
 * ───────────────
 * Sanity tests for metrics.js. Not a full test suite — just the invariants
 * that catch the most common implementation bugs (off-by-one indexing, IDCG
 * normalisation, empty-input edge cases, perfect-ranking outputs).
 *
 * Run:  node scripts/eval/metrics.test.js
 * Exit code 0 = all pass, 1 = one or more failures.
 */

const m = require("./metrics");

let failed = 0;
let passed = 0;

function approx(a, b, eps = 1e-9) {
  return Math.abs(a - b) <= eps;
}

function check(name, actual, expected) {
  const ok = typeof expected === "number" ? approx(actual, expected) : actual === expected;
  if (ok) {
    passed++;
    console.log(`  ✓ ${name}`);
  } else {
    failed++;
    console.log(`  ✗ ${name}  →  got ${actual}, expected ${expected}`);
  }
}

console.log("\n── precisionAtK / recallAtK / f1AtK ───────────────────────");
{
  const ranked = [{ placeId: "a" }, { placeId: "b" }, { placeId: "c" }, { placeId: "d" }, { placeId: "e" }];
  const relevant = new Set(["a", "b", "c"]); // 3 relevant total

  check("P@3 of perfect ranking = 1.0", m.precisionAtK(ranked, relevant, 3), 1.0);
  check("R@3 of perfect ranking = 1.0", m.recallAtK(ranked, relevant, 3), 1.0);
  check("F1@3 of perfect ranking = 1.0", m.f1AtK(ranked, relevant, 3), 1.0);
  check("P@5 of perfect ranking = 0.6 (3/5)", m.precisionAtK(ranked, relevant, 5), 0.6);
  check("R@5 of perfect ranking = 1.0", m.recallAtK(ranked, relevant, 5), 1.0);
  check("P@k=0 = 0", m.precisionAtK(ranked, relevant, 0), 0);
  check("R@k with empty relevantSet = 0", m.recallAtK(ranked, new Set(), 3), 0);

  const reversed = [{ placeId: "e" }, { placeId: "d" }, { placeId: "c" }, { placeId: "b" }, { placeId: "a" }];
  check("P@3 of worst ranking = 1/3", m.precisionAtK(reversed, relevant, 3), 1 / 3);
  check("F1@3 of worst ranking < F1@3 of best", m.f1AtK(reversed, relevant, 3) < m.f1AtK(ranked, relevant, 3), true);
}

console.log("\n── hitRateAtK / reciprocalRank ────────────────────────────");
{
  const ranked = [{ placeId: "x" }, { placeId: "y" }, { placeId: "a" }];
  const relevant = new Set(["a"]);
  check("HR@1 (relevant at rank 2) = 0", m.hitRateAtK(ranked, relevant, 1), 0);
  check("HR@2 (relevant at rank 2) = 0", m.hitRateAtK(ranked, relevant, 2), 0);
  check("HR@3 (relevant at rank 2) = 1", m.hitRateAtK(ranked, relevant, 3), 1);
  check("MRR (relevant at rank 3) = 1/3", m.reciprocalRank(ranked, relevant), 1 / 3);
  check("MRR with no relevant = 0", m.reciprocalRank(ranked, new Set()), 0);
}

console.log("\n── averagePrecision (MAP per query) ───────────────────────");
{
  // Two relevant in top-5 at positions 1 and 3:
  // P@1 = 1/1 = 1.0, P@3 = 2/3 ≈ 0.667.  AP = (1.0 + 0.667) / 2 = 0.833
  const ranked = [
    { placeId: "r1" }, { placeId: "x" }, { placeId: "r2" },
    { placeId: "y" }, { placeId: "z" },
  ];
  const relevant = new Set(["r1", "r2"]);
  const ap = m.averagePrecision(ranked, relevant);
  check("AP with relevants at ranks 1,3 = 0.833", approx(ap, (1.0 + 2 / 3) / 2), true);

  // Perfect ranking
  const perfect = [
    { placeId: "a" }, { placeId: "b" }, { placeId: "c" },
  ];
  const allRelevant = new Set(["a", "b", "c"]);
  check("AP of perfect ranking = 1.0", m.averagePrecision(perfect, allRelevant), 1.0);
}

console.log("\n── ndcgAtK ─────────────────────────────────────────────────");
{
  // Identity ordering (already sorted by ground-truth relevance) → NDCG = 1.0
  const ranked = [
    { placeId: "a" }, { placeId: "b" }, { placeId: "c" }, { placeId: "d" },
  ];
  const rel = { a: 3, b: 2, c: 1, d: 0 };
  check("NDCG@4 of identity ordering = 1.0", m.ndcgAtK(ranked, rel, 4), 1.0);

  // Reversed → NDCG < 1
  const reversed = [...ranked].reverse();
  check("NDCG@4 of reversed ordering < 1", m.ndcgAtK(reversed, rel, 4) < 1, true);
  check("NDCG@4 of reversed ordering > 0", m.ndcgAtK(reversed, rel, 4) > 0, true);
}

console.log("\n── spearmanRho ─────────────────────────────────────────────");
{
  const ranked = [
    { placeId: "a" }, { placeId: "b" }, { placeId: "c" }, { placeId: "d" },
  ];
  // Identity ordering matches ground truth → ρ = 1
  const relAligned = { a: 4, b: 3, c: 2, d: 1 };
  check("Spearman ρ of identity = 1.0", m.spearmanRho(ranked, relAligned), 1.0);

  // Perfectly reversed → ρ = -1
  const relReversed = { a: 1, b: 2, c: 3, d: 4 };
  check("Spearman ρ of reversed = -1.0", m.spearmanRho(ranked, relReversed), -1.0);
}

console.log("\n── intraListDiversity ─────────────────────────────────────");
{
  const candidateLookup = {
    a: { types: ["museum"], tags: ["cultural"] },
    b: { types: ["museum"], tags: ["cultural"] },        // identical to a → 0 diversity
    c: { types: ["beach"], tags: ["natural"] },         // entirely different → 1 diversity
  };
  const ranked = [{ placeId: "a" }, { placeId: "b" }];
  check("ILD of identical pair = 0", m.intraListDiversity(ranked, candidateLookup, 2), 0);

  const mixed = [{ placeId: "a" }, { placeId: "c" }];
  check("ILD of disjoint pair = 1", m.intraListDiversity(mixed, candidateLookup, 2), 1);
}

console.log("\n── novelty ─────────────────────────────────────────────────");
{
  const popularityRank = { a: 1, b: 2, c: 3, d: 4 }; // 4 items, log2(4) = 2
  const topMostPopular = [{ placeId: "a" }];
  check("Novelty of #1-rank item = 0", m.novelty(topMostPopular, popularityRank, 1), 0);
  const topLeastPopular = [{ placeId: "d" }];
  check("Novelty of #N-rank item = 1.0", m.novelty(topLeastPopular, popularityRank, 1), 1.0);
}

console.log("\n── catalogCoverage ─────────────────────────────────────────");
{
  const ranking1 = [{ placeId: "a" }, { placeId: "b" }];
  const ranking2 = [{ placeId: "c" }, { placeId: "d" }];
  check("Coverage with all distinct (4 of 4) = 1.0", m.catalogCoverage([ranking1, ranking2], 4, 2), 1.0);
  check("Coverage with all distinct (4 of 8) = 0.5", m.catalogCoverage([ranking1, ranking2], 8, 2), 0.5);

  const overlap1 = [{ placeId: "a" }];
  const overlap2 = [{ placeId: "a" }];
  check("Coverage with full overlap = 1/N", m.catalogCoverage([overlap1, overlap2], 4, 1), 0.25);
}

console.log("\n── scoreGap / scoreStats ──────────────────────────────────");
{
  const ranked = [{ score: 1.0 }, { score: 0.8 }, { score: 0.5 }, { score: 0.2 }, { score: 0.0 }];
  check("Score gap = top - median", m.scoreGap(ranked), 0.5);
  const stats = m.scoreStats(ranked);
  check("scoreStats.max = 1.0", stats.max, 1.0);
  check("scoreStats.min = 0.0", stats.min, 0.0);
  check("scoreStats.mean = 0.5", stats.mean, 0.5);
}

console.log("\n── jaccard ─────────────────────────────────────────────────");
{
  check("Jaccard(A,A) = 1", m.jaccard(["x", "y"], ["x", "y"]), 1);
  check("Jaccard(A,∅) = 0", m.jaccard(["x"], []), 0);
  check("Jaccard([a,b], [b,c]) = 1/3", m.jaccard(["a", "b"], ["b", "c"]), 1 / 3);
}

console.log("\n══════════════════════════════════════════════════════════");
console.log(`Total: ${passed + failed}   passed: ${passed}   failed: ${failed}`);
process.exit(failed === 0 ? 0 : 1);
