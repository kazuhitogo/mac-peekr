import Foundation
import Darwin

struct InterfaceStats: Identifiable {
    let id = UUID()
    let name: String
    let uploadSpeed: Double
    let downloadSpeed: Double
    let totalSent: Int64
    let totalReceived: Int64
}

@Observable
@MainActor
final class NetworkService {
    private(set) var interfaces: [InterfaceStats] = []

    private var prevBytes: [String: (in: UInt64, out: UInt64)] = [:]
    private var prevTime: Date = .now
    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.1
    }

    deinit { timer?.invalidate() }

    private func update() {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return }
        defer { freeifaddrs(ifap) }

        var current: [String: (in: UInt64, out: UInt64)] = [:]
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let name = String(cString: p.pointee.ifa_name)
            guard !name.hasPrefix("lo"),
                  p.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK)
            else { ptr = p.pointee.ifa_next; continue }

            if let data = p.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                let prev = current[name] ?? (0, 0)
                current[name] = (
                    prev.in  + UInt64(data.pointee.ifi_ibytes),
                    prev.out + UInt64(data.pointee.ifi_obytes)
                )
            }
            ptr = p.pointee.ifa_next
        }

        let elapsed = Date.now.timeIntervalSince(prevTime)
        guard elapsed > 0 else { prevBytes = current; prevTime = .now; return }

        interfaces = current.compactMap { name, bytes in
            let prev = prevBytes[name] ?? bytes
            let dl = elapsed > 0 ? Double(bytes.in  &- prev.in)  / elapsed : 0
            let ul = elapsed > 0 ? Double(bytes.out &- prev.out) / elapsed : 0
            return InterfaceStats(
                name: name,
                uploadSpeed: max(0, ul),
                downloadSpeed: max(0, dl),
                totalSent: Int64(bitPattern: bytes.out),
                totalReceived: Int64(bitPattern: bytes.in)
            )
        }.sorted { $0.name < $1.name }

        prevBytes = current
        prevTime = .now
    }
}
