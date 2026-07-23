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
                HStack(spacing: 6) {
                    ForEach(days, id: \.self) { day in
                        dayCell(day)
                            .id(dayKey(day))
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 6)
            }
            .onAppear {
                clampSelectionIntoWindowIfNeeded()
                scrollToSelected(proxy)
            }
            .onChange(of: selectedDate) { _, _ in scrollToSelected(proxy) }
            .onChange(of: datesWithMatches) { _, _ in scrollToSelected(proxy) }
        }
        .frame(height: 60)
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
        let hasMatches = normalizedMatchDates.contains(dayStart)

        return Button {
            selectedDate = dayStart
        } label: {
            VStack(spacing: 4) {
                Text(Self.shortDow(dayStart))
                    .font(.system(size: 10, weight: .semibold))
                Text(Self.shortDate(dayStart))
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.white : HBTheme.textPrimary)
            .frame(minWidth: 52, minHeight: 48)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? HBTheme.brand : Color.clear)
            )
            .opacity(hasMatches || isSelected ? 1 : 0.4)
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

    private static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "d.MM."
        return f
    }()

    private static func shortDow(_ date: Date) -> String {
        String(dowFormatter.string(from: date).prefix(2)).uppercased()
    }

    private static func shortDate(_ date: Date) -> String {
        dayMonthFormatter.string(from: date)
    }
}
