# Moonmoon evidence dossier: First Trusted Square / Shackleton Rim rehearsal tile

- workspace: moonbook://moonmoon/first-trusted-square
- site: first-trusted-square

## Entries

- dataset/lro-lola-first-trusted-square-dem-v1: LOLA Shackleton Rim DEM byte-range fixture
  - kind: source-dataset
  - claim: measured
  - confidence: 1
  - path: datasets/lro-lola-first-trusted-square-dem-v1.json
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
- source-extraction/extract-ldem-875s-20m-first-trusted-square-v1: Extract first-trusted-square-lola
  - kind: source-extraction-candidate
  - claim: measured
  - confidence: 0
  - path: source-extractions/extract-ldem-875s-20m-first-trusted-square-v1.json
- validation/lro-lola-first-trusted-square-dem-v1: Source validation for lro-lola-first-trusted-square-dem-v1
  - kind: source-validation
  - claim: derived
  - confidence: 1
  - path: datasets/lro-lola-first-trusted-square-dem-v1.validation.json
- terrain/first-trusted-square/metrics: Terrain metrics for First Trusted Square / Shackleton Rim rehearsal tile
  - kind: derived-terrain
  - claim: derived
  - confidence: 0.7544
  - path: terrain/first-trusted-square/metrics.json
- mission/first-trusted-square/traverse: Traverse readiness for First Trusted Square / Shackleton Rim rehearsal tile
  - kind: mission-decision
  - claim: derived
  - confidence: 0.7544
  - path: mission/first-trusted-square/traverse.json

## Review Queue

- blocker-0 [high] terrain exceeds early traverse limits -> operator
- blocker-1 [high] requires alternate route or stronger dataset -> operator
- traverse-0 [high] max neighbor grade exceeds rover hard limit -> mission-review
- traverse-1 [high] roughness exceeds rover hard limit -> mission-review
- question-0 [low] Add illumination windows for robot energy and thermal constraints. -> moonclaw
- question-1 [low] Find alternate route candidates around the blocked LOLA terrain patch. -> moonclaw
- question-2 [low] Export the dossier into a LunarBook workspace for review. -> moonclaw

