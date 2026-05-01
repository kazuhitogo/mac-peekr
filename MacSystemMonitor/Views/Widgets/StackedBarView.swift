import SwiftUI

struct StackedSegment {
    let value: Double
    let color: Color
    let label: String
}

struct StackedBarView: View {
    let segments: [StackedSegment]
    let total: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    let ratio = total > 0 ? seg.value / total : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(seg.color)
                        .frame(width: geo.size.width * ratio)
                }
            }
        }
        .frame(height: 14)
        .background(Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
    }
}
