#!/usr/bin/env node
/**
 * evaluate_accuracy_v2.js
 * ───────────────────────
 * Phase-13 evaluation harness for the recommendation engine.
 *
 *   • ~30 personas across all five contexts (solo / nearby / similar / home / tours)
 *   • ~80-candidate hand-curated Egyptian-place fixture
 *   • Auto-labelled relevance via type-overlap (structurally independent of
 *     the production scorer's tanh-normalised mean-vector formula)
 *   • Full ranking-system metric suite: P@k, R@k, F1@k, HR@k, MRR, MAP,
 *     NDCG@5/10, Spearman ρ, score gap, ILD, novelty, catalog coverage
 *   • Side-by-side comparison against 4 baselines (random, popularity,
 *     rating-only, taste-only) so the lift from hybrid scoring is visible
 *   • Per-context breakdown — each context's weight profile is evaluated
 *     against the personas that actually live in that surface
 *   • Console table for inspection + Markdown table for Chapter III paste-in
 *   • Optional JSON dump via --json=path
 *
 * Run:
 *   cd functions
 *   node scripts/evaluate_accuracy_v2.js
 *   node scripts/evaluate_accuracy_v2.js --json=out.json
 *   node scripts/evaluate_accuracy_v2.js --markdown=report.md
 */

const fs = require("fs");
const path = require("path");

const { BASELINES } = require("./eval/baselines");
const { PERSONAS, buildRelevanceMap } = require("./eval/personas_v2");
const { loadFromFile } = require("./eval/sample_candidates");
const m = require("./eval/metrics");

// ─── Argument parsing ──────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2)
    .filter((a) => a.startsWith("--"))
    .map((a) => {
      const [k, v] = a.replace(/^--/, "").split("=");
      return [k, v == null ? true : v];
    }),
);

// ─── Setup ─────────────────────────────────────────────────────────────────
const CANDIDATES = loadFromFile();
const POPULARITY_RANK = m.buildPopularityRank(CANDIDATES);
const CANDIDATE_LOOKUP = Object.fromEntries(CANDIDATES.map((c) => [c.placeId, c]));

const RANKER_NAMES = ["random", "popularity", "rating", "tasteOnly", "hybrid"];
const RANKER_LABELS = {
  random: "Random",
  popularity: "Popularity",
  rating: "Rating-only",
  tasteOnly: "Taste-only",
  hybrid: "Hybrid (production)",
};

// ─── Per-persona evaluation ────────────────────────────────────────────────
function evaluatePersonaWithRanker(persona, ranker, candidates) {
  const ranked = ranker(candidates, persona);
  const relMap = buildRelevanceMap(persona, candidates);
  const relevantSet = m.buildRelevantSet(relMap);
  const numRelevant = relevantSet.size;

  return {
    ranked,
    relMap,
    numRelevant,
    metrics: {
      "P@3":    m.precisionAtK(ranked, relevantSet, 3),
      "P@5":    m.precisionAtK(ranked, relevantSet, 5),
      "R@5":    m.recallAtK(ranked, relevantSet, 5),
      "F1@5":   m.f1AtK(ranked, relevantSet, 5),
      "HR@5":   m.hitRateAtK(ranked, relevantSet, 5),
      "MRR":    m.reciprocalRank(ranked, relevantSet),
      "MAP":    m.averagePrecision(ranked, relevantSet, 10),
      "NDCG@5": m.ndcgAtK(ranked, relMap, 5),
      "NDCG@10":m.ndcgAtK(ranked, relMap, 10),
      "Spearman": m.spearmanRho(ranked, relMap),
      "ScoreGap": m.scoreGap(ranked),
      "ILD@5":  m.intraListDiversity(ranked, CANDIDATE_LOOKUP, 5),
      "Novelty@5": m.novelty(ranked, POPULARITY_RANK, 5),
    },
  };
}

