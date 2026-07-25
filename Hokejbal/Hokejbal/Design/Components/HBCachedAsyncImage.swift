import SwiftUI
import UIKit

/// AsyncImage s jednoduchou in-memory cache (opakovaný scroll znovu nestahuje).
enum HBImageMemoryCache {
    private static let cache = NSCache<NSURL, UIImage>()

    static func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct HBCachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task(id: url?.absoluteString) { await load() }
            }
        }
    }

    private func load() async {
        guard let url else { return }
        if let cached = HBImageMemoryCache.image(for: url) {
            uiImage = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else { return }
            HBImageMemoryCache.store(image, for: url)
            uiImage = image
        } catch {
            // placeholder zůstane
        }
    }
}
