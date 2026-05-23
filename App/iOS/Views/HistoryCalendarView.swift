import SwiftUI

/// 月間カレンダーグリッド。活動した日にドットを表示し、日付タップで選択を返す。
struct HistoryCalendarView: View {

    let activeDates: Set<Date>
    @Binding var selectedDate: Date?
    @State private var displayedMonth: Date

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
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
            }
            Spacer()
            Text(monthLabel)
                .font(.headline.monospacedDigit())
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
            }
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
            displayedMonth = new
        }
    }
}
