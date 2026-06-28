// SVGLibExample — Generates a simple gauge SVG demonstrating the SVGLib API.
//
// Produces output/gauge.svg relative to the current working directory.
//
// Run from the repo root:
//   swift run SVGLibExample

import SVGLib

let size: Double = 512
let center = Point(x: size / 2, y: size / 2)
let outputDir = "output"

// ── Arc zones ─────────────────────────────────────────────────────────────────
// A 240° arc centred at 12:00, split into three coloured bands.

let arc = Arc(center: center, radius: 210, start: 150, sweep: 240)
let thickness: Double = 36

let zones: [(t0: Double, t1: Double, color: String)] = [
    (0.00, 0.55, hexRGB(0.20, 0.75, 0.25)),   // green
    (0.55, 0.80, hexRGB(0.95, 0.78, 0.08)),   // yellow
    (0.80, 1.00, hexRGB(0.90, 0.22, 0.15)),   // red
]

let arcParts = zones.enumerated().map { i, z in
    arcShape(
        t0: z.t0, t1: z.t1, arc: arc, thickness: thickness, fill: z.color,
        roundStart: i == 0, roundEnd: i == zones.count - 1
    )
}

// ── Pointer ───────────────────────────────────────────────────────────────────
// A triangle pointing at 60% along the arc, with its tip at the arc inner edge
// and its base straddling the center.

let fraction: Double = 0.60
let pointerColor = hexRGB(0.45, 0.12, 0.08)

let tip      = svgPtAtArcFraction(fraction, r: arc.radius - thickness / 2 - 8, arc: arc)
let baseCenter = svgPtAtArcFraction(fraction, r: -(arc.radius * 0.15), arc: arc)
let spine    = Line(p0: tip, p1: baseCenter)
let baseL    = offsetLine(line: spine, distance:  14).p1
let baseR    = offsetLine(line: spine, distance: -14).p1

let pointerSegments: [PathSegment] = [
    .line(to: tip),
    .line(to: baseL),
    .line(to: baseR),
]

guard let pointerPath = buildPath(segments: pointerSegments) else {
    fatalError("Could not build pointer path")
}

// ── Hub ───────────────────────────────────────────────────────────────────────

let hubParts = [
    svgCircle(center: center, r: 18, fill: hexGray(0.35)),
    svgCircle(center: center, r:  8, fill: hexGray(0.65)),
]

// ── Compose and write ─────────────────────────────────────────────────────────

let allParts =
    arcParts
    + ["<path d=\"\(pointerPath)\" fill=\"\(pointerColor)\" stroke=\"none\"/>"]
    + hubParts

let svg = svgDoc(allParts.joined(separator: "\n"), height: Int(size), width: Int(size))
writeSVG(svg, name: "gauge.svg", directory: outputDir)
