import AppKit
import IOKit

struct DisplayInfo: Identifiable {
    let id = UUID()
    let name: String
    let resolution: CGSize
    let refreshRate: Int
    let isMain: Bool
    let brightness: Float?
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
        let brightnesses = fetchBrightnesses()
        displays = NSScreen.screens.enumerated().map { index, screen in
            DisplayInfo(
                name: screen.localizedName,
                resolution: screen.frame.size,
                refreshRate: screen.maximumFramesPerSecond,
                isMain: screen == NSScreen.main,
                brightness: index < brightnesses.count ? brightnesses[index] : nil
            )
        }
    }

    private func fetchBrightnesses() -> [Float] {
        var result: [Float] = []
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
                                          IOServiceMatching("IODisplayConnect"),
                                          &iterator) == kIOReturnSuccess else { return result }
        defer { IOObjectRelease(iterator) }
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            var brightness: Float = 0
            if IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness) == kIOReturnSuccess {
                result.append(brightness)
            }
            service = IOIteratorNext(iterator)
        }
        return result
    }
}
