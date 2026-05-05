import SwiftUI

struct BatteryWidget: View {
    let battery: BatteryService

    var body: some View {
        WidgetCard(title: "Battery", collapsedSummary: {
            if battery.hasBattery {
                Text(String(format: "%.0f%% · %@",
                            battery.chargePercent * 100,
                            battery.isCharging ? "Charging" : battery.isOnAC ? "AC" : "Discharging"))
            } else {
                Text("AC Power")
            }
        }) {
            if !battery.hasBattery {
                HStack {
                    Image(systemName: "powerplug.fill")
                    Text("AC Power").font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    DonutChartView(value: battery.chargePercent, color: battery.isCharging ? .green : .blue)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: battery.isCharging ? "bolt.fill" : battery.isOnAC ? "powerplug.fill" : "battery.75")
                                .font(.caption2)
                                .foregroundStyle(battery.isCharging ? .green : .secondary)
                            Text(battery.isCharging ? "Charging" : battery.isOnAC ? "AC" : "Discharging")
                                .font(.caption2)
                        }
                        infoRow("Cycles", value: "\(battery.cycleCount)")
                        if let deg = battery.degradationPercent {
                            infoRow("Capacity", value: String(format: "%.1f%%", deg))
                        }
                        if !battery.healthStatus.isEmpty {
                            infoRow("Health", value: battery.healthStatus)
                        }
                        if let v = battery.voltageV {
                            infoRow("Voltage", value: String(format: "%.2f V", v))
                        }
                        if let ma = battery.currentMA {
                            let sign = ma >= 0 ? "+" : ""
                            infoRow("Current", value: "\(sign)\(ma) mA")
                        }
                        if let w = battery.powerW {
                            infoRow("Power", value: String(format: "%.1f W", w))
                        }
                        if let aw = battery.adapterWatts {
                            infoRow("Adapter", value: "\(aw) W")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 44, alignment: .leading)
            Text(value).font(.caption2.monospacedDigit())
        }
    }
}
