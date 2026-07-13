# MoonMold simulation ingestion

MoonMoon consumes only `simulation-model` artifacts with
`physics-derived-from` lineage to the currently accepted engineering digest.
The importer converts declared mm/cm/m units into a scale-to-metres value and
preserves coordinate system, up axis, handedness, assumptions, losses,
authority, and payload identity.

Input is portable MoonMold artifact+transform JSON and the accepted engineering
digest. Output is a `SimulationSpatialInput`; it remains simulation evidence,
not calibrated truth or physical readiness.

Acceptance requires exact child identity/digest, current engineering parent,
MoonMoon consumer authorization, explicit assumptions and losses, supported
scale/frame, and the `simulation-evidence` claim ceiling. Stale, styled,
loss-stripped, assumption-free, unknown-scale, or physical-claim inputs fail
closed.

The fixture is a byte-for-byte MoonMold portable export. Runtime ingestion does
not import MoonMold source.

