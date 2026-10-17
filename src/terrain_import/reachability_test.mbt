///|
test "reachability separates budget boundary disconnected and unknown destinations" {
  let source = bundle(
    "ncols 5 nrows 2 xllcenter 100 yllcenter 200 cellsize 10\n0 0 -9999 0 0\n0 0 -9999 0 0",
  )
  let result = @terrain_import.reachability_bundle(source, 0, 0, 0.0, 0.0, 10.0)
  let summary = field(result, "summary")
  assert_eq(num(summary, "within_budget_cells"), 3.0)
  assert_eq(num(summary, "over_budget_cells"), 1.0)
  assert_eq(num(summary, "not_connected_cells"), 4.0)
  assert_eq(num(summary, "unknown_cells"), 2.0)
  assert_eq(field(at(result, "cells", 1), "status"), "within-budget".to_json())
  assert_eq(num(at(result, "cells", 1), "minimum_cost_m_equivalent"), 10.0)
  assert_eq(num(at(result, "cells", 6), "remaining_budget_m_equivalent"), -10.0)
  assert_eq(
    field(at(result, "cells", 2), "minimum_cost_m_equivalent"),
    Json::null(),
  )
  assert_eq(
    field(at(result, "cells", 3), "minimum_cost_m_equivalent"),
    Json::null(),
  )
  assert_eq(num(at(result, "cells", 0), "x_m"), 100.0)
  assert_eq(num(at(result, "cells", 0), "y_m"), 210.0)
  assert_eq(field(at(result, "cells", 0), "predecessor"), Json::null())
  assert_eq(field(result, "physical_readiness"), false.to_json())
  assert_eq(
    result,
    @terrain_import.reachability_bundle(source, 0, 0, 0.0, 0.0, 10.0),
  )
}

///|
test "one way reachability uses directional uphill cost and zero budget keeps only start" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let up = @terrain_import.reachability_bundle(source, 0, 0, 45.0, 2.0, 30.0)
  let down = @terrain_import.reachability_bundle(source, 0, 2, 45.0, 2.0, 30.0)
  assert_eq(num(field(up, "summary"), "within_budget_cells"), 2.0)
  assert_eq(num(at(up, "cells", 2), "minimum_cost_m_equivalent"), 60.0)
  assert_eq(num(field(down, "summary"), "within_budget_cells"), 3.0)
  assert_eq(num(at(down, "cells", 0), "minimum_cost_m_equivalent"), 20.0)
  let zero = @terrain_import.reachability_bundle(source, 0, 0, 45.0, 0.0, 0.0)
  assert_eq(num(field(zero, "summary"), "within_budget_cells"), 1.0)
  let blocked = @terrain_import.reachability_bundle(
    source, 0, 0, 44.0, 0.0, 100.0,
  )
  assert_eq(num(field(blocked, "summary"), "not_connected_cells"), 2.0)
}

///|
test "reachability all destination costs and selected paths match endpoint routing" {
  let source = bundle(detour)
  let result = @terrain_import.reachability_bundle(
    source, 2, 0, 60.0, 4.0, 100.0,
  )
  for row in 0..<5 {
    for col in 0..<7 {
      if row == 3 && col == 2 {
        continue
      }
      let route = @terrain_import.route_bundle(
        source, 2, 0, row, col, 60.0, 4.0,
      )
      let cost = num(field(route, "summary"), "objective_cost_m")
      assert_eq(
        num(at(result, "cells", row * 7 + col), "minimum_cost_m_equivalent"),
        cost,
      )
      if cost <= 100.0 {
        let selected = @terrain_import.reachability_path_bundle(
          result.stringify(),
          row,
          col,
        )
        assert_eq(field(selected, "route"), route)
        assert_eq(
          field(selected, "reachability_digest"),
          field(result, "reachability_digest"),
        )
      }
    }
  }
  let chosen = @terrain_import.reachability_path_bundle(
    result.stringify(indent=2),
    2,
    6,
  )
  assert_eq(num(chosen, "minimum_cost_m_equivalent"), 100.0)
  assert_eq(num(field(field(chosen, "route"), "summary"), "ascent_m"), 0.0)
}

///|
test "selected reach path feeds exact path and corridor assessment without source changes" {
  let source = bundle(detour)
  let result = @terrain_import.reachability_bundle(
    source, 2, 0, 20.0, 0.0, 100.0,
  )
  let selected = @terrain_import.reachability_path_bundle(
    result.stringify(),
    2,
    6,
  )
  let route = field(selected, "route")
  let path = mesh_text(route, "path_cells_text")
  let assessment = @terrain_import.assess_path_bundle(source, path, 20.0, 0.0)
  assert_eq(field(assessment, "coverage_complete"), true.to_json())
  let corridor = @terrain_import.assess_corridor_bundle(
    source, path, 1, 30.0, 5.0,
  )
  assert_eq(field(corridor, "physical_readiness"), false.to_json())
  assert_eq(
    field(route, "source_bundle"),
    @terrain_import.reopen_bundle(source),
  )
  assert_eq(
    field(result, "source_bundle"),
    @terrain_import.reopen_bundle(source),
  )
}

