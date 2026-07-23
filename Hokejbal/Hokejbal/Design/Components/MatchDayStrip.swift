import SwiftUI

/// Horizontální výběr dne — pevné okno kolem dneška (bez nekonečného scrollu).
struct MatchDayStrip: View {
    @Binding var selectedDate: Date
    let datesWithMatches: Set<Date>

    /// Kolik dnů zpět / dopředu od dneška.
    var pastDays: Int = 21
    var futureDays: Int = 42

    private var calendar: Calendar { .current }

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var days: [Date] {
        (-pastDays...futureDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today).map { calendar.startOfDay(for: $0) }
        }
    }

    private var normalizedMatchDates: Set<Date> {
        Set(datesWithMatches.map { calendar.startOfDay(for: $0) })
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        dayCell(day)
                            .id(dayKey(day))
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 10)
            }
            .onAppear {
                clampSelectionIntoWindowIfNeeded()
                scrollToSelected(proxy)
            }
            .onChange(of: selectedDate) { _, _ in scrollToSelected(proxy) }
            .onChange(of: datesWithMatches) { _, _ in scrollToSelected(proxy) }
        }
        .frame(height: 78)
        .background(HBTheme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }

    private func clampSelectionIntoWindowIfNeeded() {
        let selected = calendar.startOfDay(for: selectedDate)
        guard let first = days.first, let last = days.last else { return }
        if selected < first {
            selectedDate = first
        } else if selected > last {
            selectedDate = last
        } else if !calendar.isDate(selectedDate, inSameDayAs: selected) {
            selectedDate = selected
        }
    }

    private func scrollToSelected(_ proxy: ScrollViewProxy) {
        let key = dayKey(calendar.startOfDay(for: selectedDate))
        DispatchQueue.main.async {
            proxy.scrollTo(key, anchor: .center)
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let dayStart = calendar.startOfDay(for: day)
        let isSelected = calendar.isDate(dayStart, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(dayStart)
        let hasMatches = normalizedMatchDates.contains(dayStart)

        let dow = isToday ? "DNES" : Self.shortDow(dayStart)
        let primaryColor: Color = isSelected ? .white : (isToday ? HBTheme.brand : HBTheme.textPrimary)

        return Button {
            selectedDate = dayStart
        } label: {
            VStack(spacing: 3) {
                Text(dow)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : (isToday ? HBTheme.brand : HBTheme.textTertiary))

                Text(Self.dayNumber(dayStart))
                    .font(.hbNumber(size: 19, weight: .heavy))
                    .foregroundStyle(primaryColor)

                // Indikátor zápasů.
                Circle()
                    .fill(isSelected ? Color.white : HBTheme.brand)
                    .frame(width: 5, height: 5)
                    .opacity(hasMatches ? 1 : 0)
            }
            .frame(minWidth: 50, minHeight: 58)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(HBTheme.brandGradient) : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(HBTheme.brand.opacity(isToday && !isSelected ? 0.4 : 0), lineWidth: 1.5)
            )
            .shadow(color: isSelected ? HBTheme.brand.opacity(0.35) : .clear, radius: 6, y: 3)
            .opacity(hasMatches || isSelected || isToday ? 1 : 0.5)
        }
        .buttonStyle(.plain)
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    private static let dowFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "EE"
        return f
    }()

    private static let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "d.M."
        return f
    }()

    private static func shortDow(_ date: Date) -> String {
        String(dowFormatter.string(from: date).prefix(2)).uppercased()
    }

    private static func dayNumber(_ date: Date) -> String {
        dayNumberFormatter.string(from: date)
    }
}
