import SwiftUI

struct CuteMascotView: View {
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Triangle()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.25)
                .rotationEffect(.degrees(-18))
                .offset(x: -size * 0.28, y: -size * 0.30)
                .overlay(
                    Triangle()
                        .fill(AppTheme.primary.opacity(0.45))
                        .frame(width: size * 0.14, height: size * 0.13)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -size * 0.28, y: -size * 0.27)
                )

            Triangle()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.25)
                .rotationEffect(.degrees(18))
                .offset(x: size * 0.28, y: -size * 0.30)
                .overlay(
                    Triangle()
                        .fill(AppTheme.primary.opacity(0.45))
                        .frame(width: size * 0.14, height: size * 0.13)
                        .rotationEffect(.degrees(18))
                        .offset(x: size * 0.28, y: -size * 0.27)
                )

            Circle()
                .fill(Color.white)
                .frame(width: size * 0.78, height: size * 0.70)
                .overlay(
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 2)
                )
                .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)

            HStack(spacing: size * 0.18) {
                Circle()
                    .fill(AppTheme.text)
                    .frame(width: size * 0.055, height: size * 0.055)
                Circle()
                    .fill(AppTheme.text)
                    .frame(width: size * 0.055, height: size * 0.055)
            }
            .offset(y: -size * 0.04)

            Capsule()
                .fill(AppTheme.lemon)
                .frame(width: size * 0.07, height: size * 0.045)
                .offset(y: size * 0.06)

            WhiskerSet(size: size)

            BowView(size: size * 0.30)
                .offset(x: size * 0.24, y: -size * 0.35)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct WhiskerSet: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach([-1, 1], id: \.self) { side in
                ForEach([-8, 8], id: \.self) { angle in
                    Capsule()
                        .fill(AppTheme.primaryDeep.opacity(0.72))
                        .frame(width: size * 0.20, height: 2)
                        .rotationEffect(.degrees(Double(angle * side)))
                        .offset(x: CGFloat(side) * size * 0.29, y: size * 0.06)
                }
            }
        }
    }
}

struct BowView: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(AppTheme.cherry)
                .frame(width: size * 0.56, height: size * 0.42)
                .rotationEffect(.degrees(-22))
                .offset(x: -size * 0.24)
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(AppTheme.cherry)
                .frame(width: size * 0.56, height: size * 0.42)
                .rotationEffect(.degrees(22))
                .offset(x: size * 0.24)
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.25, height: size * 0.25)
        }
        .frame(width: size, height: size * 0.65)
        .accessibilityHidden(true)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

