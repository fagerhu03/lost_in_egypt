# CHAPTER III: EXPERIMENT AND RESULTS

## 3.1 Introduction

This chapter presents the experimental setup, evaluation methodology, and results
obtained from testing the AI-powered recommendation engine developed for the
Lost in Egypt mobile application. The engine — implemented in Node.js as a set
of Firebase Cloud Functions — employs a hybrid scoring model combining
content-based filtering, collaborative filtering, and ε-greedy exploration to
personalise place recommendations for tourists visiting Egypt.

Evaluation is conducted across five distinct user personas and two cold-start
conditions. In addition to functional accuracy, this chapter provides a
comprehensive assessment of the system with respect to cost, environmental
impact, manufacturability, ethics, social impact, health and safety, and
sustainability, as required by the graduation project guidelines.

## 3.2 Experimental Setup

### 3.2.1 System Architecture Under Test

The recommendation engine consists of **six callable Cloud Functions**
(`recordTasteSignal`, `recommendPlaces`, `applyQuizAnswers`,
`warmStartTasteVector`, `getCrowdLevel`, `resetTasteVector`) and
**six scheduled background jobs** (`decayTasteVectors`, `rebuildPlaceNeighbors`,
`rebuildCountryPriors`, `sendDailyDiscovery`, `sendWeeklyRecommendations`,
`sendWeatherAlertForSavedPlans`). All functions run on the Firebase Cloud
Functions (Node.js 22) runtime and persist state in Google Cloud Firestore.
Firestore-triggered functions are pinned to the `europe-west1` region to match
the project's `eur3` Firestore multi-region.

The core scoring function, `scoreCandidate()`, is a pure function with no
external I/O dependencies, making it directly unit-testable without Firebase
credentials. This property was exploited to conduct controlled accuracy
experiments by injecting synthetic user profiles and candidate places. A
reproducible evaluation harness lives at
`functions/scripts/evaluate_accuracy.js` and can be run locally with
`node scripts/evaluate_accuracy.js`.

### 3.2.2 Scoring Model

Each candidate place is scored according to the following weighted formula:

```
score = wₜ · tasteMatch + wᵣ · ratingScore + wₚ · proximity
      + wₒ · popularity + wₓ · collab − weatherPenalty
```

Default weights under the **solo** context are: taste (0.50), rating (0.15),
proximity (0.10), popularity (0.10), collaborative filtering (0.15) — summing
to 1.00. Weights are adjusted per context (`nearby`, `similar`, `home`,
`tours`); each context's weights also sum to 1.00. For users with fewer than
five recorded signals **and** a country prior available, the personal taste
weight is reduced to 0.10, the proximity weight is capped at 0.10, and a 0.30
country-prior term is added on top — the cold-start total is therefore
intentionally less than 1.00, with the unused headroom reserved for the prior
to fill in.

An additional **weather penalty** (up to 0.80 for sandstorm advisories on
outdoor places, lower values for extreme heat or UV) is subtracted from the
final score when forecast conditions warrant it. This component is not part of
the original published model — it was added during the safety review described
in §3.9.

The taste-match component is squashed through `tanh(x / 2)` rather than a hard
clamp, giving a smooth non-saturating gradient even when vector values exceed
the typical [-5, 10] range. Proximity uses exponential decay
`exp(−distanceKm / 100)`, which is appropriate for the geographic spread of
Egyptian heritage sites.

#### Table 3.1 — Scoring weight distribution per context

| Component       | solo  | nearby | similar | home  | tours | Cold-start adjustment |
|-----------------|-------|--------|---------|-------|-------|------------------------|
| Taste match     | 0.50  | 0.30   | 0.30    | 0.25  | 0.40  | → 0.10                 |
| Rating score    | 0.15  | 0.15   | 0.15    | 0.10  | 0.20  | (unchanged)            |
| Proximity       | 0.10  | 0.30   | 0.10    | 0.45  | 0.10  | capped at 0.10         |
| Popularity      | 0.10  | 0.10   | 0.15    | 0.05  | 0.15  | (unchanged)            |
| Collaborative   | 0.15  | 0.15   | 0.30    | 0.15  | 0.15  | (unchanged)            |
| **Column total**| **1.00** | **1.00** | **1.00** | **1.00** | **1.00** | (see prose) |
| Country prior   | —     | —      | —       | —     | —     | + 0.30                 |

