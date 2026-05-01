import Foundation

@Observable
@MainActor
final class CPUService {
    private(set) var userPercent: Double = 0
    private(set) var sysPercent: Double = 0
    private(set) var idlePercent: Double = 1
    private(set) var history: [Double] = []
    private(set) var coreUsage: [Double] = []
    private(set) var chipName: String = ""
    private(set) var coreCount: Int = 0

    private var prevTicks: host_cpu_load_info?
    private var prevCoreTicks: [processor_cpu_load_info] = []
    private nonisolated(unsafe) var timer: Timer?

    init() {
        loadStaticInfo()
        start()
    }

    deinit { timer?.invalidate() }

    private func loadStaticInfo() {
        var size: Int = 256
        var buf = [CChar](repeating: 0, count: size)
        if sysctlbyname("machdep.cpu.brand_string", &buf, &size, nil, 0) == 0 {
            chipName = String(cString: buf)
        }
        var cores: Int32 = 0
        var coreSize = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &cores, &coreSize, nil, 0)
        coreCount = Int(cores)
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.1
    }

    private func update() {
        updateOverall()
        updatePerCore()
    }

    private func updateOverall() {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        if let prev = prevTicks {
            let user = Double(info.cpu_ticks.0 - prev.cpu_ticks.0)
            let sys  = Double(info.cpu_ticks.1 - prev.cpu_ticks.1)
            let idle = Double(info.cpu_ticks.2 - prev.cpu_ticks.2)
            let nice = Double(info.cpu_ticks.3 - prev.cpu_ticks.3)
            let total = user + sys + idle + nice
            guard total > 0 else { return }
            userPercent = user / total
            sysPercent  = sys  / total
            idlePercent = idle / total
            let used = (user + sys + nice) / total
            history.append(used)
            if history.count > 60 { history.removeFirst() }
        }
        prevTicks = info
    }

    private func updatePerCore() {
        var numCPUs: natural_t = 0
        var infoArray: processor_info_array_t?
        var numInfo: mach_msg_type_number_t = 0

        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &infoArray, &numInfo) == KERN_SUCCESS,
              let info = infoArray
        else { return }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numInfo) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        let stride = Int(CPU_STATE_MAX)
        var current: [processor_cpu_load_info] = (0..<Int(numCPUs)).map { i in
            let base = i * stride
            return processor_cpu_load_info(
                cpu_ticks: (
                    UInt32(info[base + Int(CPU_STATE_USER)]),
                    UInt32(info[base + Int(CPU_STATE_SYSTEM)]),
                    UInt32(info[base + Int(CPU_STATE_IDLE)]),
                    UInt32(info[base + Int(CPU_STATE_NICE)])
                )
            )
        }

        if prevCoreTicks.count == current.count {
            coreUsage = zip(current, prevCoreTicks).map { cur, prev in
                let user = Double(cur.cpu_ticks.0 &- prev.cpu_ticks.0)
                let sys  = Double(cur.cpu_ticks.1 &- prev.cpu_ticks.1)
                let idle = Double(cur.cpu_ticks.2 &- prev.cpu_ticks.2)
                let nice = Double(cur.cpu_ticks.3 &- prev.cpu_ticks.3)
                let total = user + sys + idle + nice
                return total > 0 ? (user + sys + nice) / total : 0
            }
        }
        prevCoreTicks = current
    }
}
