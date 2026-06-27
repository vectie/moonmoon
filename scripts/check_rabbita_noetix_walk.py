#!/usr/bin/env python3
"""Verify Rabbita renders the Noetix walk trace surface."""

from __future__ import annotations

from rabbita_ui_harness import (
  assert_noetix_walk_panel,
  extract_json_script,
  read_rabbita_page,
  render_noetix_walk_panel,
)


def assert_page_source(html: str) -> None:
  if "Noetix Walk" not in html:
    raise AssertionError("missing Noetix Walk section")
  if "moonmoon-noetix-walk" not in html:
    raise AssertionError("missing embedded Noetix trace")
  if "moonmoon-noetix-link-poses" not in html:
    raise AssertionError("missing embedded Noetix link-pose trace")
  if "noetix-walk-viewer" not in html:
    raise AssertionError("missing Noetix viewer anchor")
  if "hardware" in html.split("noetix-walk-viewer", 1)[0].split("Noetix Walk", 1)[-1].lower():
    raise AssertionError("Noetix section must not expose hardware controls")


def main() -> int:
  html, view, book = read_rabbita_page()
  noetix_trace = extract_json_script(html, "moonmoon-noetix-walk")
  noetix_link_poses = extract_json_script(html, "moonmoon-noetix-link-poses")
  assert_page_source(html)
  rendered = render_noetix_walk_panel(view, book, noetix_trace, noetix_link_poses)
  assert_noetix_walk_panel(rendered, noetix_trace, noetix_link_poses)
  print("checked Rabbita Noetix walk")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
