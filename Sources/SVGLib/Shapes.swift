// SVGLib — SVG element generators for basic shapes.

import Foundation

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
///   - p0: First triangle vertex.
///   - p1: Second triangle vertex.
///   - p2: Third triangle vertex.
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
