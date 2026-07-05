import SwiftUI

struct RecordThumbnailView: View {
    let record: LedgerRecord
    var size: CGFloat = 42

    var body: some View {
        RecordImagePreview(
            image: RecordImageStore.image(for: record.imageFilename),
            type: record.type,
            category: record.category,
            size: size
        )
    }
}

struct RecordImagePreview: View {
    let image: UIImage?
    let type: LedgerType
    let category: String
    var size: CGFloat

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                generatedPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.35, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.35, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1.2)
        )
        .background(AppTheme.softBackground(for: type), in: RoundedRectangle(cornerRadius: size * 0.35, style: .continuous))
    }

    private var generatedPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FFF8DC"),
                    AppTheme.softBackground(for: type).opacity(0.92),
                    Color.white.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.38))
                .frame(width: size * 0.84, height: size * 0.84)
                .offset(x: -size * 0.18, y: -size * 0.18)

            Circle()
                .fill(type.tint.opacity(0.10))
                .frame(width: size * 0.64, height: size * 0.64)
                .offset(x: size * 0.24, y: size * 0.22)

            CartoonCategoryIllustration(category: category, type: type)
                .frame(width: size * 0.78, height: size * 0.78)
                .rotationEffect(.degrees(categoryTilt))

            Image(systemName: "heart.fill")
                .font(.system(size: max(7, size * 0.17), weight: .bold))
                .foregroundStyle(AppTheme.primaryDeep.opacity(0.78))
                .offset(x: size * 0.27, y: -size * 0.27)

            Image(systemName: "sparkle")
                .font(.system(size: max(6, size * 0.14), weight: .bold))
                .foregroundStyle(AppTheme.lemon)
                .offset(x: -size * 0.28, y: -size * 0.26)
        }
    }

    private var categoryTilt: Double {
        switch category.count % 5 {
        case 0:
            return -5
        case 1:
            return 3
        case 2:
            return -2
        case 3:
            return 4
        default:
            return 0
        }
    }
}

private struct CartoonCategoryIllustration: View {
    let category: String
    let type: LedgerType

