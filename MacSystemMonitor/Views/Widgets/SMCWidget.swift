import SwiftUI

struct SMCWidget: View {
    let smc: SMCService
    let thermal: ThermalService

    var body: some View {
        WidgetCard(title: "SMC", collapsedSummary: {
            if !smc.isAvailable {
                Text("N/A")
            } else {
                Text(collapsedText)
            }
        }) {
            if !smc.isAvailable {
                Text("SMC not available").font(.caption2).foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Temp", systemImage: "thermometer")
                            .font(.caption2).foregroundStyle(.secondary)
                        if let t = smc.cpuTemperature  { tempRow("CPU",  celsius: t) }
                        if let t = smc.gpuTemperature  { tempRow("GPU",  celsius: t) }
                        if let t = smc.batteryTemperature { tempRow("Bat", celsius: t) }
                        if let t = smc.skinTemperature { tempRow("Skin", celsius: t) }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        if let w = smc.systemPowerW {
                            statRow("Power", value: String(format: "%.1f W", w))
                        }
                        if smc.fanCount > 0 {
                            if let rpm = smc.fan0RPM { statRow("Fan 0", value: "\(rpm) RPM") }
                            if let rpm = smc.fan1RPM { statRow("Fan 1", value: "\(rpm) RPM") }
                        }
                    }
                }
            }
        }
    }

    private var collapsedText: String {
        var parts: [String] = []
        if let t = smc.cpuTemperature { parts.append(String(format: "%.0f°C", t)) }
        if let w = smc.systemPowerW   { parts.append(String(format: "%.1fW", w)) }
        if smc.fanCount > 0, let rpm = smc.fan0RPM { parts.append("\(rpm) RPM") }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func tempRow(_ label: String, celsius: Double) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 28, alignment: .leading)
            Text(String(format: "%.1f°C", celsius))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(thermal.color)
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Text(value).font(.caption2.monospacedDigit())
        }
    }


}
