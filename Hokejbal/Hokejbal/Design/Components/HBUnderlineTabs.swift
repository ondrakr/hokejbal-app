import SwiftUI

/// Horizontální menu s podtržením aktivní položky (enum taby).
struct HBUnderlineTabs<Tab: Hashable & RawRepresentable>: View where Tab.RawValue == String, Tab: CaseIterable {
    @Binding var selection: Tab
    /// Stejná šířka položek (vhodné pro 2–4 taby v kartě).
    var equalWidth: Bool = false
    /// Kompaktní styl uvnitř karty (bez plné šířky paddingů).
    var embedded: Bool = false

    var body: some View {
        HBUnderlineTabBar(
            items: Array(Tab.allCases).map { .init(id: $0, title: $0.rawValue) },
            selection: $selection,
            equalWidth: equalWidth,
            embedded: embedded
        )
    }
}

/// Dynamické taby (např. Vše + soutěže na LIVE / detail zápasu).
struct HBUnderlineTabBar<ID: Hashable>: View {
    struct Item: Hashable {
        let id: ID
        let title: String
    }

    let items: [Item]
    @Binding var selection: ID
    var equalWidth: Bool = false
    var embedded: Bool = false

    private var barHeight: CGFloat { embedded ? 44 : 46 }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if equalWidth {
                    equalWidthRow
                        .padding(.horizontal, embedded ? 8 : HBTheme.screenPadding)
                } else {
                    scrollableRow
                }
            }
            .frame(height: barHeight)
            .clipped()

            Rectangle()
                .fill(HBTheme.separator.opacity(embedded ? 0.7 : 1))
                .frame(height: 0.5)
        }
        .background(embedded ? Color.clear : HBTheme.surface)
    }

    private var equalWidthRow: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.id) { item in
                tabButton(item)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var scrollableRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.id) { item in
                        tabButton(item)
                            .id(item.id)
                    }
                }
                .padding(.horizontal, embedded ? 4 : HBTheme.screenPadding - 14)
            }
            // Jen vodorovný bounce — žádné tahání nahoru/dolů.
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onChange(of: items) { _, _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
        }
    }

    private func tabButton(_ item: Item) -> some View {
        let isSelected = selection == item.id
        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selection = item.id
            }
        } label: {
            VStack(spacing: embedded ? 7 : 8) {
                Text(item.title.uppercased())
                    .font(.hbMontserrat(size: embedded ? 11 : 12, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(isSelected ? HBTheme.brand : HBTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, equalWidth ? 4 : 14)
                    .padding(.top, embedded ? 10 : 12)

                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                    if isSelected {
                        Capsule()
                            .fill(HBTheme.brand)
                            .frame(height: 3)
                            .padding(.horizontal, equalWidth ? 10 : 12)
                    }
                }
            }
            .frame(maxWidth: equalWidth ? .infinity : nil)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
