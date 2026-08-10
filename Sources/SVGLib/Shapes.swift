// SVGLib — SVG element generators for basic shapes.

import Foundation

/// Returns a filled SVG `<path>` element for an arbitrary path `d` string.
/// - Parameters:
///   - d: The SVG path data string (e.g. from `buildPath`).
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`).
public func renderPath(d: String, fill: String = "black") -> String {
    "<path d=\"\(d)\" fill=\"\(fill)\" stroke=\"none\"/>"
}

/// Returns an SVG `<circle>` element for a filled circle at a given centre and radius.
/// - Parameters:
///   - center: Centre of the circle in SVG coordinates.
///   - r: Radius of the circle in SVG units.
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`).
public func renderCircle(center: Point, r: Double, fill: String) -> String {
    "<circle cx=\"\(formatCoord(center.x))\" cy=\"\(formatCoord(center.y))\" r=\"\(formatCoord(r))\" fill=\"\(fill)\"/>"
}

/// Returns and SVG `<line>` element for a line segment between two points.
/// - Parameters:
///  - line: The line segment defined by points p0 and p1.
///  - width: Stroke width in SVG units, defaults to 2.0.
///  - stroke: CSS colour string for the line stroke
///    (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func renderLine(_ line: Line, width: Double = 2.0, stroke: String = "black") -> String {
    "<line x1=\"\(formatCoord(line.p0.x))\" y1=\"\(formatCoord(line.p0.y))\" x2=\"\(formatCoord(line.p1.x))\" y2=\"\(formatCoord(line.p1.y))\" stroke=\"\(stroke)\" stroke-width=\"\(formatCoord(width))\"/>"
}

/// Returns a filled SVG `<path>` for a capsule (stadium) centered on a line segment.
/// The outline is two parallel sides offset by `width / 2`, joined by 180° tangent semicircles at each end.
/// - Parameters:
///   - line: Centre-line of the capsule, defined by points p0 and p1.
///   - width: Full thickness of the capsule in SVG units (end-cap diameter), defaults to 2.0.
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func renderCapsule(_ line: Line, width: Double = 2.0, fill: String = "black") -> String {
    let r = width / 2
    let right = offsetLine(line: line, distance: r)
    let left = offsetLine(line: line, distance: -r)
    let segments: [PathSegment] = [
        .line(to: right.p0),
        .line(to: right.p1),
        .arc(center: line.p1, radius: r, clockwise: true, to: left.p1),
        .line(to: left.p0),
        .arc(center: line.p0, radius: r, clockwise: true, to: right.p0),
    ]
    guard let d = buildPath(segments: segments) else {
        fatalError("renderCapsule: failed to build path")
    }
    return renderPath(d: d, fill: fill)
}

/// Returns an SVG `<arc>` element for a circular arc segment.
/// - Parameters:
///   - arc: The arc defining center, radius, start angle, and sweep.
///   - width: Stroke width in SVG units, defaults to 2.0.
///   - stroke: CSS colour string for the arc stroke (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func renderArc(_ arc: Arc, width: Double = 2.0, stroke: String = "black") -> String {
    let startPt = pointAtArcFraction(0, arc: arc)
    let endPt = pointAtArcFraction(1, arc: arc)
    let sweep = arc.sweep
    let largeArc = sweep > 180 ? 1 : 0
    let sweepFlag = arc.sweep > 0 ? 1 : 0
    let d =
        "M \(formatCoord(startPt.x)) \(formatCoord(startPt.y)) A \(formatCoord(arc.radius)) \(formatCoord(arc.radius)) 0 \(largeArc) \(sweepFlag) \(formatCoord(endPt.x)) \(formatCoord(endPt.y))"
    return
        "<path d=\"\(d)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(formatCoord(width))\"/>"
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
public func renderArcShape(
    t0: Double, t1: Double, arc: Arc, thickness: Double, fill: String,
    roundStart: Bool = false, roundEnd: Bool = false
) -> String {
    let outerR = arc.radius + thickness / 2
    let innerR = arc.radius - thickness / 2
    let capR = thickness / 2

    let outerStart = pointAtArcFraction(t0, r: outerR, arc: arc)
    let outerEnd = pointAtArcFraction(t1, r: outerR, arc: arc)
    let innerEnd = pointAtArcFraction(t1, r: innerR, arc: arc)
    let innerStart = pointAtArcFraction(t0, r: innerR, arc: arc)
    let capEndCenter = pointAtArcFraction(t1, r: arc.radius, arc: arc)
    let capStartCenter = pointAtArcFraction(t0, r: arc.radius, arc: arc)

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
        fatalError("renderArcShape: failed to build path for t0=\(t0) t1=\(t1)")
    }
    return renderPath(d: d, fill: fill)
}