///|
test "reach path refuses unknown disconnected over budget out of bounds and changed exploration" {
  let source = bundle(
    "ncols 5 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 0 -9999 0",
  )
  let result = @terrain_import.reachability_bundle(source, 0, 0, 0.0, 0.0, 10.0)
  for (row, col) in [(0, 2), (0, 3), (0, 4), (-1, 0), (0, 5)] {
    assert_true(
      (try? @terrain_import.reachability_path_bundle(
        result.stringify(),
        row,
        col,
      ))
      is Err(_),
    )
  }
  let saved = result.stringify()
  for
    changed in [
      saved.replace(
        old="\"budget_m_equivalent\":10",
        new="\"budget_m_equivalent\":20",
      ),
      saved.replace(
        old="\"minimum_cost_m_equivalent\":10",
        new="\"minimum_cost_m_equivalent\":9",
      ),
      saved.replace(
        old="\"physical_readiness\":false",
        new="\"physical_readiness\":true",
      ),
      saved.replace(old="\"start_row\":0", new="\"start_row\":0.5"),
      "{}",
      "not JSON",
    ] {
    assert_true(
      (try? @terrain_import.reachability_path_bundle(changed, 0, 1)) is Err(_),
    )
  }
  assert_eq(
    num(
      @terrain_import.reachability_path_bundle(saved, 0, 0),
      "minimum_cost_m_equivalent",
    ),
    0.0,
  )
}

///|
test "reachability rejects invalid budget units start grade and overflowing costs" {
  let text = "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10"
  let source = bundle(text)
  for
    (row, col, grade, weight, budget) in [
      (-1, 0, 45.0, 0.0, 10.0),
      (0, 2, 45.0, 0.0, 10.0),
      (0, 0, 90.0, 0.0, 10.0),
      (0, 0, 45.0, -1.0, 10.0),
      (0, 0, 45.0, 0.0, -1.0),
      (0, 0, 45.0, 0.0, 1.0 / 0.0),
      (0, 0, 45.0, 0.0, 0.0 / 0.0),
      (0, 0, 45.0, 1.0e308, 10.0),
    ] {
    assert_true(
      (try? @terrain_import.reachability_bundle(
        source, row, col, grade, weight, budget,
      ))
      is Err(_),
    )
  }
  assert_true(
    (try? @terrain_import.reachability_bundle(
      bundle(text, unit="degrees"),
      0,
      0,
      45.0,
      0.0,
      10.0,
    ))
    is Err(_),
  )
  assert_true(
    (try? @terrain_import.reachability_bundle(
      bundle(text.replace(old="0 10", new="-9999 10")),
      0,
      0,
      45.0,
      0.0,
      10.0,
    ))
    is Err(_),
  )
}

///|
test "maximum reachability grid uses inclusive Manhattan budget with bounded map" {
  let text = "ncols 64 nrows 64 xllcenter 0 yllcenter 0 cellsize 1\n" +
    Array::make(4096, "0").join(" ")
  let result = @terrain_import.reachability_bundle(
    bundle(text),
    0,
    0,
    0.0,
    0.0,
    63.0,
  )
  assert_eq(num(field(result, "summary"), "within_budget_cells"), 2080.0)
  assert_eq(num(field(result, "summary"), "over_budget_cells"), 2016.0)
  assert_eq(num(at(result, "cells", 4095), "minimum_cost_m_equivalent"), 126.0)
  assert_true(
    mesh_text(result, "reachability_svg").contains("Not connected in model"),
  )
  assert_true(result.stringify(indent=2).length() < 8388608)
}

///|
test "changed assumptions or terrain revisions create distinct explorations" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0")
  let before = @terrain_import.reachability_bundle(
    source, 0, 0, 20.0, 1.0, 10.0,
  )
  let after = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n0,1,0,10\n", "Synthetic obstacle for exploration",
  )
  let revised = @terrain_import.reachability_bundle(
    after.stringify(),
    0,
    0,
    20.0,
    1.0,
    10.0,
  )
  let more = @terrain_import.reachability_bundle(source, 0, 0, 20.0, 1.0, 20.0)
  assert_true(
    field(before, "reachability_digest") !=
    field(revised, "reachability_digest"),
  )
  assert_true(
    field(before, "reachability_digest") != field(more, "reachability_digest"),
  )
  assert_eq(num(field(revised, "summary"), "not_connected_cells"), 1.0)
  assert_eq(
    num(
      @terrain_import.reachability_path_bundle(before.stringify(), 0, 1),
      "minimum_cost_m_equivalent",
    ),
    10.0,
  )
}
