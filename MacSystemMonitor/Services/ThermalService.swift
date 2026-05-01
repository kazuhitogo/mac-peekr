import Foundation
import SwiftUI

@Observable
@MainActor
final class ThermalService {
    private(set) var state: ProcessInfo.ThermalState = .nominal

    var label: String {
        switch state {
        case .nominal:  return "Nominal"
        case .fair:     return "Fair"
        case .serious:  return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var color: Color {
        switch state {
        case .nominal:  return .green
        case .fair:     return .yellow
        case .serious:  return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    init() {
        state = ProcessInfo.processInfo.thermalState
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.state = ProcessInfo.processInfo.thermalState
            }
        }
    }
}
