import SwiftUI

struct WiFiWidget: View {
    let wifi: WiFiService

    var body: some View {
        WidgetCard(title: "Wi-Fi", collapsedSummary: {
            Text(wifi.isConnected ? wifi.ssid : "Disconnected")
                .foregroundStyle(wifi.isConnected ? .primary : .secondary)
        }) {
            if wifi.isConnected {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wifi.ssid)
                            .font(.caption2.bold())
                            .lineLimit(1)
                        infoRow("RSSI",  "\(wifi.rssi) dBm",  signalColor(wifi.rssi))
                        infoRow("Noise", "\(wifi.noise) dBm", secondary: true)
                        infoRow("Ch",    "\(wifi.channel)",    secondary: true)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("TX Rate").font(.caption2).foregroundStyle(.secondary)
                        Text(String(format: "%.0f Mbps", wifi.txRate))
                            .font(.caption2.monospacedDigit())
                    }
                }
            } else {
                Text("Not Connected")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func signalColor(_ rssi: Int) -> Color {
        rssi >= -50 ? .green : rssi >= -70 ? .yellow : .red
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String, secondary: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Text(value).font(.caption2.monospacedDigit()).foregroundStyle(secondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Text(value).font(.caption2.monospacedDigit()).foregroundStyle(color)
        }
    }
}
