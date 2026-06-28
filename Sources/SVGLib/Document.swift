// SVGLib — Coordinate formatting, document wrapper, and file output.

import Foundation

/// Formats a Double as a 2-decimal-place string suitable for SVG coordinate attributes.
public func svgCoord(_ v: Double) -> String { String(format: "%.2f", v) }

/// Wraps SVG content in a root `<svg>` element with a rectangular viewBox.
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
