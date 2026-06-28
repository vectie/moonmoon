# Vision

Moonmoon should be the smallest credible lunar world model in the Moon suite:
typed source evidence, terrain claims, mission constraints, and an inspectable
operator view, all owned by MoonBit.

The first useful product is not a large integration surface. It is one trusted
site that can answer:

- which source data backs the claim,
- what terrain metrics were derived,
- which route is preferred,
- why the route is still blocked or reviewable,
- whether the preferred route has a motion handoff contract,
- what evidence must change before the model can allow traversal.

Other suite products can consume Moonmoon later. The standalone model comes
first.

Locomotion follows the same rule. Moonmoon should expose route-motion readiness
from the standalone view, while Moonphys remains a clean physics library. Robot
walking, URDF gait assets, and live Rabbita animation belong in a future suite
adapter that consumes Moonmoon evidence instead of becoming part of the core
world model.
