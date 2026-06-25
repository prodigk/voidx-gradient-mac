import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RGBColor: Hashable, Codable, Identifiable {
    var id: String { hexString }
    var red: Double
    var green: Double
    var blue: Double

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    var swiftUIColor: Color {
        Color(nsColor)
    }

    var hexString: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xff) / 255
        green = Double((hex >> 8) & 0xff) / 255
        blue = Double(hex & 0xff) / 255
    }

    init(color: Color) {
        let converted = NSColor(color).usingColorSpace(.sRGB) ?? .white
        red = Double(converted.redComponent)
        green = Double(converted.greenComponent)
        blue = Double(converted.blueComponent)
    }
}

enum GradientPattern: String, CaseIterable, Identifiable {
    case ambient = "Ambient"
    case horizon = "Horizon"
    case nebula = "Nebula"
    case orbit = "Orbit"
    case veil = "Veil"

    var id: String { rawValue }
}

enum AspectPreset: String, CaseIterable, Identifiable {
    case widescreen = "16:9"
    case square = "1:1"
    case portrait = "4:5"
    case ultrawide = "21:9"
    case custom = "Custom"

    var id: String { rawValue }

    func size(forLongEdge longEdge: Int = 1920) -> (width: Int, height: Int)? {
        switch self {
        case .widescreen:
            return (1920, 1080)
        case .square:
            return (1600, 1600)
        case .portrait:
            return (1440, 1800)
        case .ultrawide:
            return (2100, 900)
        case .custom:
            return nil
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        }
    }

    var bitmapType: NSBitmapImageRep.FileType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        }
    }

    var contentType: UTType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        }
    }
}

struct GradientSettings {
    var seed: UInt64 = UInt64.random(in: 1...UInt64.max)
    var pattern: GradientPattern = .ambient
    var aspectPreset: AspectPreset = .widescreen
    var exportFormat: ExportFormat = .png
    var width: Int = 1920
    var height: Int = 1080
    var blobCount: Int = 8
    var blurIntensity: Double = 72
    var brightness: Double = 0.84
    var colorIntensity: Double = 0.9
    var vignetteStrength: Double = 0.78
    var noiseAmount: Double = 0.035
    var colors: [RGBColor] = [
        RGBColor(hex: 0x126DFF),
        RGBColor(hex: 0x5E4CFF),
        RGBColor(hex: 0x7D31C9),
        RGBColor(hex: 0x0DB8C8)
    ]

    var safeWidth: Int { min(max(width, 320), 8192) }
    var safeHeight: Int { min(max(height, 320), 8192) }
}

struct BlobSpec {
    var x: Double
    var y: Double
    var radius: Double
    var aspectX: Double
    var aspectY: Double
    var opacity: Double
    var color: RGBColor
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        Int(nextDouble(in: Double(range.lowerBound)...Double(range.upperBound)).rounded())
    }
}