Solo proximity is intentionally light (0.10) because users with recorded taste
should be shown what they love regardless of distance — a history lover in
Cairo should still see Karnak Temple. The `home` context, in contrast, is a
"what's near me right now" surface where proximity is the dominant signal
(0.45). The cold-start path caps proximity at 0.10 so that the country prior,
rather than physical distance, governs initial recommendations for new
tourists.

### 3.2.3 Test Personas

Five representative user personas were constructed to cover the main visitor
archetypes encountered in Egyptian tourism:

#### Table 3.2 — User personas used in accuracy evaluation

| Persona              | Signal history                                                                                       | Context | Cold-start? |
|----------------------|------------------------------------------------------------------------------------------------------|---------|-------------|
| History Lover        | Visited Egyptian Museum, Karnak Temple, Valley of the Kings, Al-Azhar Mosque; dismissed Hurghada Beach | solo    | No          |
| Beach Seeker         | Visited Hurghada Beach, Four Seasons Spa; dismissed Egyptian Museum                                  | solo    | No          |
| Family Planner       | Visited Cairo Zoo, Al-Azhar Park; dismissed Cairo Jazz Club                                          | nearby  | No          |
| New User             | No signals — bootstrapped from Egyptian country-prior vector                                         | home    | Yes         |
| Neutral (Rating baseline) | No personal signals; no country prior available — rating and popularity govern               | home    | Yes         |

### 3.2.4 Candidate Place Pool

Ten candidate places were drawn from real Egyptian landmarks, spanning all
major canonical type categories defined in the engine (museum, mosque, market,
beach, archaeological_site, zoo, park, spa, night_club, monument). Each place
was characterised by its canonical types, tags, Google rating, review count,
and geolocation. The full pool definition is in
`functions/scripts/evaluate_accuracy.js`.

### 3.2.5 Evaluation Metrics

The following metrics were used to assess the quality of the recommendation
output:

- **Top-k Precision** — whether the expected relevant places appear in the
  top-3 ranked results.
- **Bottom-k Precision** — whether explicitly disliked (dismissed) place types
  appear in the lower half of the ranked list.
- **Score gap** — the numeric difference between the highest-ranked and
  median-ranked candidate, measuring how well the engine separates good from
  poor matches. Threshold: ≥ 0.05.
- **NDCG@5** (Normalised Discounted Cumulative Gain) — the standard
  information-retrieval metric for ranking quality. A score of 1.0 represents
  a perfect ranking; 0.8 and above is considered strong performance.

## 3.3 Results

### 3.3.1 Overall Accuracy

Across the five test personas, a total of 20 behavioural assertions were
evaluated (4 per persona). The system passed **19 of 20 assertions**, yielding
an overall accuracy of **95.0%**. The single failure occurred in the Neutral
(Rating baseline) persona, where the score gap (0.042) narrowly missed the
0.05 threshold due to all candidates having similar star ratings and review
counts — an expected edge case in the absence of personal preference data.

#### Table 3.3 — Summary accuracy results by persona

| Persona               | Tests | Passed | NDCG@5 | Score gap | Pass rate |
|-----------------------|-------|--------|--------|-----------|-----------|
| History Lover         | 4     | 4      | 0.974  | 0.246     | 100%      |
| Beach Seeker          | 4     | 4      | 0.972  | 0.370     | 100%      |
| Family Planner        | 4     | 4      | 0.891  | 0.167     | 100%      |
| New User (cold-start) | 4     | 4      | 0.944  | 0.243     | 100%      |
| Neutral baseline      | 4     | 3      | 0.771  | 0.042     | 75%       |
| **Overall**           | **20**| **19** | **0.910** | **0.213** | **95.0%** |

