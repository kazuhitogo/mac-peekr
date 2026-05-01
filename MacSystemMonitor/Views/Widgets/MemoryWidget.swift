import SwiftUI

struct MemoryWidget: View {
    let memory: MemoryService

    var body: some View {
        WidgetCard(title: "RAM", collapsedSummary: {
            Text(String(format: "%.1f / %.0f GB", memory.usedGB, memory.totalGB))
        }) {
            StackedBarView(
                segments: [
                    .init(value: memory.usedGB,       color: .blue,   label: "Used"),
                    .init(value: memory.wiredGB,       color: .purple, label: "Wired"),
                    .init(value: memory.compressedGB,  color: .orange, label: "Compressed"),
                    .init(value: memory.freeGB,        color: .green,  label: "Free"),
                ],
                total: memory.totalGB
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    memRow("Used",  value: memory.usedGB,       color: .blue)
                    memRow("Wired", value: memory.wiredGB,      color: .purple)
                    memRow("Comp",  value: memory.compressedGB, color: .orange)
                    memRow("Free",  value: memory.freeGB,       color: .green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Swap In").font(.caption2).foregroundStyle(.secondary)
                    Text(String(format: "%.0f MB", memory.swapInMB)).font(.caption2.monospacedDigit())
                    Text("Swap Out").font(.caption2).foregroundStyle(.secondary)
                    Text(String(format: "%.0f MB", memory.swapOutMB)).font(.caption2.monospacedDigit())
                }
            }

            if !memory.topProcesses.isEmpty {
                Divider().padding(.vertical, 2)
                VStack(spacing: 2) {
                    ForEach(memory.topProcesses) { proc in
                        HStack(spacing: 4) {
                            Text(proc.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Text(ByteFormatter.format(proc.residentBytes))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func memRow(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 32, alignment: .leading)
            Text(String(format: "%.1f GB", value)).font(.caption2.monospacedDigit())
        }
    }
}
