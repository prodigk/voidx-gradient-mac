import AppKit
import SwiftUI

@MainActor
final class GradientStudioModel: ObservableObject {
    @Published var settings = GradientSettings()
    @Published private(set) var previewImage: NSImage?
    @Published private(set) var lastExportURL: URL?
    @Published private(set) var isRendering = false

    func regenerate() {
        isRendering = true
        previewImage = GradientRenderer.renderImage(settings: settings)
        isRendering = false
    }

    func randomizeSeed() {
        settings.seed = UInt64.random(in: 1...UInt64.max)
        regenerate()
    }

    func addColor() {
        guard settings.colors.count < 4 else { return }
        let palette = [RGBColor(hex: 0x126DFF), RGBColor(hex: 0x5E4CFF), RGBColor(hex: 0x8C35FF), RGBColor(hex: 0x00D1C1)]
        settings.colors.append(palette[settings.colors.count % palette.count])
        regenerate()
    }

    func removeLastColor() {
        guard settings.colors.count > 1 else { return }
        settings.colors.removeLast()
        regenerate()
    }

    func applyAspectPreset(_ preset: AspectPreset) {
        settings.aspectPreset = preset
        if let size = preset.size() {
            settings.width = size.width
            settings.height = size.height
        }
        regenerate()
    }

    func exportCurrentImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [settings.exportFormat.contentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "voidx-gradient-\(settings.seed).\(settings.exportFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = GradientRenderer.exportData(settings: settings, format: settings.exportFormat) else { return }

        do {
            try data.write(to: url, options: .atomic)
            lastExportURL = url
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
