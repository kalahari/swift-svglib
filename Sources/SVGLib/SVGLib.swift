// SVGLib — General-purpose SVG generation utilities.

import Foundation

// ─────────────────────────── Color helpers ───────────────────────────────────

/// Returns a CSS hex color string (e.g. `#FF8000`) for RGB components in the 0–1 range.
/// - Parameters:
///   - r: Red component (0.0–1.0).
///   - g: Green component (0.0–1.0).
///   - b: Blue component (0.0–1.0).
public func hexRGB(_ r: Double, _ g: Double, _ b: Double) -> String {
    String(
        format: "#%02X%02X%02X",
        Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
}

/// Returns a CSS hex color string (e.g. `#2C2C2C`) for a gray value in the 0–1 range.
/// - Parameter w: White intensity, where 0.0 is black and 1.0 is white.
public func hexGray(_ w: Double) -> String {
    hexRGB(w, w, w)
}

// ─────────────────────────── Coordinate helpers ───────────────────────────────

/// A 2D point in SVG coordinate space.
public struct Point {
    /// X coordinate in SVG units, where 0 is the left edge and increases to the right.
    public var x: Double
    /// Y coordinate in SVG units, where 0 is the top edge and increases downward.
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A line segment defined by two points in SVG coordinate space.
public struct Line {
    public var p0: Point
    public var p1: Point

    public init(p0: Point, p1: Point) {
        self.p0 = p0
        self.p1 = p1
    }
}

/// A circle defined by a center point and radius in SVG coordinate space.
public struct Circle {
    public var center: Point
    public var radius: Double

    public init(center: Point, radius: Double) {
        self.center = center
        self.radius = radius
    }
}

/// Describes a circular arc in SVG coordinate space.
public struct Arc {
    /// Centre of the arc on the canvas.
    public var center: Point
    /// Radius in SVG units.
    public var radius: Double
    /// Starting angle in degrees (y-down clockwise convention: 0° = 3:00, 90° = 6:00, 270° = 12:00).
    public var start: Double
    /// Clockwise sweep of the arc in degrees.
    public var sweep: Double

    public init(center: Point, radius: Double, start: Double, sweep: Double) {
        self.center = center
        self.radius = radius
        self.start = start
        self.sweep = sweep
    }
}

/// The implicit coefficients of a line in the form ax + by = c.
public struct LineCoefficients {
    public var a: Double
    public var b: Double
    public var c: Double

    public init(a: Double, b: Double, c: Double) {
        self.a = a
        self.b = b
        self.c = c
    }

    /// Returns the coefficients for the infinite line through `line.p0` and `line.p1`.
    public init(_ line: Line) {
        a = line.p1.y - line.p0.y
        b = line.p0.x - line.p1.x
        c = a * line.p0.x + b * line.p0.y
    }
}

/// Returns the point where two lines (p0→p1 and p2→p3) intersect, or nil if they are parallel.
/// - Parameters:
///   - l1: First line segment defined by points p0 and p1.
///   - l2: Second line segment defined by points p2 and p3.
public func lineIntersection(l1: Line, l2: Line) -> Point? {
    let lc1 = LineCoefficients(l1)
    let lc2 = LineCoefficients(l2)
    let det = lc1.a * lc2.b - lc2.a * lc1.b
    if det == 0 {
        return nil  // Lines are parallel
    }
    let x = (lc2.b * lc1.c - lc1.b * lc2.c) / det
    let y = (lc1.a * lc2.c - lc2.a * lc1.c) / det
    return Point(x: x, y: y)
}

/// Returns a line offset from the input line by a given distance in SVG units.
/// The offset is perpendicular to the line, with positive distance to the right of
/// or below the line direction (p0→p1) and negative distance to the left or above.
/// - Parameters:
///   - line: The original line segment defined by points p0 and p1.
///   - distance: The distance to offset the line in SVG units. Positive values offset
///     to the right or below the line direction, negative values to the left or above.
public func offsetLine(line: Line, distance: Double) -> Line {
    guard lineLength(line) > 0 else { return line }
    let u = unitVector(from: line.p0, to: line.p1)
    let px = -u.y * distance
    let py = u.x * distance
    return Line(
        p0: Point(x: line.p0.x + px, y: line.p0.y + py),
        p1: Point(x: line.p1.x + px, y: line.p1.y + py)
    )
}

/// Returns the point reached when extending a line segment by a given distance beyond its endpoint.
/// The extension is in the same direction as the line from p0 to p1.
/// - Parameters:
///   - line: The original line segment defined by points p0 and p1.
///   - distance: The distance to extend the line in SVG units. Positive values extend
///     in the direction from p0 to p1, negative values extend in the opposite direction.
public func extendLine(line: Line, distance: Double) -> Point {
    guard lineLength(line) > 0 else { return line.p1 }
    let u = unitVector(from: line.p0, to: line.p1)
    return Point(x: line.p1.x + u.x * distance, y: line.p1.y + u.y * distance)
}

/// Returns the absolute canvas angle in degrees for a position along an arc.
/// Angles increase as `t` increases because the arc sweeps clockwise in y-down convention.
/// - Parameters:
///   - t: Arc fraction, where 0 is the arc start and 1 is the arc end.
///   - arc: The arc whose start and sweep define the angle range.
public func arcAngleDegrees(_ t: Double, arc: Arc) -> Double {
    arc.start + t * arc.sweep
}

/// Returns the SVG point at an angle and radius from a given centre.
/// Uses SVG y-down convention: angles increase clockwise, with 0° at 3:00, 90° at 6:00, 180° at 9:00, 270° at 12:00.
/// - Parameters:
///   - deg: Angle in degrees (y-down clockwise convention).
///   - r: Radius from the centre point.
///   - center: Centre of the canvas in SVG coordinates.
public func svgPointAtAngle(deg: Double, r: Double, center: Point) -> Point {
    let a = deg * .pi / 180
    return Point(x: center.x + r * cos(a), y: center.y + r * sin(a))
}

/// Returns the SVG point at a given arc fraction and radius.
/// Converts the fraction to degrees via `arcAngleDegrees`, then to an SVG coordinate via `svgPointAtAngle`.
/// - Parameters:
///   - t: Arc fraction, where 0 is the arc start and 1 is the arc end.
///   - r: Radius from the centre point. Defaults to `arc.radius`.
///   - arc: The arc defining center, start angle, and sweep.
public func svgPtAtArcFraction(_ t: Double, r: Double? = nil, arc: Arc) -> Point {
    svgPointAtAngle(deg: arcAngleDegrees(t, arc: arc), r: r ?? arc.radius, center: arc.center)
}

/// Returns the SVG points where a line intersects a circle, or nil if there are no intersections.
/// - Parameters:
///   - line: The line segment defined by points p0 and p1.
///   - center: The centre of the circle in SVG coordinates.
///   - radius: The radius of the circle in SVG units.
public func lineCircleIntersections(line: Line, center: Point, radius: Double) -> [Point]? {
    // Solve the quadratic equation for the intersection of the line and circle.
    let dx = line.p1.x - line.p0.x
    let dy = line.p1.y - line.p0.y
    let fx = line.p0.x - center.x
    let fy = line.p0.y - center.y
    let a = dx * dx + dy * dy
    let b = 2 * (fx * dx + fy * dy)
    let c = fx * fx + fy * fy - radius * radius
    let discriminant = b * b - 4 * a * c
    if discriminant < 0 {
        return nil  // No intersections
    }
    let sqrtDisc = sqrt(discriminant)
    let t1 = (-b + sqrtDisc) / (2 * a)
    let t2 = (-b - sqrtDisc) / (2 * a)
    var points: [Point] = []
    if t1 >= 0 && t1 <= 1 {
        points.append(Point(x: line.p0.x + t1 * dx, y: line.p0.y + t1 * dy))
    }
    if t2 >= 0 && t2 <= 1 {
        points.append(Point(x: line.p0.x + t2 * dx, y: line.p0.y + t2 * dy))
    }
    // return the points in the order they appear along the line from p0 to p1
    points.sort { (pA, pB) -> Bool in
        let tA = ((pA.x - line.p0.x) * dx + (pA.y - line.p0.y) * dy) / (dx * dx + dy * dy)
        let tB = ((pB.x - line.p0.x) * dx + (pB.y - line.p0.y) * dy) / (dx * dx + dy * dy)
        return tA < tB
    }
    return points.isEmpty ? nil : points
}

/// Returns the z-component of (b − a) × (p − a).
/// Positive means p is to the left of the directed segment a→b in standard math axes
/// (which is to the right in SVG's y-down coordinate system). Used for side-of-line tests.
private func crossZ(_ a: Point, _ b: Point, _ p: Point) -> Double {
    (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
}

/// Returns the foot of the perpendicular from `p` onto the infinite line through `l`.
private func footOfPerpendicular(from p: Point, to l: Line) -> Point {
    let dx = l.p1.x - l.p0.x
    let dy = l.p1.y - l.p0.y
    let len2 = dx * dx + dy * dy
    guard len2 > 0 else { return l.p0 }
    let t = ((p.x - l.p0.x) * dx + (p.y - l.p0.y) * dy) / len2
    return Point(x: l.p0.x + t * dx, y: l.p0.y + t * dy)
}

/// Returns `true` if the short arc from `t1` to `t2` around `center` sweeps clockwise in SVG (y-down).
private func filletArcIsClockwise(center: Point, from t1: Point, to t2: Point) -> Bool {
    (t1.x - center.x) * (t2.y - center.y) - (t1.y - center.y) * (t2.x - center.x) > 0
}

/// Returns the center of a fillet circle of the given radius inscribed in the angle formed by two lines.
///
/// The fillet circle is tangent to both lines and lies in the interior of the angle between them.
/// - Parameters:
///   - l1: First line segment forming one side of the corner.
///   - l2: Second line segment forming the other side of the corner.
///   - radius: Radius of the fillet circle in SVG units.
/// - Returns: The center of the fillet circle, or `nil` if the lines are parallel.
public func filletCenter(l1: Line, l2: Line, radius: Double) -> Point? {
    guard lineIntersection(l1: l1, l2: l2) != nil else { return nil }
    let mid1 = midpoint(l1.p0, l1.p1)
    let mid2 = midpoint(l2.p0, l2.p1)
    for s1 in [radius, -radius] {
        for s2 in [radius, -radius] {
            let ol1 = offsetLine(line: l1, distance: s1)
            let ol2 = offsetLine(line: l2, distance: s2)
            guard let c = lineIntersection(l1: ol1, l2: ol2) else { continue }
            let sameL1 = crossZ(l1.p0, l1.p1, c) * crossZ(l1.p0, l1.p1, mid2) > 0
            let sameL2 = crossZ(l2.p0, l2.p1, c) * crossZ(l2.p0, l2.p1, mid1) > 0
            if sameL1 && sameL2 { return c }
        }
    }
    return nil
}

/// Returns the center of a fillet circle of the given radius tangent to both a line segment and an arc.
///
/// The line and arc are assumed to share an endpoint near `line.p1`. The fillet circle may be
/// externally tangent to the arc (center outside the arc) or internally tangent (center inside).
/// The candidate nearest to `line.p1` is returned.
/// - Parameters:
///   - line: The line segment. The shared endpoint with the arc is assumed to be `line.p1`.
///   - arc: The arc tangent to the fillet circle.
///   - radius: Radius of the fillet circle in SVG units.
/// - Returns: The center of the fillet circle, or `nil` if no real solution exists.
public func filletCenter(line: Line, arc: Arc, radius: Double) -> Point? {
    var candidates: [Point] = []
    for sign in [radius, -radius] {
        let ol = offsetLine(line: line, distance: sign)
        let dx = ol.p1.x - ol.p0.x
        let dy = ol.p1.y - ol.p0.y
        let fx = ol.p0.x - arc.center.x
        let fy = ol.p0.y - arc.center.y
        let qa = dx * dx + dy * dy
        guard qa > 0 else { continue }
        let b = 2 * (fx * dx + fy * dy)
        for combinedR in [arc.radius + radius, arc.radius - radius] {
            guard combinedR > 0 else { continue }
            let c = fx * fx + fy * fy - combinedR * combinedR
            let disc = b * b - 4 * qa * c
            guard disc >= 0 else { continue }
            let sqrtDisc = disc.squareRoot()
            for t in [(-b + sqrtDisc) / (2 * qa), (-b - sqrtDisc) / (2 * qa)] {
                candidates.append(Point(x: ol.p0.x + t * dx, y: ol.p0.y + t * dy))
            }
        }
    }
    guard !candidates.isEmpty else { return nil }
    return candidates.min(by: { squaredDistance($0, line.p1) < squaredDistance($1, line.p1) })
}

/// Returns `true` if two line segments are tangent (parallel) at their shared endpoint.
///
/// Two straight lines are tangent at a meeting point when their direction vectors are parallel,
/// i.e. the cross product of the two directions is zero.
/// - Parameters:
///   - l1: First line segment.
///   - l2: Second line segment.
/// - Returns: `true` if the lines are tangent (parallel directions), `false` otherwise.
public func areTangent(l1: Line, l2: Line) -> Bool {
    let d1x = l1.p1.x - l1.p0.x
    let d1y = l1.p1.y - l1.p0.y
    let d2x = l2.p1.x - l2.p0.x
    let d2y = l2.p1.y - l2.p0.y
    let cross = d1x * d2y - d1y * d2x
    let scale = (d1x * d1x + d1y * d1y) * (d2x * d2x + d2y * d2y)
    return scale > 0 && cross * cross / scale < 1e-10
}

/// Returns `true` if a line segment is tangent to an arc at their shared endpoint (`line.p1`).
///
/// A line is tangent to a circle at a point when the line direction is perpendicular to the
/// radius at that point, i.e. the dot product of the line direction and the radial vector is zero.
/// - Parameters:
///   - line: The line segment. The shared endpoint with the arc is assumed to be `line.p1`.
///   - arc: The arc. The shared endpoint is the arc point nearest to `line.p1`.
/// - Returns: `true` if the line is tangent to the arc at `line.p1`, `false` otherwise.
public func areTangent(line: Line, arc: Arc) -> Bool {
    let dx = line.p1.x - line.p0.x
    let dy = line.p1.y - line.p0.y
    let rx = line.p1.x - arc.center.x
    let ry = line.p1.y - arc.center.y
    let dot = dx * rx + dy * ry
    let scale = (dx * dx + dy * dy) * (rx * rx + ry * ry)
    return scale > 0 && dot * dot / scale < 1e-10
}

/// Returns the set of lines that are tangent to the two input circles, or nil if there are no such lines.
/// - Parameters:
///  - c1: First circle defined by center and radius.
/// - c2: Second circle defined by center and radius.
/// - Returns: An array of lines tangent to both circles, or `nil` if no such lines exist.
/// The lines are returned orderd external first, then internal. Each line is represented as a `Line` struct with points `p0` and `p1`.
/// The tangent lines can be external (both circles on the same side) or internal (circles on opposite sides), depending on the relative positions and radii of the circles.
/// Note that if the circles are tangent to each other, there will be exactly one common tangent line (the line of tangency). If the circles are separate and non-intersecting, there will be four common tangents (two external and two internal). If one circle is contained within the other without touching, there will be no common tangents.
/// The mathematical derivation of the common tangents involves solving a system of equations that represent the conditions for tangency to both circles. The function should handle edge cases such as coincident circles, one circle inside another, and tangent circles appropriately.
public func commonTangents(c1: Circle, c2: Circle) -> [Line]? {
    let dx = c2.center.x - c1.center.x
    let dy = c2.center.y - c1.center.y
    let d2 = dx * dx + dy * dy
    guard d2 > 0 else { return nil }  // Coincident centers, infinite tangents

    var tangents: [Line] = []
    // sign=-1 → external tangents (rDiff = r1+r2); sign=1 → internal tangents (rDiff = r1-r2)
    for sign in [-1.0, 1.0] {
        let rDiff = c1.radius - sign * c2.radius
        let rDiff2 = rDiff * rDiff
        guard d2 >= rDiff2 else { continue }
        let h = sqrt(d2 - rDiff2)
        for hSign in [h, -h] {
            let nx = (dx * rDiff + sign * dy * hSign) / d2
            let ny = (dy * rDiff - sign * dx * hSign) / d2
            let p1 = Point(x: c1.center.x + c1.radius * nx, y: c1.center.y + c1.radius * ny)
            let p2 = Point(
                x: c2.center.x + sign * c2.radius * nx, y: c2.center.y + sign * c2.radius * ny)
            tangents.append(Line(p0: p1, p1: p2))
        }
    }
    return tangents.isEmpty ? nil : tangents
}

/// Returns the midpoint between two points.
public func midpoint(_ p1: Point, _ p2: Point) -> Point {
    Point(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
}

/// Returns the squared Euclidean distance between two points.
public func squaredDistance(_ p0: Point, _ p1: Point) -> Double {
    let dx = p1.x - p0.x
    let dy = p1.y - p0.y
    return dx * dx + dy * dy
}

/// Returns the Euclidean distance between two points.
public func distance(_ p0: Point, _ p1: Point) -> Double {
    squaredDistance(p0, p1).squareRoot()
}

/// Returns the length of a line segment.
public func lineLength(_ line: Line) -> Double {
    return distance(line.p0, line.p1)
}

/// Returns the unit vector from `a` to `b` as `(x:, y:)` components.
private func unitVector(from a: Point, to b: Point) -> (x: Double, y: Double) {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let len = (dx * dx + dy * dy).squareRoot()
    return (dx / len, dy / len)
}

// ─────────────────────────── Path segments ────────────────────────────────────

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

/// Builds an SVG path with fillet arcs inserted at all non-tangent junctions, including the
/// M-point junction between the close segment and the first drawn segment for closed paths.
private func buildPathWithFillets(segments: [PathSegment], close: Bool, radius: Double) -> String? {
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

    // Attempts to compute a fillet at the junction between prev.to and curr.from.
    func tryFillet(_ prev: DrawSeg, _ curr: DrawSeg) -> (
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
        if !result.isEmpty, let fr = tryFillet(result[result.count - 1], curr) {
            result[result.count - 1].to = fr.t1
            result.append(
                DrawSeg(
                    from: fr.t1, to: fr.t2,
                    kind: .arc(center: fr.center, radius: radius, clockwise: fr.cw)))
            curr.from = fr.t2
        }
        result.append(curr)
    }

    // For closed paths, also fillet the M-point junction between the close segment and the first
    // drawn segment. The fillet arc is inserted at position 0 and becomes the new path start (M).
    if close, result.count >= 2, let fr = tryFillet(result[result.count - 1], result[0]) {
        result[result.count - 1].to = fr.t1
        result[0].from = fr.t2
        result.insert(
            DrawSeg(
                from: fr.t1, to: fr.t2,
                kind: .arc(center: fr.center, radius: radius, clockwise: fr.cw)), at: 0)
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

/// Builds an SVG path `d` attribute string from an array of path segments.
///
/// The first segment's endpoint opens the path with `M`; each subsequent segment appends
/// `L` (line) or `A` (arc). Returns `nil` if any segment contains a `nil` endpoint.
///
/// When `filletRadius` is provided and greater than zero, a circular fillet arc of that radius
/// is inserted at each junction where consecutive segments are not tangent. Line–line,
/// line–arc, and arc–line junctions are supported; arc–arc junctions are left sharp.
/// For closed paths, the junction where the close segment meets the first drawn segment is also filleted.
///
/// - Parameters:
///   - segments: Ordered list of path segments describing the outline.
///   - close: When `true` (default), appends `Z` to close the path.
///   - filletRadius: Optional fillet radius in SVG units. Ignored when `nil` or ≤ 0.
public func buildPath(segments: [PathSegment], close: Bool = true, filletRadius: Double? = nil)
    -> String?
{
    if let r = filletRadius, r > 0, segments.count >= 3 {
        return buildPathWithFillets(segments: segments, close: close, radius: r)
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

// ─────────────────────────── Arc path ─────────────────────────────────────────

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

// ─────────────────────────── Shapes ───────────────────────────

/// Returns an SVG `<circle>` element for a filled circle at a given centre and radius.
/// - Parameters:
///   - center: Centre of the circle in SVG coordinates.
///   - r: Radius of the circle in SVG units.
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`).
public func svgCircle(center: Point, r: Double, fill: String) -> String {
    "<circle cx=\"\(svgCoord(center.x))\" cy=\"\(svgCoord(center.y))\" r=\"\(svgCoord(r))\" fill=\"\(fill)\"/>"
}

/// Returns and SVG `<line>` element for a line segment between two points.
/// - Parameters:
///  - line: The line segment defined by points p0 and p1.
///  - width: Stroke width in SVG units, defaults to 2.0.
///  - stroke: CSS colour string for the line stroke
///    (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func svgLine(_ line: Line, width: Double = 2.0, stroke: String = "black") -> String {
    "<line x1=\"\(svgCoord(line.p0.x))\" y1=\"\(svgCoord(line.p0.y))\" x2=\"\(svgCoord(line.p1.x))\" y2=\"\(svgCoord(line.p1.y))\" stroke=\"\(stroke)\" stroke-width=\"\(svgCoord(width))\"/>"
}

/// Returns an SVG `<arc>` element for a circular arc segment.
/// - Parameters:
///   - arc: The arc defining center, radius, start angle, and sweep.
///   - width: Stroke width in SVG units, defaults to 2.0.
///   - stroke: CSS colour string for the arc stroke (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func svgArc(_ arc: Arc, width: Double = 2.0, stroke: String = "black") -> String {
    let startPt = svgPtAtArcFraction(0, arc: arc)
    let endPt = svgPtAtArcFraction(1, arc: arc)
    let sweep = arc.sweep
    let largeArc = sweep > 180 ? 1 : 0
    let sweepFlag = arc.sweep > 0 ? 1 : 0
    let d =
        "M \(svgCoord(startPt.x)) \(svgCoord(startPt.y)) A \(svgCoord(arc.radius)) \(svgCoord(arc.radius)) 0 \(largeArc) \(sweepFlag) \(svgCoord(endPt.x)) \(svgCoord(endPt.y))"
    return
        "<path d=\"\(d)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(svgCoord(width))\"/>"
}

/// Returns a new triangle inset by `d` pixels from all three edges.
/// Each vertex is displaced along its interior angle bisector by `d / sin(halfAngle)`.
/// - Parameters:
///   - p0, p1, p2: Triangle vertices in any winding order.
///   - d: Inset distance in SVG units. Should be less than the triangle's inradius.
/// - Returns: Tuple of inset vertices (q0, q1, q2) matching input order.
public func insetTriangle(p0: Point, p1: Point, p2: Point, d: Double)
    -> (q0: Point, q1: Point, q2: Point)
{
    let centroid = Point(
        x: (p0.x + p1.x + p2.x) / 3,
        y: (p0.y + p1.y + p2.y) / 3)

    func insetVtx(prev: Point, curr: Point, next: Point) -> Point {
        let e0 = unitVector(from: curr, to: prev)
        let e1 = unitVector(from: curr, to: next)
        let sumX = e0.x + e1.x
        let sumY = e0.y + e1.y
        let bLen = (sumX * sumX + sumY * sumY).squareRoot()
        var bx = sumX / bLen
        var by = sumY / bLen
        if bx * (centroid.x - curr.x) + by * (centroid.y - curr.y) < 0 {
            bx = -bx
            by = -by
        }
        let sinHalf = abs(bx * e1.y - by * e1.x)
        let offset = d / max(sinHalf, 0.001)
        return Point(x: curr.x + bx * offset, y: curr.y + by * offset)
    }

    return (
        q0: insetVtx(prev: p2, curr: p0, next: p1),
        q1: insetVtx(prev: p0, curr: p1, next: p2),
        q2: insetVtx(prev: p1, curr: p2, next: p0)
    )
}

// ─────────────────────────── Formatting ───────────────────────────────────────

/// Formats a Double as a 2-decimal-place string suitable for SVG coordinate attributes.
public func svgCoord(_ v: Double) -> String { String(format: "%.2f", v) }

// ─────────────────────────── Document wrapper ─────────────────────────────────

/// Wraps SVG content in a root `<svg>` element with a square viewBox.
/// - Parameters:
///   - content: The SVG markup to embed inside the root element.
///   - height: The height of the canvas in pixels. Defaults to 1024.
///   - width: The width of the canvas in pixels. Defaults to 1024.
public func svgDoc(_ content: String, height: Int = 1024, width: Int = 1024) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="\(width)" height="\(height)">
    \(content)
    </svg>
    """
}

// ─────────────────────────── File I/O ─────────────────────────────────────────

/// Writes an SVG string to a file, creating intermediate directories as needed.
/// Prints a confirmation on success, or an error message and exits with code 1 on failure.
/// - Parameters:
///   - content: The SVG markup to write.
///   - name: The filename (e.g. `"background.svg"`).
///   - directory: The output directory path. The file will be written to `directory/name`.
public func writeSVG(_ content: String, name: String, directory: String) {
    let path = "\(directory)/\(name)"
    let url = URL(fileURLWithPath: path)
    do {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        print("Wrote \(path)")
    } catch {
        print("Error writing \(path): \(error)")
        exit(1)
    }
}
