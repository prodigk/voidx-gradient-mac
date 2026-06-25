import SwiftUI

@main
struct VoidXGradientApp: App {
    @StateObject private var model = GradientStudioModel()

    init() {
        if CommandLine.arguments.contains("--render-sample") {
            var settings = GradientSettings()
            settings.seed = 4819
            let outputIndex = CommandLine.arguments.firstIndex(of: "--output")
            let outputPath = outputIndex.flatMap { index -> String? in
                let nextIndex = CommandLine.arguments.index(after: index)
                return CommandLine.arguments.indices.contains(nextIndex) ? CommandLine.arguments[nextIndex] : nil
            } ?? "build/sample-gradient.png"
            let outputURL = URL(fileURLWithPath: outputPath)
            try? FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if let data = GradientRenderer.exportData(settings: settings, format: .png) {
                try? data.write(to: outputURL, options: .atomic)
            }
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1180, minHeight: 760)
                .onAppear {
                    model.regenerate()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Randomize Gradient") {
                    model.randomizeSeed()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Export Image...") {
                    model.exportCurrentImage()
                }
                .keyboardShortcut("e", modifiers: [.command])
            }
        }
    }
}
