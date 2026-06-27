# Noetix High-Control Walk Command Plan

- plan: moonrobo/noetix-e1/high-control-walk-plan/first-trusted-square-northeast-stepout-lola
- trace: moonrobo/noetix-e1/endless-forward-moon-walk/first-trusted-square-northeast-stepout-lola
- robot: noetix-e1-lab-01
- capability: control.high.walk
- command class: HighControl
- frames: 32
- segments: 3
- total duration: 3.2 s
- expected distance: 0.384 m
- max x command: 0.12 m/s
- max yaw command: 0 rad/s
- requires approval: true
- requires dry run: true
- executable on hardware: false
- hardware authority: moonmoon-safety-gate-only
- status: walk-command-dry-run-review
- note: Moonrobo high-level walk command plan segments the Noetix finite trace prefix into dry-run approval windows that respect the sibling robot profile limits. It is not hardware authority and does not enable execution.

## Command Segments

- segment-0-15: frames 0..15 duration=1.5s x=0.12m/s yaw=0rad/s status=dry-run-command-review
- segment-15-30: frames 15..30 duration=1.5s x=0.12m/s yaw=0rad/s status=dry-run-command-review
- segment-30-32: frames 30..32 duration=0.2s x=0.12m/s yaw=0rad/s status=dry-run-command-review
