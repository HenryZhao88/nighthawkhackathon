import SwiftUI

struct CategoryFilterBar: View {
    @Binding var selected: String
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background {
                                if selected == category {
                                    Capsule()
                                        .fill(Color.accentColor)
                                } else {
                                    Capsule()
                                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                                }
                            }
                            .foregroundStyle(selected == category ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
