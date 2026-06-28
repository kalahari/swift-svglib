// SVGLib — Path segment types and path building.

import Foundation

// MARK: - Path segment type

/// A single segment in an SVG path — either a straight line or a circular arc.
/// The `to` point may be `nil` when it comes from a failed `lineIntersection`; `buildPath`
/// treats a `nil` endpoint as an error and returns `nil`.
public enum PathSegment {
    /// A point to move to without drawing (the M command in SVG path syntax).
    case move(to: Point?)
    /// A straight line to the given point.
    case line(to: Point?)
    /// A circular arc to the given point, drawn around `center` with the given `radius`.
    /// `clockwise` sets SVG sweep-flag (true = 1, false = 0). The large-arc flag is derived
    /// automatically from the angular span of the arc.
    case arc(center: Point, radius: Double, clockwise: Bool, to: Point?)
}

// MARK: - Private path helpers

/// Returns the angular sweep and large-arc flag for an SVG arc between two points around a center.
/// Normalizes the sweep direction so it matches the requested clockwise/counterclockwise winding.
private func arcSweepAndLargeArcFlag(from: Point, to: Point, center: Point, clockwise: Bool) -> (sweep: Double, largeArc: Int) {
    let sa = atan2(from.y - center.y, from.x - center.x)
    let ea = atan2(to.y - center.y, to.x - center.x)
    var sweep = ea - sa
    if clockwise {
        if sweep < 0 { sweep += 2 * .pi }
    } else {
        if sweep > 0 { sweep -= 2 * .pi }
    }
    return (sweep, abs(sweep) > .pi ? 1 : 0)
}

/// Builds an SVG path with fillet arcs inserted at selected junctions.
///
/// `radiusFor` is called with a point index (matching the `segments` array index) and returns
/// the fillet radius at that corner, or `nil`/0 for no fillet. Index 0 addresses the
/// M-point junction between the close segment and the first drawn segment (closed paths only);
/// indices 1…n address the interior corners in order.
private func buildPathWithFillets(
    segments: [PathSegment], close: Bool, radiusFor: (Int) -> Double?
) -> String? {
    var pts: [Point] = []
    for seg in segments {
        let pt: Point?
        switch seg {
        case .move(let p): pt = p
        case .line(let p): pt = p
        case .arc(_, _, _, let p): pt = p
        }
        guard let p = pt else { return nil }
        pts.append(p)
    }

    enum DrawKind {
        case line
        case arc(center: Point, radius: Double, clockwise: Bool)
    }
    struct DrawSeg {
        var from, to: Point
        var kind: DrawKind
    }

    var drawSegs: [DrawSeg] = []
    for i in 1..<segments.count {
        let (from, to) = (pts[i - 1], pts[i])
        switch segments[i] {
        case .move:
            continue
        case .line:
            drawSegs.append(DrawSeg(from: from, to: to, kind: .line))
        case .arc(let c, let ar, let cw, _):
            drawSegs.append(
                DrawSeg(from: from, to: to, kind: .arc(center: c, radius: ar, clockwise: cw)))
        }
    }
    guard !drawSegs.isEmpty else { return nil }

    if close {
        drawSegs.append(DrawSeg(from: pts[pts.count - 1], to: pts[0], kind: .line))
    }

    // Returns the tangent point on an arc (center ac, radius ar) closest to junction P.
    func arcTangentPoint(ac: Point, ar: Double, fc: Point, P: Point) -> Point? {
        guard distance(fc, ac) > 0 else { return nil }
        let u = unitVector(from: ac, to: fc)
        let ta = Point(x: ac.x + ar * u.x, y: ac.y + ar * u.y)
        let tb = Point(x: ac.x - ar * u.x, y: ac.y - ar * u.y)
        return squaredDistance(ta, P) <= squaredDistance(tb, P) ? ta : tb
    }

    // Attempts to compute a fillet of the given radius at the junction between prev.to and curr.from.
    func tryFillet(_ prev: DrawSeg, _ curr: DrawSeg, radius: Double) -> (
        t1: Point, t2: Point, center: Point, cw: Bool
    )? {
        let P = prev.to
        switch (prev.kind, curr.kind) {
        case (.line, .line):
            let l1 = Line(p0: prev.from, p1: P)
            let l2 = Line(p0: P, p1: curr.to)
            guard !areTangent(l1: l1, l2: l2) else { return nil }
            guard let fc = filletCenter(l1: l1, l2: l2, radius: radius) else { return nil }
            let t1 = footOfPerpendicular(from: fc, to: l1)
            let t2 = footOfPerpendicular(from: fc, to: l2)
            return (t1, t2, fc, filletArcIsClockwise(center: fc, from: t1, to: t2))

        case (.line, .arc(let ac, let ar, _)):
            let l1 = Line(p0: prev.from, p1: P)
            let outArc = Arc(center: ac, radius: ar, start: 0, sweep: 0)
            guard !areTangent(line: l1, arc: outArc) else { return nil }
            guard let fc = filletCenter(line: l1, arc: outArc, radius: radius) else { return nil }
            let t1 = footOfPerpendicular(from: fc, to: l1)
            guard let t2 = arcTangentPoint(ac: ac, ar: ar, fc: fc, P: P) else { return nil }
            return (t1, t2, fc, filletArcIsClockwise(center: fc, from: t1, to: t2))

        case (.arc(let ac, let ar, _), .line):
            // Pass the outgoing line reversed so its p1 is the junction — matches filletCenter(line:arc:) convention.
            let l2rev = Line(p0: curr.to, p1: P)
            let inArc = Arc(center: ac, radius: ar, start: 0, sweep: 0)
            guard !areTangent(line: l2rev, arc: inArc) else { return nil }
            guard let fc = filletCenter(line: l2rev, arc: inArc, radius: radius) else { return nil }
            guard let t1 = arcTangentPoint(ac: ac, ar: ar, fc: fc, P: P) else { return nil }
            let t2 = footOfPerpendicular(from: fc, to: Line(p0: P, p1: curr.to))
            return (t1, t2, fc, filletArcIsClockwise(center: fc, from: t1, to: t2))

        case (.arc, .arc):
            return nil
        }
    }

    var result: [DrawSeg] = []
    for i in 0..<drawSegs.count {
        var curr = drawSegs[i]
        if !result.isEmpty, let r = radiusFor(i), r > 0,
           let fr = tryFillet(result[result.count - 1], curr, radius: r) {
            result[result.count - 1].to = fr.t1
            result.append(
                DrawSeg(
                    from: fr.t1, to: fr.t2,
                    kind: .arc(center: fr.center, radius: r, clockwise: fr.cw)))
            curr.from = fr.t2
        }
        result.append(curr)
    }

    // For closed paths, also fillet the M-point junction between the close segment and the first
    // drawn segment. The fillet arc is inserted at position 0 and becomes the new path start (M).
    if close, result.count >= 2, let r = radiusFor(0), r > 0,
       let fr = tryFillet(result[result.count - 1], result[0], radius: r) {
        result[result.count - 1].to = fr.t1
        result[0].from = fr.t2
        result.insert(
            DrawSeg(
                from: fr.t1, to: fr.t2,
                kind: .arc(center: fr.center, radius: r, clockwise: fr.cw)), at: 0)
    }

    guard let first = result.first else { return nil }
    var parts = ["M \(svgCoord(first.from.x)) \(svgCoord(first.from.y))"]
    for seg in result {
        switch seg.kind {
        case .line:
            parts.append("L \(svgCoord(seg.to.x)) \(svgCoord(seg.to.y))")
        case .arc(let center, let segRadius, let clockwise):
            let (_, largeArc) = arcSweepAndLargeArcFlag(from: seg.from, to: seg.to, center: center, clockwise: clockwise)
            parts.append(
                "A \(svgCoord(segRadius)) \(svgCoord(segRadius)) 0 \(largeArc) \(clockwise ? 1 : 0) \(svgCoord(seg.to.x)) \(svgCoord(seg.to.y))"
            )
        }
    }
    if close { parts.append("Z") }
    return parts.joined(separator: " ")
}

