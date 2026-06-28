# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.1.0] - 2026-06-28

### Added
- `filletRadii: [Int: Double]` parameter on `buildPath` for per-corner fillet radii with
  individualized values. Key `1` is the first interior corner, key `0` is the closing corner
  of a closed path. Supersedes `filletRadius` when provided.
- DocC documentation catalog (`SVGLib.docc`) with a curated topic landing page.
- GitHub Actions workflow publishing API docs to GitHub Pages on every push to `main`.

## [1.0.0] - 2026-06-28

Initial release.

### Added
- `Point`, `Line`, `Circle`, `Arc`, `LineCoefficients` geometry types.
- Distance, midpoint, vector, and coordinate math utilities.
- Line operations: `lineIntersection`, `offsetLine`, `extendLine`, `lineCircleIntersections`, `commonTangents`.
- Arc utilities: `arcAngleDegrees`, `svgPointAtAngle`, `svgPtAtArcFraction`.
- Fillet helpers: `filletCenter` (line–line and line–arc), `areTangent`, `footOfPerpendicular`.
- `PathSegment` enum and `buildPath` with uniform fillet radius support.
- `arcPath` and `arcShape` for arc band shapes with optional rounded caps.
- SVG element generators: `svgCircle`, `svgLine`, `svgArc`, `insetTriangle`.
- Document helpers: `svgCoord`, `svgDoc`, `writeSVG`.
- `SVGLibExample` executable demonstrating a gauge SVG with arc zones, pointer, and hub.
