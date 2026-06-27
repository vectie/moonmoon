# Noetix Static Support Evidence

- report: moonrobo/noetix-e1/static-support/first-trusted-square-northeast-stepout-lola
- trace: moonrobo/noetix-e1/endless-forward-moon-walk/first-trusted-square-northeast-stepout-lola
- profile: moonrobo/noetix-e1/physics-profile-v0
- mass: 38 kg (simulation-assumption; no inertial tags in referenced URDF/profile)
- actuator profiles: 24 URDF joint limits
- collision profiles: 8 review shapes
- frames: 32
- stable frames: 0
- review frames: 32
- traction-review frames: 0
- worst planar margin: -0.035 m
- worst traction margin: 35.26888932191745 N
- status: static-support-review
- hardware authority: moonmoon-safety-gate-only
- note: Static support, contact-patch, and traction evidence only: dynamic walking can be valid with COM outside the instantaneous single-foot rectangle, but that requires a controller/dynamics model not yet present. Contact patches use Moonphys heightfield patch sampling and patch-load pressure review over assumed foot soles, and traction margins use Moonphys terrain-normal force projection plus friction-cone review over assumed foot friction.

## Frame Margins

- frame 0 t=0s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 1 t=0.1s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 2 t=0.2s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 3 t=0.30000000000000004s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 4 t=0.4s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 5 t=0.5s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 6 t=0.6000000000000001s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 7 t=0.7000000000000001s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 8 t=0.8s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 9 t=0.9s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 10 t=1s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 11 t=1.1s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 12 t=1.2000000000000002s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 13 t=1.3s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 14 t=1.4000000000000001s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 15 t=1.5s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 16 t=1.6s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 17 t=1.7000000000000002s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 18 t=1.8s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 19 t=1.9000000000000001s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 20 t=2s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 21 t=2.1s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 22 t=2.2s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 23 t=2.3000000000000003s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 24 t=2.4000000000000004s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 25 t=2.5s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 26 t=2.6s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 27 t=2.7s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 28 t=2.8000000000000003s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 29 t=2.9000000000000004s phase=left-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 30 t=3s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review
- frame 31 t=3.1s phase=right-support margin=-0.035m patch=contact-patch-review traction=traction-ok status=contact-patch-review

