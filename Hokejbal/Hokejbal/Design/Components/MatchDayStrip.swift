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

    private var isTodaySelected: Bool {
        calendar.isDate(selectedDate, inSameDayAs: today)
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 4) {
                if !isTodaySelected {
                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            selectedDate = today
                            scrollToSelected(proxy)
                        } label: {
                            Text("Dnes")
                                .font(.hbMontserrat(size: 12, weight: .bold))
                                .foregroundStyle(HBTheme.brand)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day)
                                .id(dayKey(day))
                        }
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 8)
                }
            }
            .padding(.top, 4)
            .onAppear {
                clampSelectionIntoWindowIfNeeded()
                scrollToSelected(proxy)
            }
            .onChange(of: selectedDate) { _, _ in scrollToSelected(proxy) }
            .onChange(of: datesWithMatches) { _, _ in scrollToSelected(proxy) }
        }
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

        let dow = Self.shortDow(dayStart)
        // Dny bez zápasu působí „disabled" — ztlumené a neaktivní.
        let isEnabled = hasMatches || isSelected
        let dayColor: Color = {
            if isSelected { return .white }
            if !isEnabled { return HBTheme.textTertiary.opacity(0.5) }
            return isToday ? HBTheme.brand : HBTheme.textPrimary
        }()
        let dowColor: Color = {
            if isSelected { return .white.opacity(0.9) }
            if !isEnabled { return HBTheme.textTertiary.opacity(0.5) }
            return isToday ? HBTheme.brand : HBTheme.textTertiary
        }()

        return Button {
            selectedDate = dayStart
        } label: {
            VStack(spacing: 3) {
                Text(dow)
                    .font(.hbMontserrat(size: 10, weight: .semibold))
                    .tracking(0.3)
                    .foregroundStyle(dowColor)

                Text(Self.dayNumber(dayStart))
                    .font(.hbNumber(size: 17, weight: isSelected || isToday ? .bold : .medium))
                    .foregroundStyle(dayColor)
            }
            .frame(minWidth: 42, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? HBTheme.brand : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
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
        f.dateFormat = "d"
        return f
    }()

    private static func shortDow(_ date: Date) -> String {
        String(dowFormatter.string(from: date).prefix(2)).uppercased()
    }

    private static func dayNumber(_ date: Date) -> String {
        dayNumberFormatter.string(from: date)
    }
}
