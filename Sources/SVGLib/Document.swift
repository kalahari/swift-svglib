// SVGLib — Coordinate formatting, document wrapper, and file output.

import Foundation

/// Formats a Double as a 2-decimal-place string suitable for SVG coordinate attributes.
public func formatCoord(_ v: Double) -> String { String(format: "%.2f", v) }

/// Wraps SVG content in a root `<svg>` element with a rectangular viewBox.
///
/// Pass `guides` to overlay construction geometry (points, lines, circles, arcs) on top of
/// the finished content while iterating on an image. Guides are omitted when the array is empty.
/// - Parameters:
///   - content: The SVG markup to embed inside the root element.
///   - height: The height of the canvas in pixels. Defaults to 1024.
///   - width: The width of the canvas in pixels. Defaults to 1024.
///   - guides: Geometry drawn as stroke-only overlays after `content`. Defaults to none.
///   - guideColor: Stroke colour for all guides. Defaults to `defaultGuideColor`.
///   - guideStrokeWidth: Stroke width for all guides. Defaults to `defaultGuideStrokeWidth`.
public func renderDocument(
    _ content: String, height: Int = 1024, width: Int = 1024,
    guides: [any GuideGeometry] = [],
    guideColor: String = defaultGuideColor,
    guideStrokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    var body = content
    if !guides.isEmpty {
        let guideMarkup = guides.map {
            $0.renderGuide(color: guideColor, strokeWidth: guideStrokeWidth)
        }.joined(separator: "\n")
        body =
            content.isEmpty
            ? guideMarkup
            : content + "\n" + guideMarkup
    }
    return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="\(width)" height="\(height)">
        \(body)
        </svg>
        """
}

/// Wraps SVG content fragments in a root `<svg>` element with a rectangular viewBox.
/// Fragments are joined with newlines before embedding.
///
/// Pass `guides` to overlay construction geometry on top of the finished content while iterating
/// on an image. Guides are omitted when the array is empty.
/// - Parameters:
///   - content: SVG markup fragments to embed inside the root element.
///   - height: The height of the canvas in pixels. Defaults to 1024.
///   - width: The width of the canvas in pixels. Defaults to 1024.
///   - guides: Geometry drawn as stroke-only overlays after `content`. Defaults to none.
///   - guideColor: Stroke colour for all guides. Defaults to `defaultGuideColor`.
///   - guideStrokeWidth: Stroke width for all guides. Defaults to `defaultGuideStrokeWidth`.
public func renderDocument(
    _ content: [String], height: Int = 1024, width: Int = 1024,
    guides: [any GuideGeometry] = [],
    guideColor: String = defaultGuideColor,
    guideStrokeWidth: Double = defaultGuideStrokeWidth
) -> String {
    renderDocument(
        content.joined(separator: "\n"), height: height, width: width,
        guides: guides, guideColor: guideColor, guideStrokeWidth: guideStrokeWidth)
}

/// Writes an SVG string to a file, creating intermediate directories as needed.
/// Prints a confirmation on success, or an error message and exits with code 1 on failure.
/// - Parameters:
///   - content: The SVG markup to write.
///   - name: The filename (e.g. `"background.svg"`).
///   - directory: The output directory path. The file will be written to `directory/name`.
public func writeDocument(_ content: String, name: String, directory: String) {
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
