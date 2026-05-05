import Foundation
import IOKit

private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

private struct SMCKeyInfoData {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
    var _pad: (UInt8, UInt8, UInt8) = (0, 0, 0)  // C struct trailing padding (4-byte align)
}

private struct SMCParamStruct {
    var key: UInt32 = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

@Observable
@MainActor
final class SMCService {
    private(set) var cpuTemperature: Double? = nil
    private(set) var gpuTemperature: Double? = nil
    private(set) var batteryTemperature: Double? = nil
    private(set) var skinTemperature: Double? = nil
    private(set) var systemPowerW: Double? = nil
    private(set) var fan0RPM: Int? = nil
    private(set) var fan1RPM: Int? = nil
    private(set) var fanCount: Int = 0
    private(set) var isAvailable: Bool = false

    private nonisolated(unsafe) var connection: io_connect_t = 0
    private nonisolated(unsafe) var timer: Timer?

    init() {
        assert(MemoryLayout<SMCParamStruct>.size == 80,
               "SMCParamStruct size mismatch: \(MemoryLayout<SMCParamStruct>.size)")
        isAvailable = openConnection()
        guard isAvailable else { return }
        detectFanCount()
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.5
    }

    deinit {
        timer?.invalidate()
        if connection != 0 { IOServiceClose(connection) }
    }

    private func openConnection() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }
        return IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess
    }

    private func detectFanCount() {
        if let (data, _) = readKey("FNum"), !data.isEmpty {
            fanCount = Int(data[0])
        }
    }

    private func update() {
        // CPU: max across all core proximity keys
        let cpuKeys = ["Tp09", "Tp0b", "Tp0D", "Tp0E", "Tp01", "Tp05", "Tp0P", "TC0P", "TC0D"]
        let cpuTemps = cpuKeys.compactMap { readTemperature(key: $0) }.filter { $0 > 0 && $0 < 150 }
        cpuTemperature = cpuTemps.isEmpty ? nil : cpuTemps.max()

        // GPU
        for key in ["Tg0D", "Tg05", "TGDD"] {
            if let t = readTemperature(key: key), t > 0, t < 150 {
                gpuTemperature = t; break
            }
        }

        // Battery temp (average of available cells)
        let batTemps = ["TB0T", "TB1T", "TB2T"].compactMap { readTemperature(key: $0) }.filter { $0 > 0 && $0 < 80 }
        batteryTemperature = batTemps.isEmpty ? nil : batTemps.reduce(0, +) / Double(batTemps.count)

        // Skin/palm temp
        skinTemperature = ["Ts0S", "Ts0P"].compactMap { readTemperature(key: $0) }.filter { $0 > 0 && $0 < 80 }.first

        // System power draw
        if let (data, type) = readKey("PSTR"), type == smcKey("flt "), let w = flt(data), w > 0 {
            systemPowerW = w
        }

        if fanCount > 0 { fan0RPM = readFanRPM(key: "F0Ac") }
        if fanCount > 1 { fan1RPM = readFanRPM(key: "F1Ac") }
    }

    private func readTemperature(key: String) -> Double? {
        guard let (data, type) = readKey(key) else { return nil }
        switch type {
        case smcKey("sp78"): return sp78(data)
        case smcKey("flt "): return flt(data)
        default: return nil
        }
    }

    private func readFanRPM(key: String) -> Int? {
        guard let (data, type) = readKey(key),
              type == smcKey("fpe2"),
              data.count >= 2 else { return nil }
        let raw = UInt16(data[0]) << 8 | UInt16(data[1])
        return Int(raw >> 2)
    }

    private func readKey(_ key: String) -> (Data, UInt32)? {
        var input = SMCParamStruct()
        input.key = smcKey(key)
        input.data8 = 9
        guard let info = callSMC(&input) else { return nil }

        var read = SMCParamStruct()
        read.key = smcKey(key)
        read.keyInfo.dataSize = info.keyInfo.dataSize
        read.data8 = 5
        guard let result = callSMC(&read) else { return nil }

        let bytes = withUnsafeBytes(of: result.bytes) { Data($0) }
        return (bytes.prefix(Int(info.keyInfo.dataSize)), info.keyInfo.dataType)
    }

    private func callSMC(_ input: inout SMCParamStruct) -> SMCParamStruct? {
        var output = SMCParamStruct()
        var size = MemoryLayout<SMCParamStruct>.size
        let r = IOConnectCallStructMethod(connection, 2, &input, MemoryLayout<SMCParamStruct>.size, &output, &size)
        guard r == kIOReturnSuccess else { return nil }
        return output
    }

    private func smcKey(_ str: String) -> UInt32 {
        let c = Array(str.utf8.prefix(4))
        guard c.count == 4 else { return 0 }
        return UInt32(c[0]) << 24 | UInt32(c[1]) << 16 | UInt32(c[2]) << 8 | UInt32(c[3])
    }

    private func sp78(_ data: Data) -> Double? {
        guard data.count >= 2 else { return nil }
        let raw = Int16(bitPattern: UInt16(data[0]) << 8 | UInt16(data[1]))
        return Double(raw) / 256.0
    }

    private func flt(_ data: Data) -> Double? {
        guard data.count >= 4 else { return nil }
        var f: Float = 0
        _ = withUnsafeMutableBytes(of: &f) { data.copyBytes(to: $0) }
        return Double(f)
    }
}
