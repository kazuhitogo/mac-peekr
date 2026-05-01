import SwiftUI

struct AudioWidget: View {
    let audio: AudioService

    var body: some View {
        WidgetCard(title: "Audio", collapsedSummary: {
            let mic = audio.micAvailable ? (audio.micDeviceName.isEmpty ? "Mic" : audio.micDeviceName) : "No Mic"
            let spk = audio.speakerAvailable ? (audio.speakerDeviceName.isEmpty ? "Speaker" : audio.speakerDeviceName) : "No Speaker"
            Text("\(mic) · \(spk)")
                .lineLimit(1)
                .truncationMode(.middle)
        }) {
            waveformSection(
                label: "Mic",
                deviceName: audio.micDeviceName,
                samples: audio.micSamples,
                color: .cyan,
                available: audio.micAvailable
            )
            Divider().padding(.vertical, 2)
            waveformSection(
                label: "Speaker",
                deviceName: audio.speakerDeviceName,
                samples: audio.speakerSamples,
                color: .orange,
                available: audio.speakerAvailable
            )
        }
    }

    @ViewBuilder
    private func waveformSection(label: String, deviceName: String, samples: [Float], color: Color, available: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                if !deviceName.isEmpty {
                    Text(deviceName).font(.caption2).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            if available {
                WaveformView(samples: samples, color: color)
            } else {
                Text("Permission required")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
            }
        }
    }
}
