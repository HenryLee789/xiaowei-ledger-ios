import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct KittyMascotView: View {
    var size: CGFloat = 88

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(named: "hello_kitty_mascot") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel("hello_kitty_mascot")
        } else {
            CuteMascotView(size: size)
        }
        #else
        CuteMascotView(size: size)
        #endif
    }
}
