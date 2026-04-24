import SwiftUI

/// Custom bottom tab bar that floats above the paging content with an
/// `.ultraThinMaterial` glass effect. Anchored to the bottom safe area so the
/// pages glide beneath it without any visual jarring during transitions.
struct GlassTabBar: View {
    @Binding var selected: Int

    private struct Item {
        let title: String
        let icon: String
        let filledIcon: String
    }

    private let items: [Item] = [
        Item(title: "Home",     icon: "house",        filledIcon: "house.fill"),
        Item(title: "Feed",     icon: "square.stack", filledIcon: "square.stack.fill"),
        Item(title: "Search",   icon: "magnifyingglass", filledIcon: "magnifyingglass"),
        Item(title: "Settings", icon: "gearshape",    filledIcon: "gearshape.fill"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
                        selected = index
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: selected == index ? item.filledIcon : item.icon)
                            .font(.system(size: 22, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                        Text(item.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(selected == index ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
