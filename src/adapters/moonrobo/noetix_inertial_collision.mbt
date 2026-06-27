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
pub(all) struct NoetixInertialCollisionFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  center_of_mass : @moonphys.Vec3
  inertia : @moonphys.RigidBodyInertia
  support_contact_torque_nm : @moonphys.Vec3
  shape_count : Int
  terrain_contact_count : Int
  terrain_review_count : Int
  self_contact_manifold : @moonphys.CollisionContactManifold
  self_contact_resolution : @moonphys.CollisionManifoldResolution
  self_contact_correction_m : Double
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
fn noetix_assumed_body_inertia(
  profile : NoetixPhysicsProfile,
) -> @moonphys.RigidBodyInertia {
  let mass = profile.mass_model.mass_kg
  @moonphys.rigid_body_inertia(
    "\{profile.robot_id}/assumed-diagonal-inertia",
    @moonphys.vec3(mass * 0.18 * 0.18, mass * 0.20 * 0.20, mass * 0.14 * 0.14),
  )
}

///|
fn frame_center_of_mass(
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
) -> @moonphys.Vec3 {
  @moonphys.vec3(
    frame.body_position.x + profile.mass_model.com_x_offset_m,
    frame.body_position.y + profile.mass_model.com_y_offset_m,
    frame.body_position.z,
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
fn support_contact_torque(
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
  center_of_mass : @moonphys.Vec3,
) -> @moonphys.Vec3 {
  let mut support_count = 0
  if frame.left_foot.in_contact {
    support_count += 1
  }
  if frame.right_foot.in_contact {
    support_count += 1
  }
  if support_count == 0 {
    return @moonphys.vec3(0.0, 0.0, 0.0)
  }
  let normal_force = profile.mass_model.mass_kg *
    @moonphys.lunar_environment().gravity_mps2 /
    support_count.to_double()
  let force = @moonphys.vec3(0.0, 0.0, normal_force)
  let mut torque = @moonphys.vec3(0.0, 0.0, 0.0)
  if frame.left_foot.in_contact {
    torque = torque.add(
      @moonphys.contact_torque(center_of_mass, frame.left_foot.position, force),
    )
  }
  if frame.right_foot.in_contact {
    torque = torque.add(
      @moonphys.contact_torque(center_of_mass, frame.right_foot.position, force),
    )
  }
  torque
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
) -> NoetixInertialCollisionFrame {
  let center_of_mass = frame_center_of_mass(walk_frame, profile)
  let inertia = noetix_assumed_body_inertia(profile)
  let shapes : Array[NoetixCollisionShapeEvidence] = []
  for collision in profile.collision_shapes {
    shapes.push(collision_shape_evidence(pose_frame, collision))
  }
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
  {
    frame_index: walk_frame.frame_index,
    time_s: walk_frame.time_s,
    support_phase: walk_frame.support_phase,
    center_of_mass,
    inertia,
    support_contact_torque_nm: support_contact_torque(
      walk_frame, profile, center_of_mass,
    ),
    shape_count: shapes.length(),
    terrain_contact_count,
    terrain_review_count,
    self_contact_manifold: manifold,
    self_contact_resolution: resolution,
    self_contact_correction_m: vec_length(resolution.correction),
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
    note: "Inertial/collision evidence maps the Noetix review profile onto Moonphys diagonal inertia, collision bounds, terrain collisions, contact torque, narrow-phase self-collision manifolds, generic manifold resolution, and impulse accounting. It remains review evidence only because mass, inertia, and collision geometry are not authoritative Moonrobo URDF tags yet.",
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
