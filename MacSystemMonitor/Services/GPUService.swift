import Metal
import IOKit

@Observable
@MainActor
final class GPUService {
    private(set) var name: String = ""
    private(set) var maxBufferLengthGB: Double = 0
    private(set) var deviceUtilization: Int = 0
    private(set) var rendererUtilization: Int = 0
    private(set) var tilerUtilization: Int = 0
    private(set) var history: [Double] = []

    private nonisolated(unsafe) var timer: Timer?
    private nonisolated(unsafe) var service: io_service_t = 0

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            name = device.name
            maxBufferLengthGB = Double(device.maxBufferLength) / 1_073_741_824
        }
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOAccelerator"))
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
        guard service != 0 else { return }
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any],
              let perf = dict["PerformanceStatistics"] as? [String: Any]
        else { return }

        deviceUtilization   = perf["Device Utilization %"]   as? Int ?? 0
        rendererUtilization = perf["Renderer Utilization %"] as? Int ?? 0
        tilerUtilization    = perf["Tiler Utilization %"]    as? Int ?? 0

        history.append(Double(deviceUtilization) / 100.0)
        if history.count > 60 { history.removeFirst() }
    }
}
