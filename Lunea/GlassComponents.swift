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
    @State private var animate = false

    var body: some View {
        ZStack {
            // Deep space base
            LinearGradient(
                colors: [
                    Color(hex: "060612"),
                    Color(hex: "0d1a2e"),
                    Color(hex: "1a0d2e"),
                    Color(hex: "0a1a1a")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Orb 1 — Purple
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "7c3aed").opacity(0.6), .clear],
                        center: .center, startRadius: 0, endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? -280 : -260, y: animate ? -200 : -220)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            // Orb 2 — Pink/Red
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "be185d").opacity(0.5), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: animate ? 280 : 260, y: animate ? 240 : 220)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)

            // Orb 3 — Cyan
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "0891b2").opacity(0.4), .clear],
                        center: .center, startRadius: 0, endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animate ? 200 : 180, y: animate ? -60 : -80)
                .blur(radius: 50)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)

            // Orb 4 — Red (YouTube accent)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.red.opacity(0.3), .clear],
                        center: .center, startRadius: 0, endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: animate ? -50 : -30, y: animate ? 80 : 60)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
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
                            .fill(Color(hex: "FA2E5B"))
                            .shadow(color: Color(hex: "FA2E5B").opacity(0.4), radius: 6, y: 2)
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
