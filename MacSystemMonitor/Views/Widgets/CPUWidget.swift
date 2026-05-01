import SwiftUI

struct CPUWidget: View {
    let cpu: CPUService

    var body: some View {
        WidgetCard(title: "CPU", collapsedSummary: {
            Text(String(format: "%.1f%%", (cpu.userPercent + cpu.sysPercent) * 100))
        }) {
            LineChartView(data: cpu.history, color: .green)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    statRow("User", value: cpu.userPercent)
                    statRow("Sys",  value: cpu.sysPercent)
                    statRow("Idle", value: cpu.idlePercent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(cpu.chipName.isEmpty ? "—" : cpu.chipName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    Text("\(cpu.coreCount) cores")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !cpu.coreUsage.isEmpty {
                Divider().padding(.vertical, 2)
                coreGrid
            }
        }
    }

    @ViewBuilder
    private var coreGrid: some View {
        let cols = 2
        let cores = cpu.coreUsage
        let rows = (cores.count + cols - 1) / cols
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < cores.count {
                            coreBar(index: idx, usage: cores[idx])
                        } else {
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func coreBar(index: Int, usage: Double) -> some View {
        HStack(spacing: 4) {
            Text("C\(index)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(coreColor(usage))
                        .frame(width: geo.size.width * min(usage, 1))
                }
            }
            .frame(height: 6)
            Text(String(format: "%2.0f%%", usage * 100))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
    }

    private func coreColor(_ usage: Double) -> Color {
        usage > 0.8 ? .red : usage > 0.5 ? .yellow : .green
    }

    @ViewBuilder
    private func statRow(_ label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
            Text(String(format: "%.1f%%", value * 100))
                .font(.caption2.monospacedDigit())
        }
    }
}
