# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `renderPath(d:fill:)` for wrapping a path `d` string in a filled `<path>` element.
- `renderCapsule` filled path shape centered on a line segment with semicircular end caps.
- `renderArcCapsule` filled path shape centered on a circular arc with semicircular end caps.

### Changed
- Renamed markup emitters to use a `render` verb: `svgCircle` → `renderCircle`,
  `svgLine` → `renderLine`, `svgArc` → `renderArc`, `svgCapsule` → `renderCapsule`,
  `svgArcCapsule` → `renderArcCapsule`, `arcShape` → `renderArcShape`.
- Renamed document helpers: `svgCoord` → `formatCoord`, `svgDoc` → `renderDocument`,
  `writeSVG` → `writeDocument`.
- `renderDocument` accepts either a single content string or an array of strings joined with newlines.
- Renamed geometry helpers: `svgPointAtAngle` → `pointAtAngle`,
  `svgPtAtArcFraction` → `pointAtArcFraction`.
- Moved `insetTriangle` from `Shapes.swift` to `Geometry.swift`.
- Moved `renderArcShape` from `Path.swift` to `Shapes.swift`.

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
