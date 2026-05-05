import Foundation
import IOKit

@Observable
@MainActor
final class AmbientLightService {
    private(set) var currentLux: Double = 0
    private(set) var isAvailable: Bool = false

    private nonisolated(unsafe) var service: io_service_t = 0
    private nonisolated(unsafe) var timer: Timer?

    init() {
        // AppleALSColorSensor is the driver name; AppleSPUVD6286 is the actual IOClass
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSPUVD6286"))
        isAvailable = service != 0
        guard isAvailable else { return }
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.1
    }

    deinit {
        timer?.invalidate()
        if service != 0 { IOObjectRelease(service) }
    }

    private func update() {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return }

        if let lux = dict["CurrentLux"] as? Double {
            currentLux = lux
        } else if let lux = dict["CurrentLux"] as? Int {
            currentLux = Double(lux)
        }
    }
}
