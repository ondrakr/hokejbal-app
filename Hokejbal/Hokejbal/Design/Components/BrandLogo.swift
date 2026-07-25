import SwiftUI

/// Oficiální logo ČMSHb / aplikace Hokejbal.
struct BrandLogoImage: View {
    var size: CGFloat = 48

    var body: some View {
        brandImage
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Hokejbal")
    }

    private var brandImage: Image {
        if UIImage(named: "BrandLogo") != nil {
            return Image("BrandLogo")
        }
        if UIImage(named: "BrandLogoLarge") != nil {
            return Image("BrandLogoLarge")
        }
        return Image(systemName: "sportscourt.circle.fill")
    }
}

/// Splash / loading — logo uprostřed; volitelná zpráva pod ním (lokální loadery).
struct BrandLoadingView: View {
    var message: String? = nil
    var logoSize: CGFloat = 132

    @State private var visible = false

    var body: some View {
        ZStack {
            HBTheme.canvas
                .ignoresSafeArea()

            VStack(spacing: 18) {
                BrandLogoImage(size: logoSize)
                    .scaleEffect(visible ? 1 : 0.94)
                    .opacity(visible ? 1 : 0)

                if let message {
                    ProgressView()
                        .tint(HBTheme.brand)
                    Text(message)
                        .font(.hbMontserrat(size: 14, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                visible = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message.map { "Hokejbal, \($0)" } ?? "Hokejbal, načítám")
    }
}