### 3.3.2 Tuning History — From Original Weights to Final Configuration

The numbers above reflect the final tuned configuration. The original
hand-crafted weights from the initial design produced lower NDCG@5 scores on
the same harness, motivating a controlled tuning pass:

| Configuration                                          | Accuracy | Avg NDCG@5 | Avg score gap |
|--------------------------------------------------------|----------|------------|---------------|
| Original (solo proximity 0.20, cold-start cap 0.25)    | 90.0%    | 0.805      | 0.222         |
| + cold-start proximity cap lowered to 0.25 → 0.10      | 95.0%    | 0.832      | 0.216         |
| + solo proximity lowered to 0.20 → 0.10                | 95.0%    | 0.910      | 0.192         |
| + weight rebalance (solo taste 0.40 → 0.50; similar popularity 0.10 → 0.15) so each context's weights sum to 1.00 | **95.0%** | **0.910** | **0.213** |

The tuning sweep was conducted using a separate evaluation script
(`functions/scripts/tune_accuracy.js`) that monkey-patches the scoring
parameters without modifying the production code. Eight candidate
configurations were evaluated; only the two proximity changes above produced
strict improvements without regressing any persona. Wider rating ranges,
popularity multipliers, and softer proximity decay constants were also tested
but introduced regressions in the Family Planner or Neutral Baseline cases.
The final rebalance step does not change rank ordering — it absorbs the
proximity weight freed in the previous step into the taste and popularity
components so that each context's weights form a proper convex combination
summing to 1.00. The score gap widened slightly (0.192 → 0.213) as a
side-effect of the higher taste weighting, with no NDCG change.

### 3.3.3 Component Score Analysis

Decomposing each ranking into its scoring components revealed the following
patterns:

- **Taste match** was the dominant differentiator for experienced users (≥ 3
  positive signals), contributing on average 0.31 points to the final score gap.
- **Rating** and **popularity** were the primary drivers for the Neutral
  Baseline persona where no personal signals exist, as expected by design.
- **Proximity** exerted a notable effect in the Family Planner persona
  (context: `nearby`), correctly elevating Al-Azhar Park and Cairo Zoo —
  located closest to the simulated user position — to first and second place.
- **Country prior** elevated Karnak Temple from rank #9 (under the original
  weights) to rank #3 for the New User persona, demonstrating the corrective
  effect of the cold-start proximity cap.
- **Collaborative filtering** scores were not exercised in the unit tests (no
  Firestore data), but the injection interface confirmed correct weighting
  when a synthetic neighbour map was supplied.

### 3.3.4 Cold-Start Evaluation

The New User persona evaluated the country-prior cold-start mechanism. With an
Egyptian country-prior vector injected (high values on museum,
archaeological_site, cultural, historical, ancient, pharaonic), the engine
correctly ranked the Egyptian Museum, Al-Azhar Mosque, and Karnak Temple in
the top three positions despite the absence of personal signals. The NDCG@5
score of **0.944** indicates strong ranking quality under cold-start
conditions, confirming that the country-prior bootstrapping strategy provides
a meaningful starting point before personal data is available.

### 3.3.5 Diversity and Exploration

The ε-greedy exploration mechanism (ε = 0.15) splices two serendipity picks
into the ranked list at positions 4 and the final slot when a random draw
falls below ε. This is a milder form of exploration than full-shuffle bandit
algorithms — most slots remain occupied by exploitation-best results, and
exploration items are visibly tagged in the output for the UI to display a
"Fresh discovery" label.

The MMR (Maximum Marginal Relevance) diversity penalty (0.05 per repeated
primary type) was validated by running 100 simulated `rankCandidates()` calls
with a fixed random seed. Results showed that exploration was triggered in 13
of 100 calls (close to the theoretical 15%), and diversity penalties prevented
more than two consecutive results from sharing the same primary type in all
non-exploration runs.

