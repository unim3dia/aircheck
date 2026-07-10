import SwiftUI

enum AircheckTheme {
    static let paper = Color(red: 0.965, green: 0.945, blue: 0.905)
    static let paperDeep = Color(red: 0.91, green: 0.865, blue: 0.79)
    static let ink = Color(red: 0.10, green: 0.095, blue: 0.085)
    static let signal = Color(red: 0.72, green: 0.16, blue: 0.12)
    static let peach = Color(red: 0.91, green: 0.59, blue: 0.45)
    static let blue = Color(red: 0.47, green: 0.64, blue: 0.66)
    static let moss = Color(red: 0.41, green: 0.48, blue: 0.34)

    static let storyColors = [peach, blue, moss, paperDeep]
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            AircheckTheme.paper
            LinearGradient(
                colors: [.white.opacity(0.28), AircheckTheme.peach.opacity(0.10), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

struct SoftCard: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(color.opacity(0.76), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: AircheckTheme.ink.opacity(0.08), radius: 18, y: 9)
    }
}

extension View {
    func softCard(_ color: Color = .white) -> some View { modifier(SoftCard(color: color)) }
}
