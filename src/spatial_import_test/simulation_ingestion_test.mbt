///|
fn fixture() -> String raise {
  @fs.read_file_to_string(
    "src/spatial_import/testdata/simulation.portable.json",
  )
}

///|
fn ingest(
  text : String,
  parent? : String = "sha256:29ba21e38344f5e9cfcb47953c19b9a8e9023995fbba8951a9a5972e8f069c06",
) -> Result[
  @spatial_import.SimulationSpatialInput,
  @spatial_import.SimulationImportIssue,
] {
  @spatial_import.ingest_moonmold_simulation(
    text,
    expected_engineering_digest=parent,
  )
}

///|
test "MoonMoon accepts explicit simulation lineage scale frame and uncertainty" {
  match ingest(fixture()) {
    Ok(value) => {
      assert_eq(value.artifact_id, "arched-lunar-habitat:simulation-model")
      assert_eq(value.scale_to_meters, 0.001)
      assert_eq(value.up_axis, "z")
      assert_eq(value.handedness, "right")
      assert_true(value.assumptions.length() == 3)
      assert_true(value.declared_losses.length() == 2)
    }
    Err(problem) => fail("unexpected rejection: \{problem.code}")
  }
}

///|
test "MoonMoon rejects stale, styled, and physical-claim inputs" {
  match
    ingest(
      fixture(),
      parent="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ) {
    Err(problem) => assert_eq(problem.code, "stale-engineering-parent")
    Ok(_) => fail("expected stale rejection")
  }
  let styled = fixture()
    .replace(
      old="\"representation\":\"simulation-model\"",
      new="\"representation\":\"visual-styled-model\"",
    )
    .replace(
      old="\"child_representation\":\"simulation-model\"",
      new="\"child_representation\":\"visual-styled-model\"",
    )
  match ingest(styled) {
    Err(problem) => assert_eq(problem.code, "wrong-simulation-lane")
    Ok(_) => fail("expected styled rejection")
  }
  let physical = fixture().replace(
    old="\"claim_ceiling\":\"digital-artifact\"",
    new="\"claim_ceiling\":\"physical-readiness\"",
  )
  match ingest(physical) {
    Err(problem) => assert_eq(problem.code, "claim-ceiling-mismatch")
    Ok(_) => fail("expected claim rejection")
  }
  let premature_evidence = fixture().replace(
    old="\"claim_ceiling\":\"digital-artifact\"",
    new="\"claim_ceiling\":\"simulation-evidence\"",
  )
  match ingest(premature_evidence) {
    Err(problem) => assert_eq(problem.code, "claim-ceiling-mismatch")
    Ok(_) => fail("expected premature evidence rejection")
  }
}

///|
test "MoonMoon rejects missing uncertainty and unsupported scale" {
  let missing = fixture().replace(
    old="\"assumptions\":[\"unverified: structural wall composition\",\"unverified: measured mass\",\"unverified: pressure-vessel qualification\"]",
    new="\"assumptions\":[]",
  )
  match ingest(missing) {
    Err(problem) => assert_eq(problem.code, "missing-simulation-uncertainty")
    Ok(_) => fail("expected uncertainty rejection")
  }
  let scale = fixture().replace(
    old="\"units\":\"mm\"",
    new="\"units\":\"furlong\"",
  )
  match ingest(scale) {
    Err(problem) => assert_eq(problem.code, "unsupported-units")
    Ok(_) => fail("expected scale rejection")
  }
}