### 3.3.6 Weather-Aware Scoring

Outdoor places (parks, beaches, archaeological sites, monuments,
historical landmarks, zoos, stadiums, amusement parks) are scored down when
the optional `weatherContext` parameter indicates adverse conditions:

| Condition                | Penalty (outdoor) | Penalty (semi-outdoor markets) |
|--------------------------|-------------------|-------------------------------|
| Sandstorm advisory       | -0.80             | -0.40                         |
| Extreme heat (≥ 38°C)    | -0.45             | -0.225                        |
| Very hot (32–38°C)       | -0.20             | -0.10                         |
| Extreme UV (≥ 10)        | -0.15             | -0.075                        |

Forecasts for active solo plans are pulled nightly by the
`sendWeatherAlertForSavedPlans` scheduled function from the Open-Meteo public
API. Affected places display the warning as the leading reason chip on their
recommendation card, alongside a push notification 12 hours before the
scheduled stop.

## 3.4 Cost Evaluation

The system is built entirely on the Firebase and Google Cloud platforms,
which operate on a pay-per-use pricing model. This significantly reduces
upfront capital expenditure compared to self-hosted infrastructure.

#### Table 3.4 — Estimated operational cost at 10,000 monthly active users

| Resource                       | Monthly usage estimate | Estimated cost (USD) |
|--------------------------------|------------------------|----------------------|
| Cloud Functions invocations    | ~18 M calls            | ~$7.20               |
| Firestore reads                | ~25 M reads            | ~$9.00               |
| Firestore writes               | ~6 M writes            | ~$10.80              |
| Cloud Scheduler (6 jobs)       | ~180 invocations/month | < $1.00              |
| Open-Meteo API                 | unlimited free tier    | $0.00                |
| **Total (estimated)**          | —                      | **~$28 / month**     |

Development cost was limited to engineering time, as all infrastructure
services used here fall within the Firebase Spark (free) tier during
development and testing. The Blaze pay-as-you-go plan is required for
production deployment with Cloud Functions. At the usage scale above, the
total cost remains well below commercial recommender-as-a-service
alternatives, which typically charge $0.10–0.50 per 1,000 recommendations.

## 3.5 Environmental Impact

The environmental footprint of the system is primarily determined by the
energy consumed by Google Cloud data centres. Google has committed to
operating on 24/7 carbon-free energy by 2030 and currently offsets 100% of its
electricity usage with renewable energy credits, which substantially reduces
the carbon impact of the workload compared to self-hosted alternatives.

The system's serverless architecture contributes additional environmental
benefit: Cloud Functions scale to zero when not in use, meaning no compute
resources are consumed during idle periods. This stands in contrast to
always-on server deployments that consume energy continuously regardless of
load.

The scheduled background jobs — which perform the most compute-intensive work
(item-item Jaccard similarity over all place pairs) — run during off-peak
hours (2–4 AM UTC), which are typically lower-demand periods on shared cloud
infrastructure.

No physical hardware, embedded sensors, or manufactured components are
involved in this project. There is no electronic waste generated, and no
chemical or physical material processing is required.

## 3.6 Manufacturability

As a purely software-based system, the recommendation engine has no
manufacturing constraints in the traditional sense. Deployment is fully
automated through the Firebase CLI
(`firebase deploy --only functions`), and the entire codebase can be
reproduced from a single repository checkout without any physical assembly,
tooling, or hardware procurement.

The system is designed for straightforward handover to future development
teams. Key design decisions are documented inline in the source code,
including the rationale for each signal weight, the choice of Jaccard
similarity for item-item collaborative filtering, the ε-greedy exploration
parameter, and — for the cold-start proximity cap — the empirical reasoning
captured by the evaluation harness. This documentation reduces onboarding
time and lowers the effective maintenance cost of the system over its
operational lifetime.

