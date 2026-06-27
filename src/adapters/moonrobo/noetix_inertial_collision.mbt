///|
pub(all) struct NoetixCollisionShapeEvidence {
  link_name : String
  shape : @moonphys.CollisionShape
  transform : @moonphys.Transform3
  bounds : @moonphys.CollisionBounds
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixTerrainCollisionEvidence {
  foot_id : String
  link_name : String
  expected_contact : Bool
  collision : @moonphys.HeightfieldCollision
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSelfContactWorldPairResponse {
  body_a_id : String
  body_b_id : String
  contact_status : String
  correction_a_m : Double
  correction_b_m : Double
  normal_impulse_ns : Double
  friction_impulse_ns : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSelfContactWorldResponse {
  world_id : String
  pair_count : Int
  broadphase_overlap_count : Int
  contact_count : Int
  resolved_contact_count : Int
  max_pair_correction_m : Double
  normal_impulse_ns : Double
  friction_impulse_ns : Double
  resolved_pairs : Array[NoetixSelfContactWorldPairResponse]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixInertialCollisionFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  center_of_mass : @moonphys.Vec3
  inertia : @moonphys.RigidBodyInertia
  mass_properties : @moonphys.CompositeMassProperties
  support_contact_torque_nm : @moonphys.Vec3
  support_contact_wrenches : Array[@moonphys.ContactPatchWrenchAssessment]
  support_wrench_motion_step : @moonphys.RigidBodyWrenchStep
  shape_count : Int
  terrain_contact_count : Int
  terrain_review_count : Int
  self_contact_manifold : @moonphys.CollisionContactManifold
  self_contact_resolution : @moonphys.CollisionManifoldResolution
  self_contact_world_response : NoetixSelfContactWorldResponse
  self_contact_correction_m : Double
  self_contact_world_correction_m : Double
  shapes : Array[NoetixCollisionShapeEvidence]
  terrain_collisions : Array[NoetixTerrainCollisionEvidence]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixInertialCollisionReport {
  report_id : String
  trace_id : String
  profile : NoetixPhysicsProfile
  frame_count : Int
  shapes_per_frame : Int
  self_contact_frame_count : Int
  terrain_review_frame_count : Int
  max_self_penetration_m : Double
  max_self_contact_correction_m : Double
  max_self_contact_world_correction_m : Double
  max_self_contact_normal_impulse_ns : Double
  max_self_contact_friction_impulse_ns : Double
  max_support_contact_torque_nm : Double
  frames : Array[NoetixInertialCollisionFrame]
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn vec_length(value : @moonphys.Vec3) -> Double {
  value.length_squared().sqrt()
}

///|
fn collision_shape_volume_sum(
  shapes : Array[NoetixCollisionShapeEvidence],
) -> Double {
  let mut total = 0.0
  for shape in shapes {
    total += @moonphys.collision_shape_volume(shape.shape)
  }
  total
}

///|
fn noetix_assumed_shape_mass(
  total_mass_kg : Double,
  shape : NoetixCollisionShapeEvidence,
  shape_count : Int,
  volume_sum : Double,
) -> Double {
  if volume_sum > 0.0 {
    total_mass_kg * @moonphys.collision_shape_volume(shape.shape) / volume_sum
  } else if shape_count > 0 {
    total_mass_kg / shape_count.to_double()
  } else {
    0.0
  }
}

///|
fn noetix_assumed_mass_properties(
  profile : NoetixPhysicsProfile,
  shapes : Array[NoetixCollisionShapeEvidence],
) -> @moonphys.CompositeMassProperties {
  let volume_sum = collision_shape_volume_sum(shapes)
  let elements : Array[@moonphys.MassPropertyElement] = []
  for shape in shapes {
    elements.push(
      @moonphys.collision_shape_mass_element(
        shape.shape.shape_id,
        noetix_assumed_shape_mass(
          profile.mass_model.mass_kg,
          shape,
          shapes.length(),
          volume_sum,
        ),
        shape.shape,
        shape.transform.translation,
      ),
    )
  }
  @moonphys.composite_mass_properties(
    "\{profile.robot_id}/assumed-composite-mass",
    elements,
  )
}

///|
fn link_world_position(
  pose_frame : NoetixLinkPoseFrame,
  link_name : String,
) -> @moonphys.Vec3 {
  for link in pose_frame.links {
    if link.link_name == link_name {
      return link.world_position
    }
  }
  pose_frame.body_position
}

///|
fn collision_shape_evidence(
  pose_frame : NoetixLinkPoseFrame,
  collision : NoetixCollisionShapeProfile,
) -> NoetixCollisionShapeEvidence {
  let transform = @moonphys.transform3(
    @moonphys.identity_basis3(),
    link_world_position(pose_frame, collision.link_name),
  )
  {
    link_name: collision.link_name,
    shape: collision.shape,
    transform,
    bounds: @moonphys.collision_world_bounds(collision.shape, transform),
    source_status: collision.source_status,
  }
}

///|
fn foot_geometry_for_link(
  profile : NoetixPhysicsProfile,
  link_name : String,
) -> NoetixFootGeometry {
  for geometry in profile.foot_geometry {
    if geometry.link_name == link_name {
      return geometry
    }
  }
  profile.foot_geometry[0]
}

///|
fn foot_probe_for_link(
  frame : NoetixMoonWalkFrame,
  link_name : String,
) -> NoetixFootContactProbe {
  if link_name == "right_foot" {
    frame.right_foot
  } else {
    frame.left_foot
  }
}

///|
fn terrain_collision_evidence(
  field : @moonphys.Heightfield,
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
  link_name : String,
) -> NoetixTerrainCollisionEvidence {
  let geometry = foot_geometry_for_link(profile, link_name)
  let probe = foot_probe_for_link(frame, link_name)
  let state = @moonphys.rigid_body_state(
    "\{link_name}/sole-probe",
    profile.mass_model.mass_kg,
    geometry.sole_radius_m,
    probe.position.add(@moonphys.vec3(0.0, 0.0, geometry.sole_radius_m)),
    @moonphys.vec3(0.0, 0.0, 0.0),
  )
  let collision = @moonphys.heightfield_collision(field, state)
  let matches_contact = collision.in_contact == probe.in_contact
  {
    foot_id: geometry.foot_id,
    link_name,
    expected_contact: probe.in_contact,
    collision,
    status: if matches_contact {
      "terrain-collision-matches-walk-contact"
    } else {
      "terrain-collision-contact-review"
    },
  }
}

///|
fn support_contact_wrenches(
  field : @moonphys.Heightfield,
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
  center_of_mass : @moonphys.Vec3,
) -> Array[@moonphys.ContactPatchWrenchAssessment] {
  let left_geometry = foot_geometry(profile, "left-foot")
  let right_geometry = foot_geometry(profile, "right-foot")
  let load = @moonphys.support_load_assessment(
    center_of_mass,
    [
      contact_footprint(frame.left_foot, left_geometry),
      contact_footprint(frame.right_foot, right_geometry),
    ],
    profile.mass_model.mass_kg * @moonphys.lunar_environment().gravity_mps2,
  )
  let left_patch = contact_patch(field, frame.left_foot, left_geometry)
  let right_patch = contact_patch(field, frame.right_foot, right_geometry)
  let left_wrench = @moonphys.contact_patch_wrench_assessment(
    @moonphys.contact_patch_load_assessment(
      left_patch,
      support_load_normal_force(load, left_geometry.foot_id),
    ),
    center_of_mass,
    left_patch.average_surface_normal,
  )
  let right_wrench = @moonphys.contact_patch_wrench_assessment(
    @moonphys.contact_patch_load_assessment(
      right_patch,
      support_load_normal_force(load, right_geometry.foot_id),
    ),
    center_of_mass,
    right_patch.average_surface_normal,
  )
  [left_wrench, right_wrench]
}

///|
fn support_contact_torque(
  wrenches : Array[@moonphys.ContactPatchWrenchAssessment],
) -> @moonphys.Vec3 {
  let mut torque = @moonphys.vec3(0.0, 0.0, 0.0)
  for wrench in wrenches {
    torque = torque.add(wrench.total_torque_nm)
  }
  torque
}

///|
fn support_contact_force(
  wrenches : Array[@moonphys.ContactPatchWrenchAssessment],
) -> @moonphys.Vec3 {
  let mut force = @moonphys.vec3(0.0, 0.0, 0.0)
  for wrench in wrenches {
    force = force.add(wrench.total_force_n)
  }
  force
}

///|
fn support_wrench_motion_step(
  profile : NoetixPhysicsProfile,
  center_of_mass : @moonphys.Vec3,
  body_velocity : @moonphys.Vec3,
  inertia : @moonphys.RigidBodyInertia,
  support_wrenches : Array[@moonphys.ContactPatchWrenchAssessment],
  dt_s : Double,
) -> @moonphys.RigidBodyWrenchStep {
  @moonphys.integrate_rigid_body_wrench(
    @moonphys.rigid_body_motion_state(
      "\{profile.robot_id}/support-wrench-review-body",
      profile.mass_model.mass_kg,
      0.0,
      center_of_mass,
      body_velocity,
      @moonphys.identity_basis3(),
      @moonphys.vec3(0.0, 0.0, 0.0),
    ),
    inertia,
    @moonphys.rigid_body_wrench(
      support_contact_force(support_wrenches),
      support_contact_torque(support_wrenches),
    ),
    dt_s,
  )
}

///|
fn self_contact_manifold(
  frame_index : Int,
  shapes : Array[NoetixCollisionShapeEvidence],
) -> @moonphys.CollisionContactManifold {
  let contacts : Array[@moonphys.CollisionContact] = []
  for i in 0..<shapes.length() {
    for j in (i + 1)..<shapes.length() {
      contacts.push(
        @moonphys.collision_pair_contact(
          shapes[i].shape,
          shapes[i].transform,
          shapes[j].shape,
          shapes[j].transform,
        ),
      )
    }
  }
  @moonphys.collision_contact_manifold(
    "noetix-e1/self-collision/frame-\{frame_index}",
    contacts,
  )
}

///|
fn self_contact_resolution(
  profile : NoetixPhysicsProfile,
  center_of_mass : @moonphys.Vec3,
  body_velocity : @moonphys.Vec3,
  manifold : @moonphys.CollisionContactManifold,
) -> @moonphys.CollisionManifoldResolution {
  @moonphys.resolve_collision_manifold(
    @moonphys.rigid_body_state(
      "\{profile.robot_id}/self-contact-review-body",
      profile.mass_model.mass_kg,
      0.0,
      center_of_mass,
      body_velocity,
    ),
    manifold,
    @moonphys.lunar_regolith_contact_model(),
  )
}

///|
fn noetix_self_contact_world_body(
  profile : NoetixPhysicsProfile,
  shape : NoetixCollisionShapeEvidence,
  shape_count : Int,
  volume_sum : Double,
  body_velocity : @moonphys.Vec3,
) -> @moonphys.RigidBodyWorldBody {
  @moonphys.rigid_body_world_body(
    @moonphys.rigid_body_state(
      "\{profile.robot_id}/\{shape.link_name}/\{shape.shape.shape_id}",
      noetix_assumed_shape_mass(
        profile.mass_model.mass_kg,
        shape,
        shape_count,
        volume_sum,
      ),
      @moonphys.collision_bounding_radius(shape.shape),
      shape.transform.translation,
      body_velocity,
    ),
    collision_shape=shape.shape,
  )
}

///|
fn self_contact_world_resolution(
  field : @moonphys.Heightfield,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
  shapes : Array[NoetixCollisionShapeEvidence],
  body_velocity : @moonphys.Vec3,
) -> @moonphys.RigidBodyWorldContactResolution {
  let volume_sum = collision_shape_volume_sum(shapes)
  let bodies : Array[@moonphys.RigidBodyWorldBody] = []
  for shape in shapes {
    bodies.push(
      noetix_self_contact_world_body(
        profile,
        shape,
        shapes.length(),
        volume_sum,
        body_velocity,
      ),
    )
  }
  let world = @moonphys.rigid_body_heightfield_world(
    "\{profile.robot_id}/self-contact-world/frame-\{frame_index}",
    field,
    @moonphys.lunar_regolith_contact_model(),
    @moonphys.lunar_environment(),
    bodies,
  )
  @moonphys.rigid_body_world_resolve_contacts(
    world,
    @moonphys.rigid_body_world_contact_schedule(world),
  )
}

///|
fn noetix_self_contact_world_response(
  resolution : @moonphys.RigidBodyWorldContactResolution,
) -> NoetixSelfContactWorldResponse {
  let resolved_pairs : Array[NoetixSelfContactWorldPairResponse] = []
  let mut max_correction = 0.0
  for pair in resolution.resolutions {
    if pair.status == "world-pair-resolved" {
      let correction_a = pair.correction_a.length()
      let correction_b = pair.correction_b.length()
      if correction_a > max_correction {
        max_correction = correction_a
      }
      if correction_b > max_correction {
        max_correction = correction_b
      }
      resolved_pairs.push({
        body_a_id: pair.body_a_id,
        body_b_id: pair.body_b_id,
        contact_status: pair.contact.status,
        correction_a_m: correction_a,
        correction_b_m: correction_b,
        normal_impulse_ns: pair.normal_impulse_ns,
        friction_impulse_ns: pair.friction_impulse_ns,
        status: pair.status,
      })
    }
  }
  {
    world_id: resolution.world_id,
    pair_count: resolution.schedule.pair_count,
    broadphase_overlap_count: resolution.schedule.broadphase_overlap_count,
    contact_count: resolution.schedule.contact_count,
    resolved_contact_count: resolution.resolved_contact_count,
    max_pair_correction_m: max_correction,
    normal_impulse_ns: resolution.normal_impulse_ns,
    friction_impulse_ns: resolution.friction_impulse_ns,
    resolved_pairs,
    status: resolution.status,
  }
}

///|
fn noetix_review_body_velocity(
  config : NoetixMoonWalkConfig,
  frame : NoetixMoonWalkFrame,
) -> @moonphys.Vec3 {
  let lateral_direction = if frame.support_phase == "left-support" {
    1.0
  } else {
    0.0 - 1.0
  }
  let half_cycle_s = config.dt_s * config.cycle_frames.to_double() * 0.5
  let lateral_speed = if half_cycle_s > 0.0 {
    config.lateral_foot_offset_m / half_cycle_s
  } else {
    0.0
  }
  noetix_heading_forward(config)
  .scale(config.speed_mps)
  .add(noetix_heading_lateral(config).scale(lateral_direction * lateral_speed))
}

///|
fn inertial_collision_frame_status(
  terrain_review_count : Int,
  self_contact_count : Int,
) -> String {
  if terrain_review_count > 0 {
    "terrain-collision-review"
  } else if self_contact_count > 0 {
    "self-collision-review"
  } else {
    "collision-clear-review"
  }
}

///|
pub fn noetix_inertial_collision_frame(
  field : @moonphys.Heightfield,
  walk_frame : NoetixMoonWalkFrame,
  pose_frame : NoetixLinkPoseFrame,
  profile : NoetixPhysicsProfile,
  body_velocity? : @moonphys.Vec3 = @moonphys.vec3(
    default_noetix_moon_walk_config().speed_mps,
    0.0,
    0.0,
  ),
  dt_s? : Double = default_noetix_moon_walk_config().dt_s,
) -> NoetixInertialCollisionFrame {
  let shapes : Array[NoetixCollisionShapeEvidence] = []
  for collision in profile.collision_shapes {
    shapes.push(collision_shape_evidence(pose_frame, collision))
  }
  let mass_properties = noetix_assumed_mass_properties(profile, shapes)
  let center_of_mass = mass_properties.center_of_mass
  let inertia = mass_properties.inertia_about_center
  let terrain_collisions : Array[NoetixTerrainCollisionEvidence] = []
  terrain_collisions.push(
    terrain_collision_evidence(field, walk_frame, profile, "left_foot"),
  )
  terrain_collisions.push(
    terrain_collision_evidence(field, walk_frame, profile, "right_foot"),
  )
  let mut terrain_contact_count = 0
  let mut terrain_review_count = 0
  for terrain in terrain_collisions {
    if terrain.collision.in_contact {
      terrain_contact_count += 1
    }
    if terrain.status != "terrain-collision-matches-walk-contact" {
      terrain_review_count += 1
    }
  }
  let manifold = self_contact_manifold(walk_frame.frame_index, shapes)
  let resolution = self_contact_resolution(
    profile, center_of_mass, body_velocity, manifold,
  )
  let world_resolution = self_contact_world_resolution(
    field,
    walk_frame.frame_index,
    profile,
    shapes,
    body_velocity,
  )
  let world_response = noetix_self_contact_world_response(world_resolution)
  let world_correction = world_response.max_pair_correction_m
  let support_wrenches = support_contact_wrenches(
    field, walk_frame, profile, center_of_mass,
  )
  let motion_step = support_wrench_motion_step(
    profile, center_of_mass, body_velocity, inertia, support_wrenches, dt_s,
  )
  {
    frame_index: walk_frame.frame_index,
    time_s: walk_frame.time_s,
    support_phase: walk_frame.support_phase,
    center_of_mass,
    inertia,
    mass_properties,
    support_contact_torque_nm: support_contact_torque(support_wrenches),
    support_contact_wrenches: support_wrenches,
    support_wrench_motion_step: motion_step,
    shape_count: shapes.length(),
    terrain_contact_count,
    terrain_review_count,
    self_contact_manifold: manifold,
    self_contact_resolution: resolution,
    self_contact_world_response: world_response,
    self_contact_correction_m: vec_length(resolution.correction),
    self_contact_world_correction_m: world_correction,
    shapes,
    terrain_collisions,
    status: inertial_collision_frame_status(
      terrain_review_count,
      manifold.contact_count,
    ),
  }
}

///|
pub fn noetix_inertial_collision_report(
  trace : NoetixMoonWalkTrace,
  field : @moonphys.Heightfield,
  profile? : NoetixPhysicsProfile = default_noetix_physics_profile(),
) -> NoetixInertialCollisionReport {
  let pose_trace = noetix_link_pose_trace(trace)
  let frames : Array[NoetixInertialCollisionFrame] = []
  let mut self_contact_frame_count = 0
  let mut terrain_review_frame_count = 0
  let mut max_self_penetration = 0.0
  let mut max_self_contact_correction = 0.0
  let mut max_self_contact_world_correction = 0.0
  let mut max_self_contact_normal_impulse = 0.0
  let mut max_self_contact_friction_impulse = 0.0
  let mut max_torque = 0.0
  let mut shapes_per_frame = 0
  for index, frame in trace.frames {
    let evidence = noetix_inertial_collision_frame(
      field,
      frame,
      pose_trace.frames[index],
      profile,
      body_velocity=noetix_review_body_velocity(trace.config, frame),
      dt_s=trace.config.dt_s,
    )
    if evidence.self_contact_manifold.contact_count > 0 {
      self_contact_frame_count += 1
    }
    if evidence.terrain_review_count > 0 {
      terrain_review_frame_count += 1
    }
    if evidence.self_contact_manifold.max_penetration_m > max_self_penetration {
      max_self_penetration = evidence.self_contact_manifold.max_penetration_m
    }
    if evidence.self_contact_correction_m > max_self_contact_correction {
      max_self_contact_correction = evidence.self_contact_correction_m
    }
    if evidence.self_contact_world_correction_m >
      max_self_contact_world_correction {
      max_self_contact_world_correction = evidence.self_contact_world_correction_m
    }
    if evidence.self_contact_resolution.normal_impulse_ns >
      max_self_contact_normal_impulse {
      max_self_contact_normal_impulse = evidence.self_contact_resolution.normal_impulse_ns
    }
    if evidence.self_contact_resolution.friction_impulse_ns >
      max_self_contact_friction_impulse {
      max_self_contact_friction_impulse = evidence.self_contact_resolution.friction_impulse_ns
    }
    let torque = vec_length(evidence.support_contact_torque_nm)
    if torque > max_torque {
      max_torque = torque
    }
    if index == 0 {
      shapes_per_frame = evidence.shape_count
    }
    frames.push(evidence)
  }
  {
    report_id: "moonrobo/noetix-e1/inertial-collision/\{trace.terrain_tile_id}",
    trace_id: trace.trace_id,
    profile,
    frame_count: frames.length(),
    shapes_per_frame,
    self_contact_frame_count,
    terrain_review_frame_count,
    max_self_penetration_m: max_self_penetration,
    max_self_contact_correction_m: max_self_contact_correction,
    max_self_contact_world_correction_m: max_self_contact_world_correction,
    max_self_contact_normal_impulse_ns: max_self_contact_normal_impulse,
    max_self_contact_friction_impulse_ns: max_self_contact_friction_impulse,
    max_support_contact_torque_nm: max_torque,
    frames,
    hardware_authority: profile.hardware_authority,
    status: if terrain_review_frame_count > 0 {
      "inertial-collision-terrain-review"
    } else if self_contact_frame_count > 0 {
      "inertial-collision-self-review"
    } else {
      "inertial-collision-assumption-review"
    },
    note: "Inertial/collision evidence maps the Noetix review profile onto Moonphys composite primitive-shape mass properties, collision bounds, terrain collisions, patch-load contact wrench torque, support-wrench motion preview with impulse and kinetic-energy accounting, narrow-phase self-collision manifolds, generic manifold resolution, Moonphys world body-pair contact response, and impulse accounting. It remains review evidence only because mass, inertia, and collision geometry are not authoritative Moonrobo URDF tags yet.",
  }
}

///|
pub fn first_trusted_square_noetix_inertial_collision_report() -> NoetixInertialCollisionReport {
  let field = first_trusted_square_noetix_heightfield()
  noetix_inertial_collision_report(noetix_moon_walk_trace(field, 32), field)
}

///|
pub fn first_trusted_square_noetix_inertial_collision_json() -> Json {
  first_trusted_square_noetix_inertial_collision_report().to_json()
}

///|
pub fn render_noetix_inertial_collision_markdown(
  report : NoetixInertialCollisionReport,
) -> String {
  let mut text = "# Noetix Inertial Collision Evidence\n\n"
  text += "- report: \{report.report_id}\n"
  text += "- trace: \{report.trace_id}\n"
  text += "- profile: \{report.profile.profile_id}\n"
  text += "- mass: \{report.profile.mass_model.mass_kg} kg\n"
  text += "- frames: \{report.frame_count}\n"
  text += "- shapes per frame: \{report.shapes_per_frame}\n"
  text += "- self-contact frames: \{report.self_contact_frame_count}\n"
  text += "- terrain-review frames: \{report.terrain_review_frame_count}\n"
  text += "- max self penetration: \{report.max_self_penetration_m} m\n"
  text += "- max self-contact correction: \{report.max_self_contact_correction_m} m\n"
  text += "- max self-contact world correction: \{report.max_self_contact_world_correction_m} m\n"
  text += "- max self-contact normal impulse: \{report.max_self_contact_normal_impulse_ns} Ns\n"
  text += "- max self-contact friction impulse: \{report.max_self_contact_friction_impulse_ns} Ns\n"
  text += "- max support contact torque: \{report.max_support_contact_torque_nm} Nm\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Collision Summary\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} shapes=\{frame.shape_count} terrain_contacts=\{frame.terrain_contact_count} self_contacts=\{frame.self_contact_manifold.contact_count} status=\{frame.status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_inertial_collision_markdown() -> String {
  render_noetix_inertial_collision_markdown(
    first_trusted_square_noetix_inertial_collision_report(),
  )
}
