import Foundation
import IOKit.ps
import IOKit

@Observable
@MainActor
final class BatteryService {
    private(set) var chargePercent: Double = 0
    private(set) var isCharging: Bool = false
    private(set) var isOnAC: Bool = false
    private(set) var cycleCount: Int = 0
    private(set) var healthStatus: String = ""
    private(set) var hasBattery: Bool = false
    private(set) var degradationPercent: Double? = nil  // nil = 取得不可

    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 5
    }

    deinit { timer?.invalidate() }

    private func update() {
        updateFromIOPS()
        updateFromIORegistry()
    }

    private func updateFromIOPS() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              !list.isEmpty
        else { hasBattery = false; return }
        hasBattery = true

        for src in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, src)?.takeUnretainedValue() as? [String: Any] else { continue }
            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max     = desc[kIOPSMaxCapacityKey]     as? Int ?? 100
            chargePercent = max > 0 ? Double(current) / Double(max) : 0
            isCharging    = desc[kIOPSIsChargingKey] as? Bool ?? false
            isOnAC        = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            cycleCount    = desc["CycleCount"] as? Int ?? 0
            healthStatus  = desc[kIOPSBatteryHealthKey] as? String ?? ""
            break
        }
    }

    private func updateFromIORegistry() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return }

        if cycleCount == 0, let cc = dict["CycleCount"] as? Int { cycleCount = cc }

        if let rawMax    = dict["AppleRawMaxCapacity"] as? Int,
           let designCap = dict["DesignCapacity"]      as? Int,
           designCap > 0 {
            degradationPercent = Double(rawMax) / Double(designCap) * 100.0
        }
    }
}
