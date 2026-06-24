# MoonSuite Exhibition Assets

This directory stores source image assets for the MoonSuite exhibition package.
Generated deliverables stay under `output/pdf/`.

## Files

- `moonsuite_lunar_ops_visual.png`
  Source AI-generated lunar operations visual used by
  `scripts/make_moonsuite_exhibition_pdf.py`.
- `archive/moonsuite_display_schematic_v1_20x30cm_300dpi.png`
  Earlier schematic display export, kept only for visual history.

## Rebuild

From the repository root:

```bash
PYTHON_BIN=/Users/kq/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
PDFTOPPM_BIN=/Users/kq/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/pdftoppm \
sh scripts/build_moonsuite_exhibition_assets.sh
```

On a machine with `python3`, `reportlab`, and `pdftoppm` on `PATH`, this is
enough:

```bash
sh scripts/build_moonsuite_exhibition_assets.sh
```

The PDF generator embeds a local Chinese font. On macOS it defaults to:

```text
/System/Library/Fonts/STHeiti Medium.ttc
```

Set `MOONSUITE_EXHIBITION_FONT=/path/to/font.ttf` if that font is not available.

## Reproducibility Check

`scripts/make_moonsuite_exhibition_pdf.py` uses ReportLab invariant mode. With
the bundled Codex runtime used during generation, two consecutive rebuilds
produced identical SHA-256 hashes:

```text
483fb246484166b573c354795bb17d0e037df2674e7591bb954275b148b13c13  output/pdf/moonsuite_exhibition_profile.pdf
518551d840cdee74fc0fceeb41d1e68fd431aaec1b2aa8568a58e5a90b4813bc  output/pdf/moonsuite_display_generated_20x30cm_300dpi-6.png
```

## Image Generation Provenance

The source visual was generated from this prompt direction:

```text
Create a cinematic, premium portrait exhibition visual showing a human operator
command station on Earth sending verified blue data beams to autonomous robots
on the Moon, with a luminous lunar digital twin hovering above the surface and
abstract agent-system nodes orbiting it. Communicate an agentic operating
system bridging digital world, physical robotics, and lunar operations. Use
deep navy space, cyan/blue data glow, lunar silver, subtle amber robot lights,
and leave space for PDF text overlay. No logos, no watermark, no random text.
```
