import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "tray.fill"

    var body: some View {
        CuteCardView {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.primaryDeep)
                    .frame(width: 58, height: 58)
                    .background(AppTheme.primary.opacity(0.16), in: Circle())
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

