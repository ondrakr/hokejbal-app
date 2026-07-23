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

/// Splash / loading obrazovka s oficiálním logem.
struct BrandLoadingView: View {
    var message: String = "Načítám…"

    var body: some View {
        VStack(spacing: 20) {
            BrandLogoImage(size: 128)

            ProgressView()
                .tint(HBTheme.brand)

            Text(message)
                .font(.hbMontserrat(size: 14, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HBTheme.surface.ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hokejbal, \(message)")
    }
}
