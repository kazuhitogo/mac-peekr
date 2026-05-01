import SwiftUI

struct WidgetCard<Content: View, Summary: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder let collapsedSummary: () -> Summary
    @AppStorage private var isCollapsed: Bool

    init(title: String,
         @ViewBuilder collapsedSummary: @escaping () -> Summary,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
        self.collapsedSummary = collapsedSummary
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
                    if isCollapsed {
                        collapsedSummary()
                            .font(.caption2.monospacedDigit())
                    }
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

extension WidgetCard where Summary == EmptyView {
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, collapsedSummary: { EmptyView() }, content: content)
    }
}
