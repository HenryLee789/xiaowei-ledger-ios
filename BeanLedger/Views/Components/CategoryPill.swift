import SwiftUI

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = AppTheme.cherry
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : color)
                .lineLimit(1)
                .padding(.vertical, 9)
                .padding(.horizontal, 15)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.11))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.45) : color.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(CutePressButtonStyle())
    }
}

