import SwiftUI

/// Livesport-style horizontální menu s červeným podtržením aktivní položky (enum taby).
struct HBUnderlineTabs<Tab: Hashable & RawRepresentable>: View where Tab.RawValue == String, Tab: CaseIterable {
    @Binding var selection: Tab

    var body: some View {
        HBUnderlineTabBar(
            items: Array(Tab.allCases).map { .init(id: $0, title: $0.rawValue) },
            selection: $selection
        )
    }
}

/// Dynamické taby (např. Vše + soutěže na LIVE).
struct HBUnderlineTabBar<ID: Hashable>: View {
    struct Item: Hashable {
        let id: ID
        let title: String
    }

    let items: [Item]
    @Binding var selection: ID

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.id) { item in
                        Button {
                            selection = item.id
                        } label: {
                            VStack(spacing: 8) {
                                Text(item.title.uppercased())
                                    .font(.hbMontserrat(size: 12, weight: .bold))
                                    .foregroundStyle(selection == item.id ? HBTheme.brand : HBTheme.textTertiary)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 12)

                                Rectangle()
                                    .fill(selection == item.id ? HBTheme.brand : Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding - 14)
            }

            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)
        }
        .background(HBTheme.surface)
    }
}
