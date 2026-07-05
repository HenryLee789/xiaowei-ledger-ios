import SwiftUI

struct CuteButton: View {
    enum Style {
        case primary
        case secondary
        case danger
    }

    let title: String
    var systemImage: String?
    var style: Style = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(border, lineWidth: 1)
            )
        }
        .buttonStyle(CutePressButtonStyle())
    }

    private var foreground: Color {
        switch style {
        case .primary, .danger:
            return .white
        case .secondary:
            return AppTheme.cherry
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            AppTheme.buttonGradient
        case .secondary:
            Color.white
        case .danger:
            AppTheme.dangerGradient
        }
    }

    private var border: Color {
        style == .secondary ? AppTheme.border : Color.white.opacity(0.35)
    }
}

struct CutePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
