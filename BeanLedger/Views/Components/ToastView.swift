import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.onAccentText)
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
            .background(AppTheme.cherry.opacity(0.94), in: Capsule())
            .shadow(color: AppTheme.cherry.opacity(0.25), radius: 12, x: 0, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

