import AppKit

struct CodableColor: Codable, Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }

    init(nsColor: NSColor) {
        let converted = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        self.red = converted.redComponent
        self.green = converted.greenComponent
        self.blue = converted.blueComponent
        self.alpha = converted.alphaComponent
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    static let defaultBackground = CodableColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.75)

    static let presets: [CodableColor] = [
        CodableColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.75),
        CodableColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 0.75),
        CodableColor(red: 0.20, green: 0.12, blue: 0.15, alpha: 0.75),
        CodableColor(red: 0.10, green: 0.20, blue: 0.15, alpha: 0.75),
        CodableColor(red: 0.22, green: 0.18, blue: 0.10, alpha: 0.75),
        CodableColor(red: 0.18, green: 0.12, blue: 0.22, alpha: 0.75),
    ]
}
