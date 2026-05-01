import SwiftUI

struct DonutChartView: View {
    let value: Double  // 0.0 - 1.0
    var color: Color = .green
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(width: size, height: size)
    }
}
