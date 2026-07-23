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
            VStack(spacing: 6) {
                header(proxy)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day)
                                .id(dayKey(day))
                        }
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.bottom, 10)
                }
            }
            .padding(.top, 10)
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

    private func header(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            HBAccentBar(height: 16)
            Text(Self.monthLabel(selectedDate))
                .font(.hbDisplay(size: 16, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)

            Spacer(minLength: 8)

            if !isTodaySelected {
                Button {
                    selectedDate = today
                    scrollToSelected(proxy)
                } label: {
                    Text("Dnes")
                        .font(.hbMontserrat(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.brand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(HBTheme.brand.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
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
        let primaryColor: Color = isSelected ? .white : (isToday ? HBTheme.brand : HBTheme.textPrimary)

        return Button {
            selectedDate = dayStart
        } label: {
            VStack(spacing: 4) {
                Text(dow)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : (isToday ? HBTheme.brand : HBTheme.textTertiary))

                Text(Self.dayNumber(dayStart))
                    .font(.hbNumber(size: 20, weight: .heavy))
                    .foregroundStyle(primaryColor)

                // Indikátor zápasů.
                Circle()
                    .fill(isSelected ? Color.white : HBTheme.brand)
                    .frame(width: 5, height: 5)
                    .opacity(hasMatches ? 1 : 0)
            }
            .frame(minWidth: 46, minHeight: 62)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(HBTheme.brandGradient) : AnyShapeStyle(HBTheme.cardInset))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(HBTheme.brand.opacity(isToday && !isSelected ? 0.5 : 0), lineWidth: 1.5)
            )
            .shadow(color: isSelected ? HBTheme.brand.opacity(0.35) : .clear, radius: 6, y: 3)
            .opacity(hasMatches || isSelected || isToday ? 1 : 0.55)
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
        f.dateFormat = "d"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private static func shortDow(_ date: Date) -> String {
        String(dowFormatter.string(from: date).prefix(2)).uppercased()
    }

    private static func dayNumber(_ date: Date) -> String {
        dayNumberFormatter.string(from: date)
    }

    private static func monthLabel(_ date: Date) -> String {
        monthFormatter.string(from: date).capitalizedFirst
    }
}
