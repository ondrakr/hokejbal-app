import SwiftUI

/// Segmentovaný přepínač v tracku (Zápas / 1. třetina / …).
struct HBPillSelector<Option: Hashable & RawRepresentable>: View where Option.RawValue == String, Option: CaseIterable {
    @Binding var selection: Option
    var compact: Bool = false

    private var options: [Option] { Array(Option.allCases) }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.hbMontserrat(size: compact ? 11 : 12, weight: .bold))
                        .foregroundStyle(isSelected ? HBTheme.textPrimary : HBTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 8 : 9)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(HBTheme.card)
                                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HBTheme.cardInset)
        )
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
    }
}
