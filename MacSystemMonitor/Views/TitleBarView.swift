import SwiftUI
import AppKit

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

struct TitleBarView: View {
    @Binding var opacity: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WindowDragArea()

            HStack(spacing: 8) {
                Text("Peekr")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .allowsHitTesting(false)

                Spacer()

                Image(systemName: "sun.max")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Slider(value: $opacity, in: 0.2...1.0)
                    .frame(width: 80)
                    .onChange(of: opacity) { _, newValue in
                        NSApp.keyWindow?.alphaValue = newValue
                    }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 36)
        .background(.ultraThinMaterial)
    }
}
