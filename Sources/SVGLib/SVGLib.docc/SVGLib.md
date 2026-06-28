# ``SVGLib``

A Swift library for generating SVG documents programmatically.

## Overview

SVGLib provides tools for building SVG paths, shapes, and full documents from Swift code.
It covers geometry utilities for points, lines, arcs, and circles, along with path-building
helpers that can insert fillet arcs at selected corners — either with a uniform radius or
per-corner radii.

## Topics

### Building Paths

- ``buildPath(segments:close:filletRadius:filletRadii:)``
- ``arcPath(t0:t1:arc:)``
- ``arcShape(t0:t1:arc:thickness:fill:roundStart:roundEnd:)``
- ``PathSegment``

### SVG Document and Elements

- ``svgDoc(_:height:width:)``
- ``svgCircle(center:r:fill:)``
- ``svgLine(_:width:stroke:)``
- ``svgArc(_:width:stroke:)``
- ``svgCoord(_:)``
- ``writeSVG(_:name:directory:)``

### Geometry Types

- ``Point``
- ``Line``
- ``Circle``
- ``Arc``
- ``LineCoefficients``

### Coordinate Math

- ``midpoint(_:_:)``
- ``distance(_:_:)``
- ``squaredDistance(_:_:)``
- ``lineLength(_:)``
- ``svgPointAtAngle(deg:r:center:)``
- ``svgPtAtArcFraction(_:r:arc:)``
- ``arcAngleDegrees(_:arc:)``

### Line and Circle Operations

- ``lineIntersection(l1:l2:)``
- ``offsetLine(line:distance:)``
- ``extendLine(line:distance:)``
- ``lineCircleIntersections(line:center:radius:)``
- ``commonTangents(c1:c2:)``

### Fillet Helpers

- ``filletCenter(l1:l2:radius:)``
- ``filletCenter(line:arc:radius:)``
- ``areTangent(l1:l2:)``
- ``areTangent(line:arc:)``

### Triangle Utilities

- ``insetTriangle(p0:p1:p2:d:)``
