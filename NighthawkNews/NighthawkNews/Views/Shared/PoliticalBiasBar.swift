import SwiftUI

/// A compact horizontal bar showing political lean rated by AI.
/// bias: -1.0 = far left, 0.0 = center, +1.0 = far right
struct PoliticalBiasBar: View {
    let bias: Double

    private var label: String {
        switch bias {
        case ..<(-0.6): return "Left"
        case ..<(-0.2): return "Lean Left"
        case ...0.2:    return "Center"
        case ...0.6:    return "Lean Right"
        default:        return "Right"
        }
    }

    private var labelColor: Color {
        switch bias {
        case ..<(-0.2): return .blue
        case ...0.2:    return Color(uiColor: .secondaryLabel)
        default:        return .red
        }
    }

    // Position of the marker: 0 = left edge, 1 = right edge
    private var markerPosition: Double { (bias + 1.0) / 2.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Political Lean")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                Spacer()
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(labelColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.4),
                                    Color(uiColor: .systemGray4),
                                    Color.red.opacity(0.4),
                                    Color.red
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 6)

                    // Marker
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        .frame(width: 12, height: 12)
                        .offset(x: markerPosition * (geo.size.width - 12))
                }
            }
            .frame(height: 12)
        }
    }
}
