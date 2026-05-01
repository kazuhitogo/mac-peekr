import SwiftUI

struct HorizontalBarView: View {
    let ratio: Double

    private var barColor: Color {
        if ratio < 0.5  { return .green }
        if ratio < 0.8  { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: geo.size.width * min(ratio, 1))
            }
        }
        .frame(height: 8)
    }
}
