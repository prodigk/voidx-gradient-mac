import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: GradientStudioModel

    var body: some View {
        HStack(spacing: 0) {
            previewPane
            controlsPane
        }
        .background(AppStyle.canvas)
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VoidX Gradient")
                        .font(.system(size: 28, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("\(model.settings.safeWidth) x \(model.settings.safeHeight) / seed \(model.settings.seed)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()

                Button {
                    model.randomizeSeed()
                } label: {
                    Label("Random", systemImage: "shuffle")
                }
                .buttonStyle(PrimaryDarkButtonStyle())

                Button {
                    model.exportCurrentImage()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(OutlineDarkButtonStyle())
            }

            ZStack {
                AppStyle.previewBackplate

                if let image = model.previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.48), radius: 24, y: 18)
                        .padding(26)
                } else {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let url = model.lastExportURL {
                Text("Saved \(url.lastPathComponent)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.54))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.ink)
    }

    private var controlsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Generator")
                        .font(.system(size: 34, weight: .regular, design: .default))
                        .foregroundStyle(AppStyle.text)
                    Text("Dark ambient mesh gradients")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(AppStyle.muted)
                }

                controlGroup("Composition") {
                    Picker("Pattern", selection: patternBinding) {
                        ForEach(GradientPattern.allCases) { pattern in
                            Text(pattern.rawValue).tag(pattern)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Aspect", selection: aspectBinding) {
                        ForEach(AspectPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        numericField("Width", value: widthBinding)
                        numericField("Height", value: heightBinding)
                    }

                    numericField("Seed", value: seedBinding)

                    Picker("Format", selection: exportFormatBinding) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }

                controlGroup("Color Set") {
                    LazyVGrid(columns: colorColumns, alignment: .leading, spacing: 12) {
                        ForEach(model.settings.colors.indices, id: \.self) { index in
                            colorSwatch(index)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            model.addColor()
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .disabled(model.settings.colors.count >= 4)

                        Button {
                            model.removeLastColor()
                        } label: {
                            Label("Remove", systemImage: "minus")
                        }
                        .disabled(model.settings.colors.count <= 1)
                    }
                    .buttonStyle(.bordered)
                }

                controlGroup("Render") {
                    slider("Blobs", value: blobCountBinding, range: 5...12, step: 1)
                    slider("Blur", value: blurBinding, range: 20...140, step: 1)
                    slider("Brightness", value: brightnessBinding, range: 0.45...1.2, step: 0.01)
                    slider("Color", value: colorIntensityBinding, range: 0.35...1.35, step: 0.01)
                    slider("Vignette", value: vignetteBinding, range: 0.1...1.0, step: 0.01)
                    slider("Noise", value: noiseBinding, range: 0...0.09, step: 0.001)
                }

                HStack(spacing: 10) {
                    Button {
                        model.regenerate()
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryLightButtonStyle())

                    Button {
                        model.randomizeSeed()
                    } label: {
                        Label("Random", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryLightButtonStyle())
                }
            }
            .padding(26)
        }
        .frame(width: 390)
        .background(AppStyle.canvas)
    }

    private func controlGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.muted)
            content()
        }
        .padding(18)
        .background(AppStyle.stone)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func numericField<T: FixedWidthInteger>(_ title: String, value: Binding<T>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(AppStyle.muted)
            TextField(title, value: value, formatter: NumberFormatter.integer)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var colorColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 128), spacing: 12),
            GridItem(.flexible(minimum: 128), spacing: 12)
        ]
    }

    private func colorSwatch(_ index: Int) -> some View {
        HStack(spacing: 8) {
            Text("Color \(index + 1)")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.text)
                .lineLimit(1)
                .frame(width: 54, alignment: .leading)

            ColorPicker(selection: colorBinding(index), supportsOpacity: false) {
                EmptyView()
            }
            .labelsHidden()
            .frame(width: 44)
        }
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.text)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)

            Slider(value: value, in: range, step: step, onEditingChanged: { editing in
                if !editing {
                    model.regenerate()
                }
            })
            .labelsHidden()
            .controlSize(.small)
            .frame(maxWidth: .infinity)

            Text(value.wrappedValue.formatted(.number.precision(.fractionLength(step < 0.01 ? 3 : step < 1 ? 2 : 0))))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(AppStyle.muted)
                .lineLimit(1)
                .frame(width: 54, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 30)
    }

    private var patternBinding: Binding<GradientPattern> {
        Binding {
            model.settings.pattern
        } set: {
            model.settings.pattern = $0
            model.regenerate()
        }
    }

    private var aspectBinding: Binding<AspectPreset> {
        Binding {
            model.settings.aspectPreset
        } set: {
            model.applyAspectPreset($0)
        }
    }

    private var exportFormatBinding: Binding<ExportFormat> {
        Binding {
            model.settings.exportFormat
        } set: {
            model.settings.exportFormat = $0
        }
    }

    private var widthBinding: Binding<Int> {
        Binding {
            model.settings.width
        } set: {
            model.settings.width = $0
            model.settings.aspectPreset = .custom
            model.regenerate()
        }
    }

    private var heightBinding: Binding<Int> {
        Binding {
            model.settings.height
        } set: {
            model.settings.height = $0
            model.settings.aspectPreset = .custom
            model.regenerate()
        }
    }

    private var seedBinding: Binding<UInt64> {
        Binding {
            model.settings.seed
        } set: {
            model.settings.seed = $0
            model.regenerate()
        }
    }

    private var blobCountBinding: Binding<Double> {
        Binding {
            Double(model.settings.blobCount)
        } set: {
            model.settings.blobCount = Int($0.rounded())
        }
    }

    private var blurBinding: Binding<Double> {
        Binding {
            model.settings.blurIntensity
        } set: {
            model.settings.blurIntensity = $0
        }
    }

    private var brightnessBinding: Binding<Double> {
        Binding {
            model.settings.brightness
        } set: {
            model.settings.brightness = $0
        }
    }

    private var colorIntensityBinding: Binding<Double> {
        Binding {
            model.settings.colorIntensity
        } set: {
            model.settings.colorIntensity = $0
        }
    }

    private var vignetteBinding: Binding<Double> {
        Binding {
            model.settings.vignetteStrength
        } set: {
            model.settings.vignetteStrength = $0
        }
    }

    private var noiseBinding: Binding<Double> {
        Binding {
            model.settings.noiseAmount
        } set: {
            model.settings.noiseAmount = $0
        }
    }

    private func colorBinding(_ index: Int) -> Binding<Color> {
        Binding {
            model.settings.colors[index].swiftUIColor
        } set: { color in
            model.settings.colors[index] = RGBColor(color: color)
            model.regenerate()
        }
    }
}

private enum AppStyle {
    static let ink = Color(red: 0.02, green: 0.025, blue: 0.035)
    static let canvas = Color.white
    static let stone = Color(red: 0.933, green: 0.925, blue: 0.902)
    static let text = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let muted = Color(red: 0.46, green: 0.46, blue: 0.54)

    static var previewBackplate: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.006, green: 0.01, blue: 0.024))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct PrimaryDarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(.white.opacity(configuration.isPressed ? 0.72 : 0.96))
            .clipShape(Capsule())
    }
}

private struct OutlineDarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.08))
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
            .clipShape(Capsule())
    }
}

private struct PrimaryLightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.vertical, 11)
            .background(AppStyle.text.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(Capsule())
    }
}

private struct SecondaryLightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppStyle.text)
            .padding(.vertical, 11)
            .background(Color.white.opacity(configuration.isPressed ? 0.7 : 1))
            .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1))
            .clipShape(Capsule())
    }
}

private extension NumberFormatter {
    static var integer: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.allowsFloats = false
        return formatter
    }
}
