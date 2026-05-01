import Foundation
import SwiftUI

@Observable
@MainActor
final class SystemMonitorViewModel: ObservableObject {
    let cpu       = CPUService()
    let memory    = MemoryService()
    let storage   = StorageService()
    let battery   = BatteryService()
    let gpu       = GPUService()
    let network   = NetworkService()
    let display   = DisplayService()
    let thermal   = ThermalService()
    let wifi      = WiFiService()
    let audio     = AudioService()
    let bluetooth = BluetoothService()
    let usb       = USBService()
}
