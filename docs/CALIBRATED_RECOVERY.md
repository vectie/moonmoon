# Calibrated recovery contract

MoonMoon does not equate an adverse scenario with automatic failure. The
mission input owns the fault model: severity, observability, recoverability,
retained performance, energy cost, uncertainty, recovery action, and an exact
calibration reference. This prevents scenario-specific answers from being
hidden in simulator code.

The simulator applies one general policy:

- qualified observable faults retaining at least 75% performance recover;
- qualified recoverable faults retaining at least 40% continue as a reduced mission;
- unobservable or more severe modeled faults return safely;
- missing, invalid, or over-uncertain models fail closed.

The receipt exposes every state transition and never grants physical authority.
Calibration evidence should be content-addressed, independently reviewable, and
traceable to a testbed or authoritative source. Re-running the same design and
terrain must produce the same receipt.

A referenced but provisional model may produce `scenario-qualified` evidence.
It must set `qualified: false`; MoonMoon will not raise it to
`calibrated-digital-twin`. This lets early design simulations remain useful
without laundering deterministic MoonRobo evidence into a calibration claim.
