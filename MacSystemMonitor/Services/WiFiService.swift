import Foundation
import CoreWLAN

@Observable
@MainActor
final class WiFiService {
    private(set) var ssid: String = ""
    private(set) var rssi: Int = 0
    private(set) var noise: Int = 0
    private(set) var channel: Int = 0
    private(set) var txRate: Double = 0
    private(set) var isConnected: Bool = false

    private let client = CWWiFiClient.shared()
    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.3
    }

    deinit { timer?.invalidate() }

    private func update() {
        guard let iface = client.interface() else {
            isConnected = false
            ssid = ""
            return
        }
        isConnected = iface.ssid() != nil
        ssid       = iface.ssid() ?? ""
        rssi       = iface.rssiValue()
        noise      = iface.noiseMeasurement()
        channel    = iface.wlanChannel()?.channelNumber ?? 0
        txRate     = iface.transmitRate()
    }
}
