import SwiftUI

struct GPUWidget: View {
    let gpu: GPUService

    var body: some View {
        WidgetCard(title: "GPU") {
            LineChartView(data: gpu.history, color: .purple)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(gpu.name.isEmpty ? "Not available" : gpu.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    Text(String(format: "Max Buf %.0f GB", gpu.maxBufferLengthGB))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    statRow("Device",   value: gpu.deviceUtilization)
                    statRow("Renderer", value: gpu.rendererUtilization)
                    statRow("Tiler",    value: gpu.tilerUtilization)
                }
            }
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)%")
                .font(.caption2.monospacedDigit())
        }
    }
}