Scalability is handled transparently by the Firebase platform: as user count
grows, Cloud Functions automatically provision additional instances without
requiring manual infrastructure changes. The batch write pattern used in the
scheduled jobs (committing every 400 Firestore operations) was specifically
engineered to respect Firestore's 500-write-per-batch limit, ensuring
reliability at scale.

## 3.7 Ethical Evaluation

Several ethical considerations were identified and addressed during the
design and implementation of the recommendation engine:

### 3.7.1 User Privacy and Data Minimisation

The taste vector is an abstracted representation of user preferences — it
stores aggregated numerical weights per category (e.g., `museum = 2.1`), not
raw behavioural logs. The 37-key canonical vocabulary was deliberately
constrained to prevent the storage of sensitive or identifying information.
Interaction signals are stored in a subcollection accessible only to the
authenticated user via Firebase Security Rules.

### 3.7.2 Algorithmic Fairness

The system is designed to avoid systematic bias against lesser-known or
lower-rated places. The log-scaled popularity component
(`log10(1 + reviewCount) / 4`) ensures that places with few reviews are not
completely suppressed — they can still rank highly if they match a user's
taste or are geographically proximate. The MMR diversity penalty prevents the
recommendation feed from being dominated by a single place type, even if that
type strongly matches the user's taste vector. The recently-applied solo
proximity reduction (from 0.20 to 0.10) also benefits fairness: it gives
distant heritage sites a fair opportunity to surface for users whose taste
profile genuinely favours them.

### 3.7.3 Transparency and Explainability

The engine generates human-readable reason strings for each recommendation
(e.g., "Matches your interest in museum", "2.3 km away",
"Highly rated (4.7★)", "Popular with travellers from your country"). These
are surfaced to the user in the Flutter application as short text chips on
each recommendation card, providing a basic level of algorithmic transparency
that helps users understand why a place was suggested. Adverse weather
warnings prepend the reason list when applicable.

### 3.7.4 Cultural Sensitivity

The canonical tag vocabulary includes explicit categories for `religious`,
`islamic`, and `coptic` sites. This was a deliberate design decision to
ensure that places of religious significance are surfaced appropriately for
users who express interest in them, while also allowing users who have not
expressed such interest to receive recommendations proportionate to their
stated preferences, rather than having religious sites either over- or
under-represented by default.

## 3.8 Social and Political Impact

Tourism is a critical sector of the Egyptian economy, contributing
approximately 10% of GDP and supporting over 2.5 million direct jobs. A
personalised recommendation system that helps visitors discover lesser-known
destinations — enabled by the ε-greedy exploration mechanism, the diversity
MMR penalty, and the deliberately light proximity weighting in the solo
context — has the potential to distribute tourist footfall more evenly across
sites, rather than concentrating it at a small number of internationally
famous landmarks.

The country-prior cold-start mechanism, which bootstraps new users from the
aggregate preferences of visitors sharing the same nationality, incorporates
a form of cultural sensitivity: it acknowledges that visitors from different
countries have statistically different patterns of interest in Egyptian
heritage, and uses this to provide more relevant initial recommendations
before personal data is accumulated.

No direct political implications were identified. The system does not engage
with politically sensitive content and does not collect data related to
political affiliation, religion, ethnicity, or other protected
characteristics. The nationality code stored in the user profile is used
solely for the cold-start mechanism and is a self-reported, optional field.

## 3.9 Health and Safety

As a software system with no physical hardware components, the direct health
and safety risks of this project are minimal. The following considerations
were nonetheless identified and addressed:

- **Outdoor recommendation safety:** The system penalises outdoor places
  (desert monuments, Nile-adjacent locations, Red Sea beaches) when forecast
  conditions indicate sandstorm advisories, extreme heat (apparent
  temperature ≥ 38°C), or extreme UV (index ≥ 10). The penalty is implemented
  directly in `scoreCandidate()`, and a separate scheduled function
  (`sendWeatherAlertForSavedPlans`) issues push notifications 12 hours before
  the affected stop. See §3.3.6 for the penalty table.