// ─── Aggregation ───────────────────────────────────────────────────────────
function avgMetrics(perPersonaResults) {
  if (perPersonaResults.length === 0) return {};
  const keys = Object.keys(perPersonaResults[0].metrics);
  const out = {};
  for (const k of keys) {
    out[k] = perPersonaResults.reduce((s, r) => s + r.metrics[k], 0) / perPersonaResults.length;
  }
  return out;
}

function evaluateAll() {
  // Index personas by context for the per-context breakdown
  const contexts = ["solo", "nearby", "similar", "home", "tours"];
  const personasByContext = {};
  for (const ctx of contexts) {
    personasByContext[ctx] = PERSONAS.filter((p) => p.context === ctx);
  }

  // results[rankerName][contextOr"all"] = { metrics: {…}, personaCount: N, rankings: […] }
  const results = {};
  for (const name of RANKER_NAMES) results[name] = {};

  // Per-context evaluation
  for (const ctx of contexts) {
    const perCtxPersonas = personasByContext[ctx];
    if (perCtxPersonas.length === 0) continue;

    for (const name of RANKER_NAMES) {
      const ranker = BASELINES[name];
      const perPersona = perCtxPersonas.map((p) => evaluatePersonaWithRanker(p, ranker, CANDIDATES));
      results[name][ctx] = {
        metrics: avgMetrics(perPersona),
        personaCount: perCtxPersonas.length,
        rankings: perPersona.map((r) => r.ranked),
      };
    }
  }

  // Overall (all personas)
  for (const name of RANKER_NAMES) {
    const ranker = BASELINES[name];
    const perPersona = PERSONAS.map((p) => evaluatePersonaWithRanker(p, ranker, CANDIDATES));
    results[name].all = {
      metrics: avgMetrics(perPersona),
      personaCount: PERSONAS.length,
      rankings: perPersona.map((r) => r.ranked),
      coverage10: m.catalogCoverage(perPersona.map((r) => r.ranked), CANDIDATES.length, 10),
    };
  }

  return { results, contexts, personasByContext };
}

// ─── Output: console ───────────────────────────────────────────────────────
function printHeader() {
  console.log("");
  console.log("═══════════════════════════════════════════════════════════════════════");
  console.log("   Lost in Egypt — Recommendation Engine Evaluation (v2 / Phase 13)");
  console.log("═══════════════════════════════════════════════════════════════════════");
  console.log(`   ${PERSONAS.length} personas   |   ${CANDIDATES.length} candidates   |   5 contexts   |   5 rankers`);
  console.log("");
}

function fmt(x, digits = 3) {
  if (typeof x !== "number" || Number.isNaN(x)) return "  —  ";
  return x.toFixed(digits).padStart(6);
}

function printOverallTable(results) {
  console.log("─── OVERALL (all personas, all contexts averaged) ──────────────────────");
  const headers = ["Ranker", "P@5", "R@5", "F1@5", "HR@5", "MRR", "MAP", "NDCG@5", "NDCG@10", "Spear", "ILD@5", "Nov@5"];
  console.log(headers.map((h, i) => i === 0 ? h.padEnd(20) : h.padStart(7)).join("  "));
  console.log("─".repeat(120));
  for (const name of RANKER_NAMES) {
    const r = results[name].all.metrics;
    const row = [
      RANKER_LABELS[name].padEnd(20),
      fmt(r["P@5"]),
      fmt(r["R@5"]),
      fmt(r["F1@5"]),
      fmt(r["HR@5"]),
      fmt(r["MRR"]),
      fmt(r["MAP"]),
      fmt(r["NDCG@5"]),
      fmt(r["NDCG@10"]),
      fmt(r["Spearman"]),
      fmt(r["ILD@5"]),
      fmt(r["Novelty@5"]),
    ];
    console.log(row.join("  "));
  }
  console.log("");
}

function printContextTable(results, contexts) {
  console.log("─── NDCG@5 by context (the headline thesis metric, per surface) ────────");
  const header = ["Context".padEnd(12), ...RANKER_NAMES.map((n) => RANKER_LABELS[n].padStart(20))];
  console.log(header.join("  "));
  console.log("─".repeat(120));
  for (const ctx of contexts) {
    const row = [ctx.padEnd(12)];
    for (const name of RANKER_NAMES) {
      const v = results[name][ctx]?.metrics["NDCG@5"];
      row.push((v != null ? v.toFixed(3) : "—").padStart(20));
    }
    console.log(row.join("  "));
  }
  console.log("");
}

