import SwiftUI

struct AmbientLightWidget: View {
    let ambientLight: AmbientLightService

    var body: some View {
        WidgetCard(title: "Ambient Light", collapsedSummary: {
            if ambientLight.isAvailable {
                Text(String(format: "%.0f lx", ambientLight.currentLux))
            } else {
                Text("No Sensor")
            }
        }) {
            if !ambientLight.isAvailable {
                HStack {
                    Image(systemName: "light.max")
                    Text("Ambient light sensor not available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: luxIcon)
                        .font(.title2)
                        .foregroundStyle(luxColor)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "%.0f lx", ambientLight.currentLux))
                            .font(.caption.monospacedDigit())
                            .fontWeight(.medium)
                        Text(luxLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var luxIcon: String {
        switch ambientLight.currentLux {
        case 0..<10:   return "moon"
        case 10..<100: return "light.min"
        case 100..<500: return "sun.min"
        default:        return "sun.max"
        }
    }

    private var luxColor: Color {
        switch ambientLight.currentLux {
        case 0..<10:   return .indigo
        case 10..<100: return .blue
        case 100..<500: return .orange
        default:        return .yellow
        }
    }

    private var luxLabel: String {
        switch ambientLight.currentLux {
        case 0..<1:    return "Dark"
        case 1..<10:   return "Dim"
        case 10..<100: return "Indoor (dim)"
        case 100..<400: return "Indoor"
        case 400..<1000: return "Bright indoor"
        case 1000..<10000: return "Overcast outdoor"
        default:        return "Direct sunlight"
        }
    }
}
