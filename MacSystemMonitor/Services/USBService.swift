import Foundation
import IOKit

struct USBDeviceInfo: Identifiable {
    let id: String
    let name: String
    let vendorID: Int
    let productID: Int
    var vidPid: String { String(format: "%04X:%04X", vendorID, productID) }
}

@Observable
@MainActor
final class USBService {
    private(set) var devices: [USBDeviceInfo] = []

    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.5
    }

    deinit { timer?.invalidate() }

    private func update() {
        var results: [USBDeviceInfo] = []
        guard let matching = IOServiceMatching("IOUSBDevice") else { return }
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            let productName = ioStringProperty(service, "USB Product Name")
                ?? ioStringProperty(service, "Product Name")
            guard let name = productName, !name.isEmpty else { continue }

            let vendorID    = ioIntProperty(service, "idVendor")    ?? 0
            let productID   = ioIntProperty(service, "idProduct")   ?? 0
            let locationID  = ioIntProperty(service, "locationID")  ?? results.count
            let idStr = "\(locationID):\(vendorID):\(productID):\(name)"
            results.append(USBDeviceInfo(id: idStr, name: name, vendorID: vendorID, productID: productID))
        }
        devices = results
    }

    private func ioStringProperty(_ entry: io_registry_entry_t, _ key: String) -> String? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? String
    }

    private func ioIntProperty(_ entry: io_registry_entry_t, _ key: String) -> Int? {
        (IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? NSNumber)?.intValue
    }
}