function printLiftTable(results) {
  console.log("─── Hybrid lift vs each baseline (NDCG@5, all personas) ────────────────");
  const hybrid = results.hybrid.all.metrics["NDCG@5"];
  for (const baseline of ["random", "popularity", "rating", "tasteOnly"]) {
    const base = results[baseline].all.metrics["NDCG@5"];
    const abs = hybrid - base;
    const rel = base > 0 ? (abs / base) * 100 : 0;
    console.log(`   vs ${RANKER_LABELS[baseline].padEnd(20)}  ` +
      `Δ NDCG@5 = ${abs >= 0 ? "+" : ""}${abs.toFixed(3)}` +
      `   (${rel >= 0 ? "+" : ""}${rel.toFixed(1)}% relative)`);
  }
  console.log("");
}

function printCoverage(results) {
  console.log("─── List health (all personas, top-10) ─────────────────────────────────");
  for (const name of RANKER_NAMES) {
    const cov = results[name].all.coverage10;
    const ild = results[name].all.metrics["ILD@5"];
    const nov = results[name].all.metrics["Novelty@5"];
    console.log(`   ${RANKER_LABELS[name].padEnd(20)}  ` +
      `coverage@10=${cov.toFixed(3)}   ILD@5=${ild.toFixed(3)}   Novelty@5=${nov.toFixed(3)}`);
  }
  console.log("");
}