// MARK: - Public path builders

/// Builds an SVG path `d` attribute string from an array of path segments.
///
/// The first segment's endpoint opens the path with `M`; each subsequent segment appends
/// `L` (line) or `A` (arc). Returns `nil` if any segment contains a `nil` endpoint.
///
/// **Uniform fillets** — pass `filletRadius` to round every non-tangent corner with the same radius.
///
/// **Per-corner fillets** — pass `filletRadii` to round only selected corners, each with its own
/// radius. The dictionary key is the point index in `segments`: key `1` is the first interior
/// corner (between segments 0 and 1), key `2` the second, and so on. Key `0` addresses the
/// closing corner of a closed path (where the `Z` segment rejoins the start). Corners absent
/// from the dictionary are left sharp. When `filletRadii` is provided it takes full control;
/// `filletRadius` is ignored.
///
/// Line–line, line–arc, and arc–line junctions are supported; arc–arc junctions are always left sharp.
///
/// - Parameters:
///   - segments: Ordered list of path segments describing the outline.
///   - close: When `true` (default), appends `Z` to close the path.
///   - filletRadius: Uniform fillet radius applied to every corner. Ignored when `nil` or ≤ 0,
///     or when `filletRadii` is provided.
///   - filletRadii: Per-corner fillet radii keyed by point index. When non-nil, overrides
///     `filletRadius` entirely. Entries with a value ≤ 0 are treated as no fillet.
public func buildPath(
    segments: [PathSegment], close: Bool = true,
    filletRadius: Double? = nil, filletRadii: [Int: Double]? = nil
) -> String? {
    if let radii = filletRadii, segments.count >= 3 {
        return buildPathWithFillets(segments: segments, close: close) { radii[$0] }
    }
    if let r = filletRadius, r > 0, segments.count >= 3 {
        return buildPathWithFillets(segments: segments, close: close) { _ in r }
    }

    var parts: [String] = []
    var currentPoint: Point? = nil

    for (index, segment) in segments.enumerated() {
        // Extract the destination point regardless of segment type.
        let destination: Point?
        switch segment {
        case .move(let pt): destination = pt
        case .line(let pt): destination = pt
        case .arc(_, _, _, let pt): destination = pt
        }

        guard let pt = destination else { return nil }

        if index == 0 {
            parts.append("M \(svgCoord(pt.x)) \(svgCoord(pt.y))")
        } else {
            switch segment {
            case .move:
                continue
            case .line:
                parts.append("L \(svgCoord(pt.x)) \(svgCoord(pt.y))")

            case .arc(let center, let radius, let clockwise, _):
                guard let from = currentPoint else { return nil }
                let (_, largeArc) = arcSweepAndLargeArcFlag(from: from, to: pt, center: center, clockwise: clockwise)
                let sweepFlag = clockwise ? 1 : 0
                parts.append(
                    "A \(svgCoord(radius)) \(svgCoord(radius)) 0 \(largeArc) \(sweepFlag) \(svgCoord(pt.x)) \(svgCoord(pt.y))"
                )
            }
        }
        currentPoint = pt
    }

    if close { parts.append("Z") }
    return parts.joined(separator: " ")
}

