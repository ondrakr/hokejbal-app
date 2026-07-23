import SwiftUI

/// Pevný (ne-glass) výběr ročníku — sheet se solidním pozadím v brand stylu.
struct HBSolidPickerSheet<Option: Identifiable>: View {
    let title: String
    let options: [Option]
    let selectedId: Option.ID?
    let label: (Option) -> String
    let detail: ((Option) -> String?)?
    let onSelect: (Option) -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        options: [Option],
        selectedId: Option.ID?,
        label: @escaping (Option) -> String,
        detail: ((Option) -> String?)? = nil,
        onSelect: @escaping (Option) -> Void
    ) {
        self.title = title
        self.options = options
        self.selectedId = selectedId
        self.label = label
        self.detail = detail
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(option))
                                    .font(.hbMontserrat(size: 16, weight: .semibold))
                                    .foregroundStyle(HBTheme.textPrimary)
                                if let detail, let text = detail(option) {
                                    Text(text)
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                            }
                            Spacer()
                            if option.id == selectedId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HBTheme.brand)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(HBTheme.surface)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(HBTheme.surface)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .hbNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") { dismiss() }
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HBTheme.surface)
    }
}

/// Tlačítko + sheet místo systémového `Menu` (bez Liquid Glass).
struct HBSolidMenuButton<Option: Identifiable, Label: View>: View {
    let title: String
    let options: [Option]
    let selectedId: Option.ID?
    let optionLabel: (Option) -> String
    let optionDetail: ((Option) -> String?)?
    let onSelect: (Option) -> Void
    @ViewBuilder var label: () -> Label

    @State private var showSheet = false

    init(
        title: String,
        options: [Option],
        selectedId: Option.ID?,
        optionLabel: @escaping (Option) -> String,
        optionDetail: ((Option) -> String?)? = nil,
        onSelect: @escaping (Option) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.title = title
        self.options = options
        self.selectedId = selectedId
        self.optionLabel = optionLabel
        self.optionDetail = optionDetail
        self.onSelect = onSelect
        self.label = label
    }

    var body: some View {
        Button {
            showSheet = true
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            HBSolidPickerSheet(
                title: title,
                options: options,
                selectedId: selectedId,
                label: optionLabel,
                detail: optionDetail,
                onSelect: onSelect
            )
        }
    }
}
