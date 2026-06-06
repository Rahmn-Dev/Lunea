import SwiftUI

// MARK: - Liquid Glass Effect

struct LiquidGlassModifier: ViewModifier {
    var intensity: Double = 1.0
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.7 * intensity)

                    // White shimmer top edge
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25 * intensity),
                                    Color.white.opacity(0.05 * intensity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Inner glow
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4 * intensity),
                                    Color.white.opacity(0.1 * intensity),
                                    Color.white.opacity(0.05 * intensity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func liquidGlass(intensity: Double = 1.0, cornerRadius: CGFloat = 16) -> some View {
        modifier(LiquidGlassModifier(intensity: intensity, cornerRadius: cornerRadius))
    }
}

// MARK: - Animated Background Orbs

struct BackgroundOrbs: View {
    @State private var start = UnitPoint(x: 0, y: -0.5)
        @State private var end = UnitPoint(x: 1, y: 1.5)
        
        let colors = [
            Color(hex: "0A0A12"),
            Color(hex: "1A1A2E"),
            Color(hex: "16213E"),
            Color(hex: "0A0A12")
        ]

        var body: some View {
            TimelineView(.animation) { context in
                // Menghitung perubahan waktu untuk menggerakkan gradien
                let time = context.date.timeIntervalSinceReferenceDate
                let angle = time.remainder(dividingBy: 5) * (Double.pi * 2) / 5
                
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: start,
                    endPoint: end
                )
                .hueRotation(.degrees(sin(angle) * 20)) // Efek pergeseran warna yang lembut
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        start = UnitPoint(x: 1, y: 0)
                        end = UnitPoint(x: 0, y: 1)
                    }
                }
            }
        }
}

// MARK: - Traffic Light Buttons

struct TrafficLightButtons: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "FF5F57"))
                .frame(width: 13, height: 13)
                .shadow(color: Color(hex: "FF5F57").opacity(0.6), radius: 4)
            Circle()
                .fill(Color(hex: "FFBD2E"))
                .frame(width: 13, height: 13)
                .shadow(color: Color(hex: "FFBD2E").opacity(0.6), radius: 4)
            Circle()
                .fill(Color(hex: "28C840"))
                .frame(width: 13, height: 13)
                .shadow(color: Color(hex: "28C840").opacity(0.6), radius: 4)
        }
    }
}

// MARK: - YouTube Logo

struct YouTubeLogo: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.red)
                .frame(width: size * 1.4, height: size)

            Image(systemName: "play.fill")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.white)
                .offset(x: 1)
        }
    }
}

// MARK: - Glass Chip

struct GlassChip: View {
    @ObservedObject var state: AppState
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? .white : .white.opacity(0.6)))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minWidth: 70) // Agar area klik lebih luas & konsisten
                .contentShape(Rectangle()) // 🔥 INI KUNCINYA! Bikin seluruh area bisa diklik
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(state.currentTheme.accentColor)
                            .shadow(color: state.currentTheme.accentColor.opacity(0.4), radius: 6, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(isHovered ? 0.12 : 0.06))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Channel Avatar

struct ChannelAvatar: View {
    let initial: String
    var gradientStart: Color = Color(hex: "7c3aed")
    var gradientEnd: Color = Color(hex: "db2777")
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
