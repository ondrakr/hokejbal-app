import SwiftUI

/// Přepínač webů ve stylu hlavičky hokejbal.cz / cmshb.cz.
struct SiteSwitchSheet: View {
    @EnvironmentObject private var brandStore: AppBrandStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(AppBrand.allCases) { option in
                    Button {
                        brandStore.select(option)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.displayName)
                                .font(.hbMontserrat(size: 16, weight: .bold))
                                .foregroundStyle(
                                    brandStore.brand == option ? HBTheme.onBrand : HBTheme.textPrimary
                                )
                            Spacer(minLength: 0)
                            if brandStore.brand == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HBTheme.onBrand)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            brandStore.brand == option ? HBTheme.brand : HBTheme.card,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    brandStore.brand == option ? Color.clear : HBTheme.cardStroke,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(HBTheme.screenPadding)
            .padding(.top, 8)
            .background(HBTheme.canvas.ignoresSafeArea())
            .navigationTitle("Web")
            .navigationBarTitleDisplayMode(.inline)
            .hbNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
}
