import Foundation
import Darwin

struct ProcessMemInfo: Identifiable {
    let id: Int32  // pid
    let name: String
    let residentBytes: Int64
}

@Observable
@MainActor
final class MemoryService {
    private(set) var usedGB: Double = 0
    private(set) var wiredGB: Double = 0
    private(set) var compressedGB: Double = 0
    private(set) var freeGB: Double = 0
    private(set) var totalGB: Double = 0
    private(set) var swapInMB: Double = 0
    private(set) var swapOutMB: Double = 0
    private(set) var topProcesses: [ProcessMemInfo] = []

    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.2
    }

    deinit { timer?.invalidate() }

    private func update() {
        updateVM()
        updateProcesses()
    }

    private func updateVM() {
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let page = Double(pageSize)
        let gb = 1_073_741_824.0
        usedGB       = Double(stats.active_count) * page / gb
        wiredGB      = Double(stats.wire_count)   * page / gb
        compressedGB = Double(stats.compressor_page_count) * page / gb
        freeGB       = Double(stats.free_count)   * page / gb
        totalGB      = usedGB + wiredGB + compressedGB + freeGB
        swapInMB     = Double(stats.swapins)  / 256.0
        swapOutMB    = Double(stats.swapouts) / 256.0
    }

    private func updateProcesses() {
        let bufSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bufSize > 0 else { return }
        var pids = [Int32](repeating: 0, count: Int(bufSize) / MemoryLayout<Int32>.size)
        proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bufSize)

        var results: [ProcessMemInfo] = []
        for pid in pids where pid > 0 {
            var info = proc_taskinfo()
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
            guard ret > 0, info.pti_resident_size > 0 else { continue }

            var nameBuf = [CChar](repeating: 0, count: 1024)
            proc_name(pid, &nameBuf, UInt32(nameBuf.count))
            let name = String(cString: nameBuf).isEmpty ? "(\(pid))" : String(cString: nameBuf)

            results.append(ProcessMemInfo(
                id: pid,
                name: name,
                residentBytes: Int64(info.pti_resident_size)
            ))
        }

        topProcesses = results
            .sorted { $0.residentBytes > $1.residentBytes }
            .prefix(15)
            .map { $0 }
    }
}
