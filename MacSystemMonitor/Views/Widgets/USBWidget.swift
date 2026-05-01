import SwiftUI

struct USBWidget: View {
    let usb: USBService

    var body: some View {
        WidgetCard(title: "USB", collapsedSummary: {
            Text("\(usb.devices.count) devices")
        }) {
            if usb.devices.isEmpty {
                Text("No devices")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 2) {
                    ForEach(usb.devices.prefix(10)) { dev in
                        HStack(spacing: 6) {
                            Image(systemName: "cable.connector")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Text(dev.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Text(dev.vidPid)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
