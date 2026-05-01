import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var color: Color = .cyan

    var body: some View {
        Canvas { ctx, size in
            guard samples.count > 1 else { return }
            let midY  = size.height / 2
            let xStep = size.width / Double(samples.count - 1)
            var path  = Path()
            path.move(to: CGPoint(x: 0, y: midY - Double(samples[0]) * midY * 0.9))
            for i in 1..<samples.count {
                let x = Double(i) * xStep
                let y = midY - Double(samples[i]) * midY * 0.9
                path.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.stroke(path, with: .color(color), lineWidth: 1)
        }
        .frame(height: 40)
    }
}