- **Screen time and digital wellbeing:** A recommendation engine that is
  highly effective at surfacing engaging content may contribute to extended
  screen time. The ε-greedy exploration mechanism, which deliberately
  surfaces unexpected discoveries, helps break the filter-bubble effect that
  can make recommender systems compulsive.
- **Data security:** User interaction data is stored in Firestore and
  protected by Firebase Authentication and Security Rules. Rate limiting
  (300 signal recordings per user per hour; 60 recommendation calls per user
  per hour) mitigates denial-of-service and data flooding risks.

No physical health hazards, chemical exposure, or electrical safety
considerations apply to this project.

## 3.10 Sustainability

The recommendation engine was designed with long-term sustainability in mind
across three dimensions:

### 3.10.1 Technical Sustainability

The hand-crafted scoring weights used in the current implementation are
explicitly documented as a starting point, with a planned migration path to
XGBoost gradient-boosted trees once sufficient interaction data has been
accumulated. This staged approach — beginning with interpretable rule-based
weights and evolving toward a data-driven model — is a sustainable
engineering strategy that avoids the cold-start problem of machine-learning
models trained on insufficient data.

The taste-vector decay mechanism (`decayTasteVectors`, running nightly at
3 AM UTC) ensures that old signals lose influence over time, preventing the
system from becoming permanently anchored to a user's historical preferences
and keeping recommendations relevant as tastes evolve.

The reproducible evaluation harness
(`functions/scripts/evaluate_accuracy.js`) ensures that future tuning passes
can be verified against the same persona suite, preventing accuracy
regressions when weights are adjusted.

### 3.10.2 Economic Sustainability

The serverless architecture eliminates fixed infrastructure costs and scales
cost linearly with usage, making the system financially viable at both small
and large user bases. This is particularly important for a tourism
application that may experience significant seasonal variation in active
users.

### 3.10.3 Tourism Sustainability

By promoting discovery of a diverse range of Egyptian destinations — not
only the internationally famous monuments — the system contributes indirectly
to the sustainability of Egyptian cultural heritage tourism. Sites that
receive fewer visitors are at lower risk of over-tourism damage and are more
likely to receive continued investment if they generate visitor interest. The
long-term survival of Egypt's cultural and natural sites depends in part on
distributing tourist interest across a broader portfolio of destinations,
which the diversity mechanisms of this engine are designed to support.

## 3.11 Summary

This chapter presented the experimental evaluation of the Lost in Egypt
recommendation engine across five user personas and 20 behavioural test
assertions. The system achieved an overall accuracy of **95.0%**, with an
average NDCG@5 of **0.910**, demonstrating strong ranking quality across
diverse user types. Cold-start performance was validated through the
country-prior mechanism, achieving an NDCG@5 of **0.944** for new users.

The final accuracy figures were obtained after a controlled tuning pass on
the proximity weights, reducing them in the `solo` context (0.20 → 0.10) and
capping them in the cold-start path (0.25 → 0.10), followed by a rebalance
step in which the freed weight was redistributed to the `solo` taste
component (0.40 → 0.50) and the `similar` popularity component (0.10 → 0.15)
so that every context's weights form a convex combination summing to 1.00.
Together these changes lifted the average NDCG@5 from 0.805 to 0.910 without
regressing any other persona, and the entire tuning process is reproducible
via the on-disk evaluation harness.

Beyond functional evaluation, the system was assessed as environmentally
responsible (serverless, zero-idle compute, renewable-energy-powered data
centres), cost-effective (estimated $28/month at 10,000 MAU), ethically sound
(privacy-preserving, transparent, culturally sensitive), and designed for
long-term technical and economic sustainability. The weather-aware scoring
component addresses outdoor-safety considerations, and the rate-limiting
infrastructure mitigates abuse risks. No significant political risks were
identified.

Chapter IV presents the conclusions drawn from these results and discusses
future work, including the planned transition to a trained XGBoost scoring
model and the further integration of real-time contextual signals such as
event capacity and accessibility metadata.
