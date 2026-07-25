import SwiftUI

// MARK: - Shimmer

/// Plynulý shimmer přes skeleton kosti.
struct HBShimmer: ViewModifier {
    @State private var move = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.55), location: 0.45),
                            .init(color: Color.white.opacity(0.55), location: 0.55),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 0.55)
                    .offset(x: move ? w : -w * 0.55)
                    .blendMode(.softLight)
                }
                .allowsHitTesting(false)
            }
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: false)) {
                    move = true
                }
            }
    }
}

extension View {
    func hbShimmer() -> some View {
        modifier(HBShimmer())
    }
}

/// Základní „kost“ skeletonu.
struct HBSkeletonBone: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(HBTheme.cardInset)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .hbShimmer()
    }
}

// MARK: - Featured news (Domů)

/// Skeleton velké novinky — stejná výška jako `featuredArticleCard` (210 + page).
struct FeaturedNewsSkeleton: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                .fill(HBTheme.cardInset)
                .hbShimmer()

            VStack(alignment: .leading, spacing: 10) {
                HBSkeletonBone(width: 72, height: 22, cornerRadius: 11)
                HBSkeletonBone(height: 18, cornerRadius: 5)
                HBSkeletonBone(width: 180, height: 18, cornerRadius: 5)
                HBSkeletonBone(width: 100, height: 12, cornerRadius: 4)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .padding(.horizontal, HBTheme.screenPadding)
        .accessibilityLabel("Načítám novinky")
    }
}

// MARK: - Match slider card

/// Skeleton karty zápasu ve slideru — šířka 250 jako reálná karta.
struct MatchCardSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            HBTheme.cardInset
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 12) {
                HBSkeletonBone(width: 88, height: 10, cornerRadius: 4)

                HStack(spacing: 10) {
                    Circle()
                        .fill(HBTheme.cardInset)
                        .frame(width: 24, height: 24)
                        .hbShimmer()
                    HBSkeletonBone(height: 14, cornerRadius: 4)
                    Spacer(minLength: 8)
                    HBSkeletonBone(width: 28, height: 16, cornerRadius: 4)
                }

                HStack(spacing: 10) {
                    Circle()
                        .fill(HBTheme.cardInset)
                        .frame(width: 24, height: 24)
                        .hbShimmer()
                    HBSkeletonBone(height: 14, cornerRadius: 4)
                    Spacer(minLength: 8)
                    HBSkeletonBone(width: 28, height: 16, cornerRadius: 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .frame(width: 250, height: 118)
        .background(HBTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .accessibilityLabel("Načítám zápas")
    }
}

struct MatchSliderSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    MatchCardSkeleton()
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.vertical, 2)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - News list card

/// Skeleton karty článku na stránce Novinky.
struct NewsArticleCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(HBTheme.cardInset)
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .hbShimmer()
                .overlay(alignment: .bottomLeading) {
                    HBSkeletonBone(width: 70, height: 22, cornerRadius: 11)
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                HBSkeletonBone(height: 16, cornerRadius: 5)
                HBSkeletonBone(width: 220, height: 16, cornerRadius: 5)
                HBSkeletonBone(height: 12, cornerRadius: 4)
                HBSkeletonBone(width: 160, height: 12, cornerRadius: 4)
                HBSkeletonBone(width: 90, height: 11, cornerRadius: 4)
                    .padding(.top, 2)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .accessibilityLabel("Načítám článek")
    }
}

struct NewsListSkeleton: View {
    var count: Int = 4

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                NewsArticleCardSkeleton()
            }
        }
        .padding(HBTheme.screenPadding)
        .allowsHitTesting(false)
    }
}

// MARK: - Article body

struct ArticleBodySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<6, id: \.self) { i in
                HBSkeletonBone(
                    width: i == 5 ? 160 : nil,
                    height: 13,
                    cornerRadius: 4
                )
            }
        }
        .padding(.vertical, 8)
        .accessibilityLabel("Načítám text článku")
    }
}
