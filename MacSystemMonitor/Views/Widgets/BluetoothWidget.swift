import SwiftUI

struct BluetoothWidget: View {
    let bluetooth: BluetoothService

    var body: some View {
        WidgetCard(title: "Bluetooth", collapsedSummary: {
            let connected = bluetooth.devices.filter(\.isConnected).count
            Text("\(connected) connected")
        }) {
            if bluetooth.devices.isEmpty {
                Text("No paired devices")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 2) {
                    ForEach(bluetooth.devices.prefix(8)) { dev in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(dev.isConnected ? Color.blue : Color.secondary.opacity(0.4))
                                .frame(width: 6, height: 6)
                            Text(dev.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Text(dev.isConnected ? "Connected" : "Paired")
                                .font(.caption2)
                                .foregroundStyle(dev.isConnected ? .blue : .secondary)
                                .frame(width: 58, alignment: .trailing)
                            Button {
                                if dev.isConnected { bluetooth.disconnect(dev.id) }
                                else               { bluetooth.connect(dev.id) }
                            } label: {
                                Text(dev.isConnected ? "Disconnect" : "Connect")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .frame(width: 68)
                                    .background((dev.isConnected ? Color.red : Color.blue).opacity(0.15))
                                    .foregroundStyle(dev.isConnected ? .red : .blue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
