## Recommendation Engine Evaluation (Phase 13)

Evaluated **34 personas** across **83 candidate places** and **5 contexts** (`solo`, `nearby`, `similar`, `home`, `tours`). Ground-truth relevance is auto-labelled by canonical-key overlap — a formula structurally distinct from the production tanh-normalised mean-vector scorer.

### Headline metrics (averaged across all personas)

| Ranker | P@5 | R@5 | F1@5 | HR@5 | MRR | MAP | NDCG@5 | NDCG@10 | Spearman ρ | ILD@5 | Novelty@5 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Random | 0.488 | 0.070 | 0.119 | 0.765 | 0.589 | 0.097 | **0.332** | 0.322 | -0.011 | 0.778 | 0.701 |
| Popularity | 0.429 | 0.058 | 0.100 | 0.618 | 0.570 | 0.090 | **0.354** | 0.352 | 0.070 | 0.325 | 0.258 |
| Rating-only | 0.194 | 0.038 | 0.062 | 0.529 | 0.445 | 0.045 | **0.162** | 0.235 | 0.029 | 0.853 | 0.855 |
| Taste-only | 0.800 | 0.148 | 0.241 | 0.971 | 0.807 | 0.252 | **0.784** | 0.785 | 0.361 | 0.360 | 0.739 |
| Hybrid (production) | 0.976 | 0.212 | 0.332 | 1.000 | 1.000 | 0.356 | **0.863** | 0.804 | 0.227 | 0.587 | 0.696 |

### Hybrid lift over baselines (NDCG@5)

| Baseline | Baseline NDCG@5 | Hybrid NDCG@5 | Absolute Δ | Relative lift |
|---|---|---|---|---|
| Random | 0.332 | 0.863 | +0.531 | +159.9% |
| Popularity | 0.354 | 0.863 | +0.509 | +143.6% |
| Rating-only | 0.162 | 0.863 | +0.701 | +432.9% |
| Taste-only | 0.784 | 0.863 | +0.079 | +10.1% |

### Per-context NDCG@5

| Context | Personas | Random | Popularity | Rating-only | Taste-only | Hybrid |
|---|---|---|---|---|---|---|
| solo | 12 | 0.276 | 0.340 | 0.245 | 0.987 | 0.886 |
| nearby | 5 | 0.344 | 0.247 | 0.035 | 0.632 | 0.813 |
| similar | 4 | 0.371 | 0.442 | 0.255 | 1.000 | 0.784 |
| home | 10 | 0.400 | 0.396 | 0.045 | 0.465 | 0.868 |
| tours | 3 | 0.257 | 0.333 | 0.307 | 1.000 | 0.943 |

### List-health metrics (top-10)

| Ranker | Catalog coverage | ILD@5 | Novelty@5 |
|---|---|---|---|
| Random | 0.120 | 0.778 | 0.701 |
| Popularity | 0.120 | 0.325 | 0.258 |
| Rating-only | 0.120 | 0.853 | 0.855 |
| Taste-only | 0.880 | 0.360 | 0.739 |
| Hybrid (production) | 0.928 | 0.587 | 0.696 |

### Methodology notes

- **Ground-truth relevance** is computed independently of the scoring formula: per persona, a candidate is graded 0–3 by canonical-key set-intersection with the persona's `loves`/`dislikes`. The scorer uses a tanh-normalised mean over the taste vector; the two formulas share no math, so engine performance against this label set reflects real lift rather than formula self-consistency.
- For `nearby` and `home` contexts, ground-truth relevance is distance-capped (>200 km → grade ≤ 1; >500 km → 0) so a Cairo-resident's home feed isn't "correct" when it surfaces Aswan.
- `random` baseline uses a seeded LCG (Mulberry32, seed 42) for reproducibility.
- Hybrid ranker runs with `epsilon = 0` (ε-greedy exploration disabled) to keep evaluation deterministic.
- The existing `evaluate_accuracy.js` script remains in place as a v1 regression continuity check on the original 5-persona / 10-place suite (currently 19/20 = 95.0% assertion pass-rate, against the original design-intent target of 90%).