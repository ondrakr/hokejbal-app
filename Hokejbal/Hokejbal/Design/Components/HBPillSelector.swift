import SwiftUI

/// Livesport-style horizontální kapsle (CELKEM / DOMA / …).
struct HBPillSelector<Option: Hashable & RawRepresentable>: View where Option.RawValue == String, Option: CaseIterable {
    @Binding var selection: Option

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(Option.allCases), id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option.rawValue.uppercased())
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(selection == option ? Color.white : HBTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selection == option ? HBTheme.brand : HBTheme.tertiarySurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.vertical, 10)
        }
    }
}
