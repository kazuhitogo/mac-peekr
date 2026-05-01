import SwiftUI

struct StorageWidget: View {
    let storage: StorageService

    var body: some View {
        WidgetCard(title: "Storage", collapsedSummary: {
            if let vol = storage.volumes.first {
                Text(String(format: "%.0f%%", vol.usageRatio * 100))
            }
        }) {
            if storage.volumes.isEmpty {
                Text("No volumes").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(storage.volumes) { vol in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: vol.isRemovable ? "externaldrive" : "internaldrive")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(vol.name).font(.caption2).lineLimit(1)
                            Spacer()
                            Text("\(ByteFormatter.format(vol.usedBytes)) / \(ByteFormatter.format(vol.totalBytes))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        HorizontalBarView(ratio: vol.usageRatio)
                    }
                }
            }
        }
    }
}
