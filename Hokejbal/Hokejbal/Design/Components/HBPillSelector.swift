import SwiftUI

/// Horizontální chipy ve stylu ročníků v detailu hráče (Live / Celkem / Domácí…).
struct HBChipRow<Value: Hashable>: View {
    let items: [(value: Value, label: String)]
    @Binding var selection: Value
    /// Menší horní mezera (např. druhá řada Forma 5/10/15 pod Live/Celkem).
    var stacked: Bool = false
    /// Menší spodní mezera, když hned pod ní následuje další řada chipů.
    var tightBottom: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.value) { item in
                    let selected = selection == item.value
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = item.value
                        }
                    } label: {
                        Text(item.label)
                            .font(.hbMontserrat(size: 13, weight: .semibold))
                            .foregroundStyle(selected ? HBTheme.onBrand : HBTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected ? HBTheme.brand : HBTheme.card)
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(selected ? Color.clear : HBTheme.cardStroke, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
        }
        .padding(.top, stacked ? 2 : 6)
        .padding(.bottom, tightBottom ? 4 : 14)
    }
}

/// Segmentovaný přepínač — stejné chipy jako ročníky v detailu hráče.
struct HBPillSelector<Option: Hashable & RawRepresentable>: View where Option.RawValue == String, Option: CaseIterable {
    @Binding var selection: Option
    /// Zachováno kvůli call-site; font je vždy 13 semibold.
    var compact: Bool = false
    /// Volitelný filtr (např. skrýt Live, když není živý zápas).
    var include: ((Option) -> Bool)? = nil
    var stacked: Bool = false
    var tightBottom: Bool = false

    private var items: [(value: Option, label: String)] {
        Array(Option.allCases)
            .filter { include?($0) ?? true }
            .map { ($0, $0.rawValue) }
    }

    var body: some View {
        HBChipRow(
            items: items,
            selection: $selection,
            stacked: stacked,
            tightBottom: tightBottom
        )
    }
}
