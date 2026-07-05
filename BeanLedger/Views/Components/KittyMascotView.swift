import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum KittyAsset: String {
    case mascot = "hello_kitty_mascot"
    case bow = "hello_kitty_bow"
    case icon = "hello_kitty_icon"

    var displayName: String {
        switch self {
        case .mascot:
            return "hello_kitty_mascot"
        case .bow:
            return "hello_kitty_bow"
        case .icon:
            return "hello_kitty_icon"
        }
    }
}

struct KittyMascotView: View {
    var size: CGFloat = 88
    var asset: KittyAsset = .mascot

    var body: some View {
        MascotImageView(asset: asset, size: size) {
            CuteMascotView(size: size)
        }
    }
}

struct MascotImageView<Placeholder: View>: View {
    let asset: KittyAsset
    let size: CGFloat
    let placeholder: Placeholder

    init(asset: KittyAsset, size: CGFloat, @ViewBuilder placeholder: () -> Placeholder) {
        self.asset = asset
        self.size = size
        self.placeholder = placeholder()
    }

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(named: asset.rawValue) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel(asset.displayName)
        } else {
            placeholder
        }
        #else
        placeholder
        #endif
    }
}

