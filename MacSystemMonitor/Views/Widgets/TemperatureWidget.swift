import SwiftUI

struct TemperatureWidget: View {
    let smc: SMCService
    let thermal: ThermalService

    var body: some View {
        WidgetCard(title: "Temperature", collapsedSummary: {
            if !smc.isAvailable {
                Text("N/A")
            } else if let t = smc.cpuTemperature {
                Text(String(format: "CPU %.0f°C", t))
                    .foregroundStyle(thermal.color)
            }
        }) {
            if !smc.isAvailable {
                Text("SMC not available").font(.caption2).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    if let t = smc.cpuTemperature      { tempRow("CPU",  celsius: t) }
                    if let t = smc.gpuTemperature      { tempRow("GPU",  celsius: t) }
                    if let t = smc.batteryTemperature  { tempRow("Bat",  celsius: t) }
                    if let t = smc.skinTemperature     { tempRow("Skin", celsius: t) }
                }
            }
        }
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
}
