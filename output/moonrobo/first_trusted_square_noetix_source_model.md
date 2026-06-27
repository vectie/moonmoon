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
- missing collision links: 25
- missing inertial links: 25
- source metadata blockers: 50
- joint limits: 24
- low-level joint control enabled: false
- high-level walk requires approval: true
- status: source-model-metadata-blocked
- hardware authority: moonmoon-safety-gate-only
- note: Sibling Moonrobo Noetix source model provides URDF joint limits and visual geometry, including a placeholder base mesh, but exposes no authoritative collision or inertial tags for any link. Moonphys collision/inertia reports must therefore remain review-only until Moonrobo publishes those tags.

## Visual Geometry

- base_link: urdf-visual-mesh; bounds derived from referenced obj vertices
- torso_link: urdf-visual-box
- chest_link: urdf-visual-box
- left_arm_1: urdf-visual-cylinder
- right_arm_1: urdf-visual-cylinder
- left_leg_1: urdf-visual-cylinder

## Metadata Blockers

- missing collision links: base_link, torso_link, chest_link, left_arm_1, left_arm_2, left_arm_3, left_arm_4, left_hand, right_arm_1, right_arm_2, right_arm_3, right_arm_4, right_hand, left_leg_1, left_leg_2, left_leg_3, left_leg_4, left_leg_5, left_foot, right_leg_1, right_leg_2, right_leg_3, right_leg_4, right_leg_5, right_foot
- missing inertial links: base_link, torso_link, chest_link, left_arm_1, left_arm_2, left_arm_3, left_arm_4, left_hand, right_arm_1, right_arm_2, right_arm_3, right_arm_4, right_hand, left_leg_1, left_leg_2, left_leg_3, left_leg_4, left_leg_5, left_foot, right_leg_1, right_leg_2, right_leg_3, right_leg_4, right_leg_5, right_foot

## Joint Limits

- arm_l1_joint[0]: lower=-1.8 upper=1.8 effort=45 velocity=3 source=urdf-limit-tag
- arm_l2_joint[1]: lower=-1.6 upper=1.6 effort=45 velocity=3 source=urdf-limit-tag
- arm_l3_joint[2]: lower=-1.8 upper=1.8 effort=35 velocity=3 source=urdf-limit-tag
- arm_l4_joint[3]: lower=-1.6 upper=1.6 effort=30 velocity=3 source=urdf-limit-tag
- arm_l5_joint[4]: lower=-1.2 upper=1.2 effort=20 velocity=3 source=urdf-limit-tag
- leg_l1_joint[5]: lower=-1.2 upper=1.2 effort=90 velocity=3 source=urdf-limit-tag
- leg_l2_joint[6]: lower=-0.9 upper=0.9 effort=90 velocity=3 source=urdf-limit-tag
- leg_l3_joint[7]: lower=-1.6 upper=1.6 effort=100 velocity=3 source=urdf-limit-tag
- leg_l4_joint[8]: lower=-1.8 upper=1.8 effort=100 velocity=3 source=urdf-limit-tag
- leg_l5_joint[9]: lower=-0.8 upper=0.8 effort=80 velocity=3 source=urdf-limit-tag
- leg_l6_joint[10]: lower=-0.8 upper=0.8 effort=80 velocity=3 source=urdf-limit-tag
- arm_r1_joint[11]: lower=-1.8 upper=1.8 effort=45 velocity=3 source=urdf-limit-tag
- arm_r2_joint[12]: lower=-1.6 upper=1.6 effort=45 velocity=3 source=urdf-limit-tag
- arm_r3_joint[13]: lower=-1.8 upper=1.8 effort=35 velocity=3 source=urdf-limit-tag
- arm_r4_joint[14]: lower=-1.6 upper=1.6 effort=30 velocity=3 source=urdf-limit-tag
- arm_r5_joint[15]: lower=-1.2 upper=1.2 effort=20 velocity=3 source=urdf-limit-tag
- leg_r1_joint[16]: lower=-1.2 upper=1.2 effort=90 velocity=3 source=urdf-limit-tag
- leg_r2_joint[17]: lower=-0.9 upper=0.9 effort=90 velocity=3 source=urdf-limit-tag
- leg_r3_joint[18]: lower=-1.6 upper=1.6 effort=100 velocity=3 source=urdf-limit-tag
- leg_r4_joint[19]: lower=-1.8 upper=1.8 effort=100 velocity=3 source=urdf-limit-tag
- leg_r5_joint[20]: lower=-0.8 upper=0.8 effort=80 velocity=3 source=urdf-limit-tag
- leg_r6_joint[21]: lower=-0.8 upper=0.8 effort=80 velocity=3 source=urdf-limit-tag
- waist_1_joint[22]: lower=-0.8 upper=0.8 effort=80 velocity=2 source=urdf-limit-tag
- waist_2_joint[23]: lower=-0.5 upper=0.5 effort=80 velocity=2 source=urdf-limit-tag
