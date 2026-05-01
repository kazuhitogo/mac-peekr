import SwiftUI

struct WidgetCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @AppStorage private var isCollapsed: Bool

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
        self._isCollapsed = AppStorage(wrappedValue: false, "widget_collapsed_\(title)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isCollapsed.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isCollapsed ? "▶" : "▼")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                content()
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
