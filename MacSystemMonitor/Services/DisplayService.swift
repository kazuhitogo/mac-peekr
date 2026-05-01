import AppKit

struct DisplayInfo: Identifiable {
    let id = UUID()
    let name: String
    let resolution: CGSize
    let refreshRate: Int
    let isMain: Bool
}

@Observable
@MainActor
final class DisplayService {
    private(set) var displays: [DisplayInfo] = []

    init() {
        update()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
    }

    private func update() {
        displays = NSScreen.screens.map { screen in
            DisplayInfo(
                name: screen.localizedName,
                resolution: screen.frame.size,
                refreshRate: screen.maximumFramesPerSecond,
                isMain: screen == NSScreen.main
            )
        }
    }
}
