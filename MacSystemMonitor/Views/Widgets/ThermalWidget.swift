import SwiftUI

struct ThermalWidget: View {
    let thermal: ThermalService

    var body: some View {
        WidgetCard(title: "Thermal", collapsedSummary: {
            Text(thermal.label)
                .foregroundStyle(thermal.color)
        }) {
            VStack(alignment: .center, spacing: 6) {
                Circle()
                    .fill(thermal.color)
                    .frame(width: 24, height: 24)
                    .shadow(color: thermal.color.opacity(0.6), radius: 4)
                Text(thermal.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(thermal.color)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
