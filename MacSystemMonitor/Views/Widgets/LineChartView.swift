import SwiftUI

struct LineChartView: View {
    let data: [Double]
    var color: Color = .green

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // grid lines at 25/50/75%
            for y in [0.25, 0.5, 0.75] {
                let py = h * (1 - y)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: py))
                path.addLine(to: CGPoint(x: w, y: py))
                ctx.stroke(path, with: .color(.secondary.opacity(0.3)), lineWidth: 0.5)
            }

            guard data.count >= 2 else { return }
            let step = w / CGFloat(max(data.count - 1, 1))
            var path = Path()
            for (i, v) in data.enumerated() {
                let x = CGFloat(i) * step
                let y = h * (1 - CGFloat(v))
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(color), lineWidth: 1.5)
        }
        .frame(height: 50)
    }
}