/// Returns an SVG path string for a circular arc segment between two arc fractions.
/// The arc sweeps clockwise on screen, so SVG sweep-flag=1 is used.
/// large-arc-flag is set automatically based on whether the segment spans more than 180°.
/// - Parameters:
///   - t0: Start position as an arc fraction (0 = arc start, ~7:30 on a clock face).
///   - t1: End position as an arc fraction (1 = arc end, ~4:30 on a clock face).
///   - arc: The arc defining center, radius, start angle, and sweep.
public func arcPath(t0: Double, t1: Double, arc: Arc) -> String {
    let p0 = svgPtAtArcFraction(t0, arc: arc)
    let p1 = svgPtAtArcFraction(t1, arc: arc)
    let sweep = (t1 - t0) * arc.sweep
    let largeArc = sweep > 180 ? 1 : 0
    return
        "M \(svgCoord(p0.x)) \(svgCoord(p0.y)) A \(svgCoord(arc.radius)) \(svgCoord(arc.radius)) 0 \(largeArc) 1 \(svgCoord(p1.x)) \(svgCoord(p1.y))"
}

/// Returns a filled SVG `<path>` element for a closed arc band between two arc fractions.
/// The shape is bounded by two concentric arcs (inner and outer) joined by radial lines at each end.
/// - Parameters:
///   - t0: Start position as an arc fraction (0 = arc start, ~7:30 on a clock face).
///   - t1: End position as an arc fraction (1 = arc end, ~4:30 on a clock face).
///   - arc: The arc defining center, radius, start angle, and sweep. `arc.radius` is the centre-line radius of the band.
///   - thickness: Total radial width of the band. Inner radius is `arc.radius - thickness/2`, outer is `arc.radius + thickness/2`.
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`).
///   - roundStart: When `true`, caps the start end of the band with a semicircular arc.
///   - roundEnd: When `true`, caps the end end of the band with a semicircular arc.
public func arcShape(
    t0: Double, t1: Double, arc: Arc, thickness: Double, fill: String,
    roundStart: Bool = false, roundEnd: Bool = false
) -> String {
    let outerR = arc.radius + thickness / 2
    let innerR = arc.radius - thickness / 2
    let capR = thickness / 2

    let outerStart = svgPtAtArcFraction(t0, r: outerR, arc: arc)
    let outerEnd = svgPtAtArcFraction(t1, r: outerR, arc: arc)
    let innerEnd = svgPtAtArcFraction(t1, r: innerR, arc: arc)
    let innerStart = svgPtAtArcFraction(t0, r: innerR, arc: arc)
    let capEndCenter = svgPtAtArcFraction(t1, r: arc.radius, arc: arc)
    let capStartCenter = svgPtAtArcFraction(t0, r: arc.radius, arc: arc)

    var segments: [PathSegment] = [
        .line(to: outerStart),
        .arc(center: arc.center, radius: outerR, clockwise: true, to: outerEnd),
    ]

    if roundEnd {
        segments.append(.arc(center: capEndCenter, radius: capR, clockwise: true, to: innerEnd))
    } else {
        segments.append(.line(to: innerEnd))
    }

    segments.append(.arc(center: arc.center, radius: innerR, clockwise: false, to: innerStart))

    if roundStart {
        segments.append(.arc(center: capStartCenter, radius: capR, clockwise: true, to: outerStart))
    }

    guard let d = buildPath(segments: segments) else {
        fatalError("arcShape: failed to build path for t0=\(t0) t1=\(t1)")
    }
    return "<path d=\"\(d)\" fill=\"\(fill)\" stroke=\"none\"/>"
}
