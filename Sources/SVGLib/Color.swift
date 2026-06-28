// SVGLib — Color helpers.

import Foundation

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
