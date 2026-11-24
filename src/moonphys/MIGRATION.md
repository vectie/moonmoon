# MoonPhys compatibility package

The physical implementation and its complete tests have moved to the independent,
unpublished `vectie/moonphys@0.1.0` module at the sibling `../moonphys` checkout.
This package and `review/` contain generated `pub using` facades only. All original
public functions and types remain available; methods resolve through their
canonical public owners. Geometry types now belong to `vectie/moonnum/geometry`.
Use `@moonphys.CollisionShapeKind::SphereShape` (or a context-inferred constructor)
in place of the enum's old short `@moonphys.SphereShape` spelling; MoonBit type
re-exports retain enum cases through the type-qualified form.

The original source files and interfaces were preserved byte-for-byte with
SHA-256 hashes under `../moonphys/docs/provenance/moonmoon-moonphys-20261023/`.
See `../moonphys/MIGRATION.md` for the extraction mapping and deferred validation.
These paths are relative to the MoonMoon repository root, not this file.

The extraction tool is `scripts/extract_moonphys.mbtx`. To regenerate only the
compatibility declarations from the archived original interfaces, run from the
MoonMoon repository root:

```sh
moon run --target native scripts/extract_moonphys.mbtx -- refresh-facades /ABSOLUTE/moonmoon /ABSOLUTE/moonphys
moon info src/moonphys src/moonphys/review
moon fmt src/moonphys src/moonphys/review
```

The original `extract` mode refuses to overwrite an existing archive. Maintain
physics exclusively in the canonical module. Test execution remains deferred.
