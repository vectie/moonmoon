#!/usr/bin/env python3
"""Verify the complete materialized MoonBook workspace."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

import check_rabbita_transition_import
import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
ACCEPT_FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"


def run_current_workspace_check() -> None:
  subprocess.run(
    ["python3", "scripts/materialize_moonbook_workspace.py", "--check"],
    cwd=ROOT,
    check=True,
  )


def run_imported_workspace_check() -> None:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-workspace-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, ACCEPT_FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    workspace = tmp_root / "output/moonbook/workspaces/first-trusted-square"
    for required in [
      "index.json",
      "manifest.json",
      "review_transitions.json",
      "moonclaw/first-trusted-square/remediation-margin-task.json",
      "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json",
    ]:
      if not (workspace / required).exists():
        raise AssertionError(f"missing imported workspace file {required}")


def main() -> int:
  run_current_workspace_check()
  run_imported_workspace_check()
  print("checked MoonBook workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
