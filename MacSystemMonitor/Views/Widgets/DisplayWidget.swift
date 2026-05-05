import SwiftUI

struct DisplayWidget: View {
    let display: DisplayService

    var body: some View {
        WidgetCard(title: "Displays", collapsedSummary: {
            let main = display.displays.first(where: { $0.isMain }) ?? display.displays.first
            if let d = main {
                Text("\(Int(d.resolution.width))×\(Int(d.resolution.height))")
            }
        }) {
            if display.displays.isEmpty {
                Text("No displays").font(.caption2).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(display.displays) { d in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: d.isMain ? "display" : "display.2")
                                    .font(.caption2)
                                    .foregroundStyle(d.isMain ? .blue : .secondary)
                                Text(d.name)
                                    .font(.caption2)
                                    .fontWeight(d.isMain ? .semibold : .regular)
                                    .lineLimit(1)
                            }
                            Text("\(Int(d.resolution.width))×\(Int(d.resolution.height))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text("\(d.refreshRate) Hz")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            if let b = d.brightness {
                                Text(String(format: "%.0f%% bright", b * 100))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if d.id != display.displays.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
