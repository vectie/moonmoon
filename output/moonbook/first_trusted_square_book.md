# Moonmoon evidence dossier: First Trusted Square / Shackleton Rim rehearsal tile

- workspace: moonbook://moonmoon/first-trusted-square
- site: first-trusted-square

## Entries

- dataset/fixture-first-trusted-square-dem-v1: Synthetic Shackleton Rim DEM fixture
  - kind: source-dataset
  - claim: simulated
  - confidence: 1
  - path: datasets/fixture-first-trusted-square-dem-v1.json
- source-candidate/candidate-lro-lola-sldem-first-trusted-square: LRO LOLA derived gridded topography candidate
  - kind: source-upgrade-candidate
  - claim: unknown
  - confidence: 0
  - path: source-candidates/candidate-lro-lola-sldem-first-trusted-square.json
- source-acquisition/acquire-lro-lola-gdr-south-pole-20m-v1: Acquire lro-lola-gdr-south-pole-selection
  - kind: source-acquisition-plan
  - claim: unknown
  - confidence: 0
  - path: source-acquisition/acquire-lro-lola-gdr-south-pole-20m-v1.json
- source-product/select-ldem-875s-20m-float-v1: Select ldem_875s_20m_float
  - kind: source-product-selection
  - claim: unknown
  - confidence: 0
  - path: source-products/select-ldem-875s-20m-float-v1.json
- validation/fixture-first-trusted-square-dem-v1: Source validation for fixture-first-trusted-square-dem-v1
  - kind: source-validation
  - claim: derived
  - confidence: 1
  - path: datasets/fixture-first-trusted-square-dem-v1.validation.json
- terrain/first-trusted-square/metrics: Terrain metrics for First Trusted Square / Shackleton Rim rehearsal tile
  - kind: derived-terrain
  - claim: derived
  - confidence: 0.6624
  - path: terrain/first-trusted-square/metrics.json
- mission/first-trusted-square/traverse: Traverse readiness for First Trusted Square / Shackleton Rim rehearsal tile
  - kind: mission-decision
  - claim: derived
  - confidence: 0.6624
  - path: mission/first-trusted-square/traverse.json

## Review Queue

- source-candidate-candidate-lro-lola-sldem-first-trusted-square [medium] Select a specific LOLA/SLDEM product, record its source URL and SHA-256, then regenerate the trusted-square fixture. -> data-review
- blocker-0 [medium] needs operator review before robot traverse planning -> operator
- blocker-1 [medium] fixture confidence is not high enough for physical mission planning -> operator
- traverse-0 [medium] max neighbor grade needs route review -> mission-review
- traverse-1 [medium] terrain confidence below traverse threshold -> mission-review
- question-0 [low] Replace synthetic DEM with an authoritative LOLA/LROC-backed fixture. -> moonclaw
- question-1 [low] Add illumination windows for robot energy and thermal constraints. -> moonclaw
- question-2 [low] Export the dossier into a LunarBook workspace for review. -> moonclaw