/// Returns a filled SVG `<path>` for a capsule centered on a circular arc.
/// The outline is two concentric arcs offset by `width / 2`, joined by 180° tangent semicircles at each end.
/// - Parameters:
///   - arc: Centre-line of the capsule (center, radius, start angle, and sweep).
///   - width: Full radial thickness of the capsule in SVG units (end-cap diameter), defaults to 2.0.
///   - fill: CSS colour string for the fill (e.g. `"#FF0000"` or `"red"`), defaults to `"black"`.
public func renderArcCapsule(_ arc: Arc, width: Double = 2.0, fill: String = "black") -> String {
    renderArcShape(
        t0: 0, t1: 1, arc: arc, thickness: width, fill: fill,
        roundStart: true, roundEnd: true
    )
}

// MARK: - Construction guides

/// Default stroke colour for construction guides drawn via `renderGuide` / `renderDocument`.
public let defaultGuideColor = "#FF00FF"

/// Default stroke width for construction guides drawn via `renderGuide` / `renderDocument`.
public let defaultGuideStrokeWidth: Double = 1.0

/// A geometric primitive that can be drawn as a stroke-only construction guide.
public protocol GuideGeometry {
    /// Returns SVG markup rendering this geometry as a construction guide.
    /// - Parameters:
    ///   - color: CSS colour string for the stroke.
    ///   - strokeWidth: Stroke width in SVG units.
    func renderGuide(color: String, strokeWidth: Double) -> String
}

extension Point: GuideGeometry {
    /// Returns SVG markup for this point as a small crosshair construction guide.
    public func renderGuide(color: String, strokeWidth: Double) -> String {
        let arm = max(4.0, strokeWidth * 4)
        let h = Line(
            p0: Point(x: x - arm, y: y),
            p1: Point(x: x + arm, y: y))
        let v = Line(
            p0: Point(x: x, y: y - arm),
            p1: Point(x: x, y: y + arm))
        return renderLine(h, width: strokeWidth, stroke: color) + "\n"
            + renderLine(v, width: strokeWidth, stroke: color)
    }
}

extension Line: GuideGeometry {
    /// Returns SVG markup for this line as a construction guide.
    public func renderGuide(color: String, strokeWidth: Double) -> String {
        renderLine(self, width: strokeWidth, stroke: color)
    }
}

extension Circle: GuideGeometry {
    /// Returns SVG markup for this circle as a stroke-only construction guide.
    public func renderGuide(color: String, strokeWidth: Double) -> String {
        "<circle cx=\"\(formatCoord(center.x))\" cy=\"\(formatCoord(center.y))\" r=\"\(formatCoord(radius))\" fill=\"none\" stroke=\"\(color)\" stroke-width=\"\(formatCoord(strokeWidth))\"/>"
    }
}

extension Arc: GuideGeometry {
    /// Returns SVG markup for this arc as a construction guide.
    public func renderGuide(color: String, strokeWidth: Double) -> String {
        renderArc(self, width: strokeWidth, stroke: color)
    }
}

/// Returns SVG markup for a point drawn as a small crosshair construction guide.
/// - Parameters:
///   - point: The point to mark.
///   - color: CSS colour string for the stroke. Defaults to `defaultGuideColor`.
///   - strokeWidth: Stroke width in SVG units. Defaults to `defaultGuideStrokeWidth`.
public func renderGuide(
    _ point: Point, color: String = defaultGuideColor, strokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    point.renderGuide(color: color, strokeWidth: strokeWidth)
}

/// Returns SVG markup for a line drawn as a construction guide.
/// - Parameters:
///   - line: The line segment to draw.
///   - color: CSS colour string for the stroke. Defaults to `defaultGuideColor`.
///   - strokeWidth: Stroke width in SVG units. Defaults to `defaultGuideStrokeWidth`.
public func renderGuide(
    _ line: Line, color: String = defaultGuideColor, strokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    line.renderGuide(color: color, strokeWidth: strokeWidth)
}

/// Returns SVG markup for a circle drawn as a stroke-only construction guide.
/// - Parameters:
///   - circle: The circle to outline.
///   - color: CSS colour string for the stroke. Defaults to `defaultGuideColor`.
///   - strokeWidth: Stroke width in SVG units. Defaults to `defaultGuideStrokeWidth`.
public func renderGuide(
    _ circle: Circle, color: String = defaultGuideColor,
    strokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    circle.renderGuide(color: color, strokeWidth: strokeWidth)
}

/// Returns SVG markup for an arc drawn as a construction guide.
/// - Parameters:
///   - arc: The arc to draw.
///   - color: CSS colour string for the stroke. Defaults to `defaultGuideColor`.
///   - strokeWidth: Stroke width in SVG units. Defaults to `defaultGuideStrokeWidth`.
public func renderGuide(
    _ arc: Arc, color: String = defaultGuideColor, strokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    arc.renderGuide(color: color, strokeWidth: strokeWidth)
}
