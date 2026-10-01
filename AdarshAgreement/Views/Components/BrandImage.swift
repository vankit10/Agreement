import SwiftUI

struct BrandImage: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "logo", withExtension: "png"), let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Adarsh company logo")
        }
    }
}
