import SwiftUI

struct NetworkWidget: View {
    let network: NetworkService

    var body: some View {
        WidgetCard(title: "Network") {
            if network.interfaces.isEmpty {
                Text("No interfaces").font(.caption2).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(network.interfaces) { iface in
                        HStack {
                            Text(iface.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up").font(.caption2).foregroundStyle(.orange)
                                    Text(ByteFormatter.formatSpeed(iface.uploadSpeed)).font(.caption2.monospacedDigit())
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down").font(.caption2).foregroundStyle(.blue)
                                    Text(ByteFormatter.formatSpeed(iface.downloadSpeed)).font(.caption2.monospacedDigit())
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(ByteFormatter.format(iface.totalSent)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                                Text(ByteFormatter.format(iface.totalReceived)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
