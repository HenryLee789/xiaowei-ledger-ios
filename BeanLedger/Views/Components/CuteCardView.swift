import SwiftUI

struct CuteCardView<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(
        padding: CGFloat = AppTheme.spacingLarge,
        cornerRadius: CGFloat = AppTheme.cornerLarge,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .cuteCardBackground(cornerRadius: cornerRadius)
    }
}

