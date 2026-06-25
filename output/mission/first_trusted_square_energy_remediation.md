# Selected Route Energy Remediation

- evidence: first-trusted-square-energy-remediation-v1
- site: first-trusted-square
- route: northeast-stepout
- power window: first-trusted-square-power-window-computed-v1
- decision: block
- all-route required energy: 1265 Wh
- bounded required energy: 1090 Wh
- verified available energy: 234.938073 Wh
- bounded margin: -855.061927 Wh
- margin gap: 1105.061927 Wh
- selected-route drive hours: 0.25
- dark survival hours: 13
- route-count demand reduction: 175 Wh

## Demand Components

- reserve: 600 Wh
- drive: 30 Wh
- comms: 5 Wh
- thermal survival: 455 Wh

## Reasons

- selected-route bounded demand still exceeds verified available energy by 855.061927 Wh
- bounding demand from 6 candidate routes to one selected route removes 175 Wh but does not clear the gate
- thermal survival demand 455 Wh exceeds verified available energy 234.938073 Wh
- 6 route candidates remain blocked before energy can move out of review

## Next Action

reduce reserve or dark-survival demand, increase verified power-window energy, or keep northeast-stepout out of MoonRobo simulation