    private var outline: Color {
        AppTheme.text.opacity(0.62)
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            illustration(side: side)
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    @ViewBuilder
    private func illustration(side: CGFloat) -> some View {
        switch category {
        case "餐饮":
            riceBowl(side: side)
        case "购物":
            shoppingBag(side: side)
        case "生活缴费":
            toiletRoll(side: side)
        case "交通":
            miniBus(side: side)
        case "娱乐":
            ticket(side: side)
        case "医疗":
            medicineKit(side: side)
        case "房租":
            tinyHouse(side: side)
        case "工资", "副业", "报销", "其他入账":
            moneyPouch(side: side)
        case "红包":
            redEnvelope(side: side)
        case "投资收益":
            coinSprout(side: side)
        case "存钱", "目标储蓄", "备用金", "理财转入", "其他攒豆豆":
            beanJar(side: side)
        case "信用卡", "花呗 / 白条":
            cuteCard(side: side)
        case "借出", "借入", "还款", "收回借款", "其他借贷":
            debtNote(side: side)
        default:
            fallbackObject(side: side)
        }
    }

    private func stickerBase(side: CGFloat, fill: Color = .white) -> some View {
        Circle()
            .fill(fill.opacity(0.98))
            .overlay(
                Circle()
                    .stroke(outline, lineWidth: max(1.5, side * 0.05))
            )
            .shadow(color: type.tint.opacity(0.14), radius: side * 0.10, x: 0, y: side * 0.04)
    }

    private func riceBowl(side: CGFloat) -> some View {
        ZStack {
            stickerBase(side: side, fill: Color(hex: "FFFDF7"))
                .frame(width: side * 0.88, height: side * 0.88)

            Ellipse()
                .fill(Color.white)
                .frame(width: side * 0.50, height: side * 0.28)
                .offset(y: -side * 0.07)
                .overlay(
                    Ellipse()
                        .stroke(outline, lineWidth: side * 0.04)
                        .frame(width: side * 0.50, height: side * 0.28)
                        .offset(y: -side * 0.07)
                )

            RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                .fill(Color(hex: "FFE6A6"))
                .frame(width: side * 0.58, height: side * 0.32)
                .offset(y: side * 0.12)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.04)
                        .frame(width: side * 0.58, height: side * 0.32)
                        .offset(y: side * 0.12)
                )

            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(type.tint.opacity(0.82))
                    .frame(width: side * 0.05, height: side * 0.28)
                    .offset(x: CGFloat(index - 1) * side * 0.11, y: side * 0.13)
            }
        }
    }

    private func shoppingBag(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(Color(hex: "FFD6E4"))
                .frame(width: side * 0.62, height: side * 0.62)
                .offset(y: side * 0.10)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                        .frame(width: side * 0.62, height: side * 0.62)
                        .offset(y: side * 0.10)
                )

            Path { path in
                path.move(to: CGPoint(x: side * 0.32, y: side * 0.38))
                path.addQuadCurve(
                    to: CGPoint(x: side * 0.68, y: side * 0.38),
                    control: CGPoint(x: side * 0.50, y: side * 0.10)
                )
            }
            .stroke(outline, style: StrokeStyle(lineWidth: side * 0.055, lineCap: .round))

            Circle()
                .fill(AppTheme.primaryDeep.opacity(0.82))
                .frame(width: side * 0.13, height: side * 0.13)
                .offset(x: side * 0.12, y: -side * 0.04)

            Image(systemName: "heart.fill")
                .font(.system(size: side * 0.18, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
                .offset(y: side * 0.13)
        }
    }

    private func toiletRoll(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                .fill(Color(hex: "EAF4FF"))
                .frame(width: side * 0.56, height: side * 0.68)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )

            Circle()
                .fill(Color.white)
                .frame(width: side * 0.35, height: side * 0.35)
                .overlay(Circle().stroke(outline.opacity(0.85), lineWidth: side * 0.04))
                .offset(y: -side * 0.09)

            Circle()
                .fill(Color(hex: "BFE9FF"))
                .frame(width: side * 0.13, height: side * 0.13)
                .offset(y: -side * 0.09)

            RoundedRectangle(cornerRadius: side * 0.06, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .frame(width: side * 0.35, height: side * 0.16)
                .offset(y: side * 0.22)
        }
    }

    private func miniBus(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                .fill(Color(hex: "BFE9FF"))
                .frame(width: side * 0.70, height: side * 0.50)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )

            HStack(spacing: side * 0.06) {
                RoundedRectangle(cornerRadius: side * 0.04)
                    .fill(Color.white.opacity(0.90))
                RoundedRectangle(cornerRadius: side * 0.04)
                    .fill(Color.white.opacity(0.90))
            }
            .frame(width: side * 0.42, height: side * 0.16)
            .offset(y: -side * 0.06)

            HStack(spacing: side * 0.30) {
                Circle().fill(outline)
                Circle().fill(outline)
            }
            .frame(width: side * 0.52, height: side * 0.12)
            .offset(y: side * 0.25)
        }
    }

    private func ticket(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                .fill(Color(hex: "FCEBFF"))
                .frame(width: side * 0.70, height: side * 0.48)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )
                .rotationEffect(.degrees(-8))

            Image(systemName: "star.fill")
                .font(.system(size: side * 0.30, weight: .heavy))
                .foregroundStyle(AppTheme.savingPrimary)
        }
    }

    private func medicineKit(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.15, style: .continuous)
                .fill(Color.white)
                .frame(width: side * 0.66, height: side * 0.54)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.15, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )

            Capsule()
                .fill(AppTheme.cherry)
                .frame(width: side * 0.12, height: side * 0.36)
            Capsule()
                .fill(AppTheme.cherry)
                .frame(width: side * 0.36, height: side * 0.12)
        }
    }

    private func tinyHouse(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.10, style: .continuous)
                .fill(Color(hex: "FFF4D6"))
                .frame(width: side * 0.58, height: side * 0.46)
                .offset(y: side * 0.12)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.10, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                        .frame(width: side * 0.58, height: side * 0.46)
                        .offset(y: side * 0.12)
                )

            Path { path in
                path.move(to: CGPoint(x: side * 0.22, y: side * 0.43))
                path.addLine(to: CGPoint(x: side * 0.50, y: side * 0.18))
                path.addLine(to: CGPoint(x: side * 0.78, y: side * 0.43))
            }
            .stroke(outline, style: StrokeStyle(lineWidth: side * 0.065, lineCap: .round, lineJoin: .round))

            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(AppTheme.primary.opacity(0.72))
                .frame(width: side * 0.16, height: side * 0.24)
                .offset(y: side * 0.20)
        }
    }

    private func moneyPouch(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(Color(hex: "EAF4FF"))
                .frame(width: side * 0.62, height: side * 0.54)
                .offset(y: side * 0.10)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                        .frame(width: side * 0.62, height: side * 0.54)
                        .offset(y: side * 0.10)
                )

            Capsule()
                .fill(AppTheme.incomePrimary.opacity(0.78))
                .frame(width: side * 0.42, height: side * 0.16)
                .offset(y: -side * 0.18)

            Text("¥")
                .font(.system(size: side * 0.34, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.incomePrimary)
                .offset(y: side * 0.09)
        }
    }

    private func redEnvelope(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                .fill(Color(hex: "FF8FA3"))
                .frame(width: side * 0.62, height: side * 0.68)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )

            Circle()
                .fill(Color(hex: "FFE6A6"))
                .frame(width: side * 0.25, height: side * 0.25)

            Image(systemName: "heart.fill")
                .font(.system(size: side * 0.15, weight: .bold))
                .foregroundStyle(AppTheme.cherry)
        }
    }

    private func coinSprout(side: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFE6A6"))
                .frame(width: side * 0.58, height: side * 0.58)
                .overlay(Circle().stroke(outline, lineWidth: side * 0.05))
                .offset(y: side * 0.10)

            Path { path in
                path.move(to: CGPoint(x: side * 0.50, y: side * 0.45))
                path.addLine(to: CGPoint(x: side * 0.50, y: side * 0.20))
                path.addQuadCurve(to: CGPoint(x: side * 0.32, y: side * 0.24), control: CGPoint(x: side * 0.38, y: side * 0.12))
                path.move(to: CGPoint(x: side * 0.50, y: side * 0.20))
                path.addQuadCurve(to: CGPoint(x: side * 0.68, y: side * 0.24), control: CGPoint(x: side * 0.62, y: side * 0.12))
            }
            .stroke(AppTheme.budgetSafe, style: StrokeStyle(lineWidth: side * 0.06, lineCap: .round, lineJoin: .round))
        }
    }

    private func beanJar(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(Color(hex: "FCEBFF"))
                .frame(width: side * 0.56, height: side * 0.66)
                .offset(y: side * 0.08)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                        .frame(width: side * 0.56, height: side * 0.66)
                        .offset(y: side * 0.08)
                )

            Capsule()
                .fill(Color.white)
                .frame(width: side * 0.42, height: side * 0.16)
                .overlay(Capsule().stroke(outline, lineWidth: side * 0.04))
                .offset(y: -side * 0.30)

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(AppTheme.savingPrimary.opacity(0.78))
                    .frame(width: side * 0.12, height: side * 0.20)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -25 : 25))
                    .offset(
                        x: CGFloat(index % 2 == 0 ? -1 : 1) * side * CGFloat(0.09 + Double(index / 2) * 0.07),
                        y: side * CGFloat(0.05 + Double(index / 2) * 0.12)
                    )
            }
        }
    }

    private func cuteCard(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                .fill(Color(hex: "F0EAFF"))
                .frame(width: side * 0.70, height: side * 0.48)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )
                .rotationEffect(.degrees(-6))

            Capsule()
                .fill(AppTheme.debtPrimary.opacity(0.38))
                .frame(width: side * 0.50, height: side * 0.10)
                .offset(y: -side * 0.08)
        }
    }

    private func debtNote(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                .fill(Color.white)
                .frame(width: side * 0.62, height: side * 0.68)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                        .stroke(outline, lineWidth: side * 0.05)
                )

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: side * 0.28, weight: .heavy))
                .foregroundStyle(AppTheme.debtPrimary)

            VStack(spacing: side * 0.06) {
                Capsule().fill(outline.opacity(0.32)).frame(width: side * 0.34, height: side * 0.04)
                Capsule().fill(outline.opacity(0.22)).frame(width: side * 0.24, height: side * 0.04)
            }
            .offset(y: side * 0.21)
        }
    }

    private func fallbackObject(side: CGFloat) -> some View {
        ZStack {
            stickerBase(side: side)
                .frame(width: side * 0.84, height: side * 0.84)
            Image(systemName: type.iconName)
                .font(.system(size: side * 0.32, weight: .heavy))
                .foregroundStyle(type.tint)
        }
    }
}
