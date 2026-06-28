// SVGLib — Geometric types and coordinate math.

import Foundation

// MARK: - Types

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

// MARK: - Distance and vector utilities

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

func unitVector(from a: Point, to b: Point) -> (x: Double, y: Double) {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let len = (dx * dx + dy * dy).squareRoot()
    return (dx / len, dy / len)
}

// MARK: - Line operations

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

// MARK: - Arc operations

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

// MARK: - Intersection

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

// MARK: - Fillet helpers

/// Returns the z-component of (b − a) × (p − a).
/// Positive means p is to the left of the directed segment a→b in standard math axes
/// (which is to the right in SVG's y-down coordinate system). Used for side-of-line tests.
private func crossZ(_ a: Point, _ b: Point, _ p: Point) -> Double {
    (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
}

/// Returns the foot of the perpendicular from `p` onto the infinite line through `l`.
func footOfPerpendicular(from p: Point, to l: Line) -> Point {
    let dx = l.p1.x - l.p0.x
    let dy = l.p1.y - l.p0.y
    let len2 = dx * dx + dy * dy
    guard len2 > 0 else { return l.p0 }
    let t = ((p.x - l.p0.x) * dx + (p.y - l.p0.y) * dy) / len2
    return Point(x: l.p0.x + t * dx, y: l.p0.y + t * dy)
}

/// Returns `true` if the short arc from `t1` to `t2` around `center` sweeps clockwise in SVG (y-down).
func filletArcIsClockwise(center: Point, from t1: Point, to t2: Point) -> Bool {
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

// MARK: - Tangency tests

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