// ─── Output: Markdown for Chapter III paste-in ─────────────────────────────
function generateMarkdown(results, contexts) {
  const lines = [];
  lines.push("## Recommendation Engine Evaluation (Phase 13)");
  lines.push("");
  lines.push(`Evaluated **${PERSONAS.length} personas** across **${CANDIDATES.length} candidate places** and **5 contexts** (\`solo\`, \`nearby\`, \`similar\`, \`home\`, \`tours\`). Ground-truth relevance is auto-labelled by canonical-key overlap — a formula structurally distinct from the production tanh-normalised mean-vector scorer.`);
  lines.push("");
  lines.push("### Headline metrics (averaged across all personas)");
  lines.push("");
  lines.push("| Ranker | P@5 | R@5 | F1@5 | HR@5 | MRR | MAP | NDCG@5 | NDCG@10 | Spearman ρ | ILD@5 | Novelty@5 |");
  lines.push("|---|---|---|---|---|---|---|---|---|---|---|---|");
  for (const name of RANKER_NAMES) {
    const r = results[name].all.metrics;
    lines.push(`| ${RANKER_LABELS[name]} | ${r["P@5"].toFixed(3)} | ${r["R@5"].toFixed(3)} | ${r["F1@5"].toFixed(3)} | ${r["HR@5"].toFixed(3)} | ${r["MRR"].toFixed(3)} | ${r["MAP"].toFixed(3)} | **${r["NDCG@5"].toFixed(3)}** | ${r["NDCG@10"].toFixed(3)} | ${r["Spearman"].toFixed(3)} | ${r["ILD@5"].toFixed(3)} | ${r["Novelty@5"].toFixed(3)} |`);
  }
  lines.push("");

  lines.push("### Hybrid lift over baselines (NDCG@5)");
  lines.push("");
  lines.push("| Baseline | Baseline NDCG@5 | Hybrid NDCG@5 | Absolute Δ | Relative lift |");
  lines.push("|---|---|---|---|---|");
  const hybrid = results.hybrid.all.metrics["NDCG@5"];
  for (const baseline of ["random", "popularity", "rating", "tasteOnly"]) {
    const base = results[baseline].all.metrics["NDCG@5"];
    const abs = hybrid - base;
    const rel = base > 0 ? (abs / base) * 100 : 0;
    lines.push(`| ${RANKER_LABELS[baseline]} | ${base.toFixed(3)} | ${hybrid.toFixed(3)} | ${abs >= 0 ? "+" : ""}${abs.toFixed(3)} | ${rel >= 0 ? "+" : ""}${rel.toFixed(1)}% |`);
  }
  lines.push("");

  lines.push("### Per-context NDCG@5");
  lines.push("");
  lines.push("| Context | Personas | Random | Popularity | Rating-only | Taste-only | Hybrid |");
  lines.push("|---|---|---|---|---|---|---|");
  for (const ctx of contexts) {
    const row = [ctx, results.hybrid[ctx]?.personaCount || 0];
    for (const name of RANKER_NAMES) {
      const v = results[name][ctx]?.metrics["NDCG@5"];
      row.push(v != null ? v.toFixed(3) : "—");
    }
    lines.push(`| ${row.join(" | ")} |`);
  }
  lines.push("");

  lines.push("### List-health metrics (top-10)");
  lines.push("");
  lines.push("| Ranker | Catalog coverage | ILD@5 | Novelty@5 |");
  lines.push("|---|---|---|---|");
  for (const name of RANKER_NAMES) {
    const a = results[name].all;
    lines.push(`| ${RANKER_LABELS[name]} | ${a.coverage10.toFixed(3)} | ${a.metrics["ILD@5"].toFixed(3)} | ${a.metrics["Novelty@5"].toFixed(3)} |`);
  }
  lines.push("");

  lines.push("### Methodology notes");
  lines.push("");
  lines.push("- **Ground-truth relevance** is computed independently of the scoring formula: per persona, a candidate is graded 0–3 by canonical-key set-intersection with the persona's `loves`/`dislikes`. The scorer uses a tanh-normalised mean over the taste vector; the two formulas share no math, so engine performance against this label set reflects real lift rather than formula self-consistency.");
  lines.push("- For `nearby` and `home` contexts, ground-truth relevance is distance-capped (>200 km → grade ≤ 1; >500 km → 0) so a Cairo-resident's home feed isn't \"correct\" when it surfaces Aswan.");
  lines.push("- `random` baseline uses a seeded LCG (Mulberry32, seed 42) for reproducibility.");
  lines.push("- Hybrid ranker runs with `epsilon = 0` (ε-greedy exploration disabled) to keep evaluation deterministic.");
  lines.push("- The existing `evaluate_accuracy.js` script remains in place as a v1 regression continuity check on the original 5-persona / 10-place suite (currently 19/20 = 95.0% assertion pass-rate, against the original design-intent target of 90%).");

  return lines.join("\n");
}

// ─── Main ──────────────────────────────────────────────────────────────────
printHeader();
const { results, contexts } = evaluateAll();

printOverallTable(results);
printContextTable(results, contexts);
printLiftTable(results);
printCoverage(results);

if (args.json) {
  const outPath = path.resolve(args.json);
  // Strip rankings (verbose) — keep metrics only
  const dump = {};
  for (const name of RANKER_NAMES) {
    dump[name] = {};
    for (const ctx of [...contexts, "all"]) {
      if (!results[name][ctx]) continue;
      dump[name][ctx] = {
        metrics: results[name][ctx].metrics,
        personaCount: results[name][ctx].personaCount,
        coverage10: results[name][ctx].coverage10,
      };
    }
  }
  fs.writeFileSync(outPath, JSON.stringify(dump, null, 2));
  console.log(`JSON dump → ${outPath}`);
}

if (args.markdown) {
  const outPath = path.resolve(args.markdown);
  fs.writeFileSync(outPath, generateMarkdown(results, contexts));
  console.log(`Markdown report → ${outPath}`);
}

console.log("─── Notes ──────────────────────────────────────────────────────────────");
console.log("• Run with --markdown=path/to/report.md to dump the thesis-grade markdown.");
console.log("• Run with --json=path/to/out.json for downstream analysis.");
console.log("• The legacy 5-persona 'evaluate_accuracy.js' is preserved as a regression check.");
console.log("");
