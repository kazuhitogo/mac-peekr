import Foundation
import IOBluetooth

struct BTDeviceInfo: Identifiable {
    let id: String
    let name: String
    let isConnected: Bool
}

@Observable
@MainActor
final class BluetoothService {
    private(set) var devices: [BTDeviceInfo] = []

    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.5
    }

    deinit { timer?.invalidate() }

    func connect(_ id: String) {
        IOBluetoothDevice(addressString: id)?.openConnection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.update() }
    }

    func disconnect(_ id: String) {
        IOBluetoothDevice(addressString: id)?.closeConnection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.update() }
    }

    private func update() {
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            devices = []
            return
        }
        devices = paired
            .map { BTDeviceInfo(id: $0.addressString, name: $0.nameOrAddress, isConnected: $0.isConnected()) }
            .sorted { $0.isConnected && !$1.isConnected }
    }
}
