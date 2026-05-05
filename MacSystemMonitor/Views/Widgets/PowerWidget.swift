import SwiftUI

struct PowerWidget: View {
    let smc: SMCService

    var body: some View {
        WidgetCard(title: "Power", collapsedSummary: {
            if !smc.isAvailable {
                Text("N/A")
            } else if let w = smc.systemPowerW {
                Text(String(format: "%.1f W", w))
            }
        }) {
            if !smc.isAvailable {
                Text("SMC not available").font(.caption2).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    if let w = smc.systemPowerW {
                        statRow("Power", value: String(format: "%.1f W", w))
                    }
                    if smc.fanCount > 0 {
                        if let rpm = smc.fan0RPM { statRow("Fan 0", value: "\(rpm) RPM") }
                        if let rpm = smc.fan1RPM { statRow("Fan 1", value: "\(rpm) RPM") }
                    }
                    if smc.systemPowerW == nil && smc.fanCount == 0 {
                        Text("No data").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
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
