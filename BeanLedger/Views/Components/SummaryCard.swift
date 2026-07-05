import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var valueColor: Color = AppTheme.text
    var iconBackground: Color? = nil

    var body: some View {
        CuteCardView(padding: 14, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .background(iconBackground ?? tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer(minLength: 4)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.primary.opacity(0.75))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(value)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(valueColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        }
    }
}
