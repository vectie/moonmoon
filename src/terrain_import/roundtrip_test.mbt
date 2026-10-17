///|
test "roundtrip combines directional costs and retains exact ordered legs" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let study = @terrain_import.roundtrip_bundle(source, 0, 0, 45.0, 2.0, 80.0)
  let cell = at(study, "cells", 2)
  assert_eq(num(cell, "outbound_cost_m_equivalent"), 60.0)
  assert_eq(num(cell, "return_cost_m_equivalent"), 20.0)
  assert_eq(num(cell, "combined_cost_m_equivalent"), 80.0)
  assert_eq(field(cell, "status"), "within-budget".to_json())
  let selection = @terrain_import.roundtrip_path_bundle(study.stringify(), 0, 2)
  let outbound = field(selection, "outbound_route")
  let returning = field(selection, "return_route")
  assert_eq(field(outbound, "path_cells_text"), "0,0\n0,1\n0,2\n".to_json())
  assert_eq(field(returning, "path_cells_text"), "0,2\n0,1\n0,0\n".to_json())
  assert_eq(num(field(outbound, "summary"), "objective_cost_m"), 60.0)
  assert_eq(num(field(returning, "summary"), "objective_cost_m"), 20.0)
  assert_eq(field(selection, "physical_readiness"), false.to_json())
  let too_small = @terrain_import.roundtrip_bundle(
    source, 0, 0, 45.0, 2.0, 79.0,
  )
  assert_true(
    (try? @terrain_import.roundtrip_path_bundle(too_small.stringify(), 0, 2))
    is Err(_),
  )
  let downhill = @terrain_import.roundtrip_bundle(source, 0, 2, 45.0, 2.0, 80.0)
  assert_eq(num(at(downhill, "cells", 0), "outbound_cost_m_equivalent"), 20.0)
  assert_eq(num(at(downhill, "cells", 0), "return_cost_m_equivalent"), 60.0)
}

///|
test "roundtrip unknown disconnected zero budget and grade limits stay distinct" {
  let source = bundle(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 -9999 0",
  )
  let study = @terrain_import.roundtrip_bundle(source, 0, 0, 45.0, 0.0, 0.0)
  assert_eq(field(at(study, "cells", 0), "status"), "within-budget".to_json())
  assert_eq(field(at(study, "cells", 1), "status"), "over-budget".to_json())
  assert_eq(field(at(study, "cells", 2), "status"), "unknown".to_json())
  assert_eq(
    field(at(study, "cells", 3), "status"),
    "not-connected-in-model".to_json(),
  )
  assert_true(
    (try? @terrain_import.roundtrip_path_bundle(study.stringify(), 0, 2))
    is Err(_),
  )
  assert_true(
    (try? @terrain_import.roundtrip_path_bundle(study.stringify(), 0, 3))
    is Err(_),
  )
  let same = @terrain_import.roundtrip_path_bundle(study.stringify(), 0, 0)
  assert_eq(num(same, "combined_cost_m_equivalent"), 0.0)
  let blocked = @terrain_import.roundtrip_bundle(source, 0, 0, 44.0, 0.0, 100.0)
  assert_eq(
    field(at(blocked, "cells", 1), "status"),
    "not-connected-in-model".to_json(),
  )
}

///|
test "roundtrip costs agree with endpoint routing through detours" {
  let source = bundle(
    "ncols 4 nrows 3 xllcenter 0 yllcenter 0 cellsize 10\n0 2 3 4\n0 -9999 50 5\n0 0 0 0",
  )
  let study = @terrain_import.roundtrip_bundle(source, 1, 0, 40.0, 3.0, 1000.0)
  for row in 0..<3 {
    for col in 0..<4 {
      if field(at(study, "cells", row * 4 + col), "status") !=
        "within-budget".to_json() {
        continue
      }
      let out = @terrain_import.route_bundle(source, 1, 0, row, col, 40.0, 3.0)
      let back = @terrain_import.route_bundle(source, row, col, 1, 0, 40.0, 3.0)
      let a = num(field(out, "summary"), "objective_cost_m")
      let b = num(field(back, "summary"), "objective_cost_m")
      assert_eq(
        num(at(study, "cells", row * 4 + col), "combined_cost_m_equivalent"),
        a + b,
      )
      let selection = @terrain_import.roundtrip_path_bundle(
        study.stringify(),
        row,
        col,
      )
      assert_eq(
        num(
          field(field(selection, "return_route"), "summary"),
          "objective_cost_m",
        ),
        b,
      )
    }
  }
}

///|
test "roundtrip saved source assumptions and result tampering are rejected" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0")
  let study = @terrain_import.roundtrip_bundle(source, 0, 0, 0.0, 0.0, 20.0)
  let text = study.stringify()
  for
    (old, replacement) in [
      ("\"budget_m_equivalent\":20", "\"budget_m_equivalent\":21"),
      ("\"combined_cost_m_equivalent\":20", "\"combined_cost_m_equivalent\":19"),
      ("moonmoon.terrain-roundtrip.v1", "moonmoon.terrain-roundtrip.v2"),
    ] {
    let changed = text.replace(old~, new=replacement)
    assert_true(changed != text)
    assert_true(
      (try? @terrain_import.roundtrip_path_bundle(changed, 0, 1)) is Err(_),
    )
  }
  assert_true(
    (try? @terrain_import.roundtrip_bundle(source, 0, 0, 0.0, 0.0, -1.0))
    is Err(_),
  )
  assert_true(
    (try? @terrain_import.roundtrip_path_bundle("{}", 0, 1)) is Err(_),
  )
  assert_true(
    (try? @terrain_import.roundtrip_path_bundle(text, 0, 2)) is Err(_),
  )
}

///|
test "roundtrip supports full bounded grid and rejects combined overflow" {
  let row = Array::make(64, "0").join(" ")
  let source = bundle(
    "ncols 64 nrows 64 xllcenter 0 yllcenter 0 cellsize 1\n" +
    Array::make(64, row).join("\n"),
  )
  let study = @terrain_import.roundtrip_bundle(source, 0, 0, 0.0, 0.0, 252.0)
  assert_eq(num(field(study, "summary"), "within_budget_cells"), 4096.0)
  assert_eq(num(at(study, "cells", 4095), "combined_cost_m_equivalent"), 252.0)
  let huge = bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 1 0")
  assert_true(
    (try? @terrain_import.roundtrip_bundle(huge, 0, 0, 45.0, 1.0e308, 1.0))
    is Err(_),
  )
}
