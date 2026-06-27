# Noetix Source Model Audit

- report: moonrobo/noetix-e1/source-model/audit-v0
- robot: noetix-e1-lab-01
- source model: ../moonrobo/examples/noetix-e1/model/robot.urdf
- source profile: ../moonrobo/examples/noetix-e1/robot.json
- links: 25
- joints: 24
- visual geometries: 6
- collision tags: 0
- inertial tags: 0
- joint limits: 24
- low-level joint control enabled: false
- high-level walk requires approval: true
- status: source-model-audit-review
- hardware authority: moonmoon-safety-gate-only
- note: Sibling Moonrobo Noetix source model provides URDF joint limits and visual geometry, including a placeholder base mesh, but exposes no authoritative collision or inertial tags. Moonphys collision/inertia reports must therefore remain review-only until Moonrobo publishes those tags.

## Visual Geometry

- base_link: urdf-visual-mesh; bounds derived from referenced obj vertices
- torso_link: urdf-visual-box
- chest_link: urdf-visual-box
- left_arm_1: urdf-visual-cylinder
- right_arm_1: urdf-visual-cylinder
- left_leg_1: urdf-visual-cylinder
