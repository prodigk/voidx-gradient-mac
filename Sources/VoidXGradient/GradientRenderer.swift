import AppKit
import CoreImage
import SwiftUI

enum GradientRenderer {
    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ciContext = CIContext(options: [
        .workingColorSpace: colorSpace,
        .outputColorSpace: colorSpace
    ])

    static func renderImage(settings: GradientSettings) -> NSImage {
        let cgImage = renderCGImage(settings: settings)
        let image = NSImage(size: NSSize(width: settings.safeWidth, height: settings.safeHeight))
        image.addRepresentation(NSBitmapImageRep(cgImage: cgImage))
        return image
    }

    static func exportData(settings: GradientSettings, format: ExportFormat) -> Data? {
        let cgImage = renderCGImage(settings: settings)
        let rep = NSBitmapImageRep(cgImage: cgImage)
        let properties: [NSBitmapImageRep.PropertyKey: Any] = format == .jpeg
            ? [.compressionFactor: 0.95]
            : [:]
        return rep.representation(using: format.bitmapType, properties: properties)
    }

    static func renderCGImage(settings: GradientSettings) -> CGImage {
        let width = settings.safeWidth
        let height = settings.safeHeight
        var rng = SplitMix64(seed: settings.seed)

        let context = makeContext(width: width, height: height)
        drawBase(in: context, width: width, height: height)
        drawBlobs(in: context, width: width, height: height, settings: settings, rng: &rng)

        let rawImage = context.makeImage()!
        let blurredImage = blur(rawImage, radius: settings.blurIntensity)

        let finalContext = makeContext(width: width, height: height)
        finalContext.draw(blurredImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        drawVignette(in: finalContext, width: width, height: height, strength: settings.vignetteStrength)
        drawNoise(in: finalContext, width: width, height: height, amount: settings.noiseAmount, rng: &rng)
        return finalContext.makeImage()!
    }

    private static func makeContext(width: Int, height: Int) -> CGContext {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
    }

    private static func drawBase(in context: CGContext, width: Int, height: Int) {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let canvasWidth = Double(width)
        let canvasHeight = Double(height)
        context.setFillColor(NSColor(srgbRed: 0.012, green: 0.016, blue: 0.045, alpha: 1).cgColor)
        context.fill(rect)

        let colors = [
            NSColor(srgbRed: 0.02, green: 0.05, blue: 0.12, alpha: 0.62).cgColor,
            NSColor(srgbRed: 0.0, green: 0.01, blue: 0.03, alpha: 0.96).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: canvasWidth * 0.35, y: canvasHeight * 1.15),
            end: CGPoint(x: canvasWidth * 0.9, y: -canvasHeight * 0.1),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    private static func drawBlobs(
        in context: CGContext,
        width: Int,
        height: Int,
        settings: GradientSettings,
        rng: inout SplitMix64
    ) {
        let canvasMax = Double(max(width, height))
        let colors = settings.colors.isEmpty ? GradientSettings().colors : settings.colors
        let count = min(max(settings.blobCount, 5), 12)

        context.setBlendMode(.screen)

        for index in 0..<count {
            var spec = blobSpec(index: index, count: count, canvasMax: canvasMax, settings: settings, rng: &rng)
            spec.color = colors[index % colors.count]
            drawBlob(spec, in: context, width: width, height: height, settings: settings)
        }

        context.setBlendMode(.normal)
    }

    private static func blobSpec(
        index: Int,
        count: Int,
        canvasMax: Double,
        settings: GradientSettings,
        rng: inout SplitMix64
    ) -> BlobSpec {
        var x = rng.nextDouble(in: -0.18...1.18)
        var y = rng.nextDouble(in: -0.22...1.18)
        var radius = canvasMax * rng.nextDouble(in: 0.28...0.68)
        var aspectX = rng.nextDouble(in: 0.75...1.7)
        var aspectY = rng.nextDouble(in: 0.72...1.55)

        switch settings.pattern {
        case .ambient:
            if index == 0 {
                x = rng.nextDouble(in: 0.38...0.68)
                y = rng.nextDouble(in: 0.38...0.68)
                radius = canvasMax * rng.nextDouble(in: 0.54...0.82)
            }
        case .horizon:
            y = rng.nextDouble(in: 0.15...0.72)
            x = Double(index) / Double(max(count - 1, 1)) + rng.nextDouble(in: -0.2...0.2)
            aspectX *= rng.nextDouble(in: 1.2...2.1)
        case .nebula:
            let angle = rng.nextDouble(in: -0.35...0.35) + Double(index) * 0.18
            x = 0.5 + cos(angle) * rng.nextDouble(in: -0.45...0.45)
            y = 0.52 + sin(angle) * rng.nextDouble(in: -0.35...0.35)
            radius = canvasMax * rng.nextDouble(in: 0.38...0.78)
        case .orbit:
            let angle = (Double(index) / Double(count)) * .pi * 2 + rng.nextDouble(in: -0.45...0.45)
            let distance = rng.nextDouble(in: 0.12...0.48)
            x = 0.52 + cos(angle) * distance
            y = 0.48 + sin(angle) * distance
            radius = canvasMax * rng.nextDouble(in: 0.3...0.58)
        case .veil:
            x = rng.nextDouble(in: -0.08...1.08)
            y = rng.nextDouble(in: -0.1...1.12)
            radius = canvasMax * rng.nextDouble(in: 0.45...0.86)
            aspectX *= rng.nextDouble(in: 1.35...2.35)
            aspectY *= rng.nextDouble(in: 0.65...1.1)
        }

        return BlobSpec(
            x: x,
            y: y,
            radius: radius,
            aspectX: aspectX,
            aspectY: aspectY,
            opacity: rng.nextDouble(in: 0.18...0.48),
            color: RGBColor(hex: 0x126DFF)
        )
    }

    private static func drawBlob(
        _ spec: BlobSpec,
        in context: CGContext,
        width: Int,
        height: Int,
        settings: GradientSettings
    ) {
        let base = spec.color.nsColor.usingColorSpace(.sRGB) ?? .systemBlue
        let saturationBoost = CGFloat(settings.colorIntensity)
        let brightness = CGFloat(settings.brightness)
        let color = NSColor(
            hue: base.hueComponent,
            saturation: min(1, base.saturationComponent * saturationBoost * 1.35),
            brightness: min(1, max(0.05, base.brightnessComponent * brightness * 1.18)),
            alpha: min(0.72, spec.opacity * settings.brightness)
        )

        let center = CGPoint(x: spec.x * Double(width), y: spec.y * Double(height))
        let radius = CGFloat(spec.radius)
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                color.withAlphaComponent(color.alphaComponent).cgColor,
                color.withAlphaComponent(color.alphaComponent * 0.38).cgColor,
                color.withAlphaComponent(color.alphaComponent * 0.08).cgColor,
                color.withAlphaComponent(0).cgColor
            ] as CFArray,
            locations: [0, 0.34, 0.72, 1]
        )!

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: CGFloat(spec.aspectX), y: CGFloat(spec.aspectY))
        context.drawRadialGradient(
            gradient,
            startCenter: .zero,
            startRadius: 0,
            endCenter: .zero,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    private static func blur(_ image: CGImage, radius: Double) -> CGImage {
        let input = CIImage(cgImage: image)
        let clamped = input.clampedToExtent()
        let blurred = clamped
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(0, radius)])
            .cropped(to: input.extent)
        return ciContext.createCGImage(blurred, from: input.extent) ?? image
    }

    private static func drawVignette(in context: CGContext, width: Int, height: Int, strength: Double) {
        let maxRadius = CGFloat(max(width, height)) * 0.78
        let colors = [
            NSColor.black.withAlphaComponent(0).cgColor,
            NSColor.black.withAlphaComponent(CGFloat(strength * 0.28)).cgColor,
            NSColor.black.withAlphaComponent(CGFloat(strength * 0.88)).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.62, 1])!
        context.setBlendMode(.multiply)
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: width / 2, y: height / 2),
            startRadius: CGFloat(min(width, height)) * 0.22,
            endCenter: CGPoint(x: width / 2, y: height / 2),
            endRadius: maxRadius,
            options: [.drawsAfterEndLocation]
        )
        context.setBlendMode(.normal)
    }

    private static func drawNoise(
        in context: CGContext,
        width: Int,
        height: Int,
        amount: Double,
        rng: inout SplitMix64
    ) {
        guard amount > 0 else { return }

        let noiseWidth = max(160, min(480, width / 4))
        let noiseHeight = max(90, min(270, height / 4))
        var pixels = [UInt8](repeating: 0, count: noiseWidth * noiseHeight * 4)

        for i in stride(from: 0, to: pixels.count, by: 4) {
            let value = UInt8(rng.next() & 0xff)
            pixels[i] = value
            pixels[i + 1] = value
            pixels[i + 2] = value
            pixels[i + 3] = UInt8(max(0, min(255, amount * 255)))
        }

        pixels.withUnsafeMutableBytes { pointer in
            guard let data = pointer.baseAddress else { return }
            let noiseContext = CGContext(
                data: data,
                width: noiseWidth,
                height: noiseHeight,
                bitsPerComponent: 8,
                bytesPerRow: noiseWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            guard let image = noiseContext?.makeImage() else { return }
            context.saveGState()
            context.setAlpha(CGFloat(min(0.14, amount * 2.5)))
            context.setBlendMode(.overlay)
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            context.restoreGState()
        }
    }
}
