import SwiftUI

/// 月間カレンダーグリッド。活動した日にドットを表示し、日付タップで選択を返す。
struct HistoryCalendarView: View {

    let activeDates: Set<Date>
    @Binding var selectedDate: Date?
    @State private var displayedMonth: Date
    @State private var isPickingMonth = false
    @State private var pickerYear: Int = 0
    @State private var pickerMonth: Int = 1

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2  // 月曜開始
        return cal
    }()

    init(activeDates: Set<Date>, selectedDate: Binding<Date?>) {
        self.activeDates = activeDates
        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue ?? Date())
    }

    private var monthDays: [Date?] {
        // 月の初日
        let comp = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comp) else { return [] }
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!

        // 月初の曜日（firstWeekday=2 のとき月曜=1, 火曜=2, ... 日曜=7）
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday + 5) % 7  // 月曜の場合 0、日曜の場合 6

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth))
        }
        // 6 行分（最大 42 セル）になるよう nil で埋める
        while cells.count < 42 {
            cells.append(nil)
        }
        return cells
    }

    private let weekdayLabels = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayHeader
            grid
        }
        .sheet(isPresented: $isPickingMonth) {
            MonthYearPickerSheet(
                year: $pickerYear,
                month: $pickerMonth,
                yearRange: availableYearRange,
                // 「今月へ」「完了」とも閉じる際の applyPickedMonth で一元的に反映する。
                onJumpToCurrentMonth: {
                    pickerYear = calendar.component(.year, from: Date())
                    pickerMonth = calendar.component(.month, from: Date())
                }
            )
            .presentationDetents([.height(320)])
            .onDisappear { applyPickedMonth() }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 月ラベルタップで年月ピッカーを提示し、任意の過去月へ一気に移動できる。
            Button {
                presentMonthPicker()
            } label: {
                HStack(spacing: 4) {
                    Text(monthLabel)
                        .font(.headline.monospacedDigit())
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isAtCurrentMonth)
        }
    }

    @ViewBuilder
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isActive = activeDates.contains(calendar.startOfDay(for: date))
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)

        Button {
            if isSelected {
                selectedDate = nil
            } else {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(textColor(isSelected: isSelected, isToday: isToday))
                Circle()
                    .fill(isActive ? OikomiColor.brandPrimary : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? OikomiColor.brandPrimary.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isToday && !isSelected ? OikomiColor.brandPrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func textColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return .accentColor }
        if isToday { return .accentColor }
        return .primary
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by months: Int) {
        if let new = calendar.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = clampToCurrentMonth(new)
        }
    }

    // MARK: - 年月ピッカー連携

    /// 現在月の月初。これより未来へは表示を進めない。
    private var currentMonthStart: Date {
        let comp = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comp) ?? Date()
    }

    private var isAtCurrentMonth: Bool {
        let displayedStart =
            calendar.date(
                from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        return displayedStart >= currentMonthStart
    }

    /// 与えられた日付を月初へ丸めつつ、現在月を上限にクランプする。
    private func clampToCurrentMonth(_ date: Date) -> Date {
        let monthStart =
            calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)) ?? date
        return min(monthStart, currentMonthStart)
    }

    /// 活動日の最小年〜現在年。記録が無ければ現在年のみ。
    private var availableYearRange: ClosedRange<Int> {
        let currentYear = calendar.component(.year, from: Date())
        let minYear = activeDates.map { calendar.component(.year, from: $0) }.min() ?? currentYear
        return min(minYear, currentYear)...currentYear
    }

    private func presentMonthPicker() {
        pickerYear = calendar.component(.year, from: displayedMonth)
        pickerMonth = calendar.component(.month, from: displayedMonth)
        isPickingMonth = true
    }

    /// ピッカーの選択値を月初へ組み立て、クランプして反映する。「完了」「今月へ」共通の適用経路。
    private func applyPickedMonth() {
        var comp = DateComponents()
        comp.year = pickerYear
        comp.month = pickerMonth
        guard let picked = calendar.date(from: comp) else { return }
        displayedMonth = clampToCurrentMonth(picked)
    }
}
