import SwiftUI

struct LedgerCalendarView: View {
    @ObservedObject var viewModel: LedgerViewModel

    @State private var selectedMonth = Date()
    @State private var selectedDay = Date()
    @State private var isShowingDaySheet = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdayTitles = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    titleHeader
                    monthSwitcher
                    calendarCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingDaySheet) {
            DayRecordListSheet(day: selectedDay, records: records(on: selectedDay), viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var titleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("收支日历")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("按天看看钱的流入和流出")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.cherry)
                .frame(width: 56, height: 56)
                .background(AppTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var monthSwitcher: some View {
        CuteCardView(padding: 14, cornerRadius: 22) {
            HStack(spacing: 12) {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.primary.opacity(0.12), in: Circle())
                }
                .buttonStyle(CutePressButtonStyle())

                Spacer()
                Text(selectedMonth.monthTitle)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Spacer()

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.primary.opacity(0.12), in: Circle())
                }
                .buttonStyle(CutePressButtonStyle())
            }
        }
    }

    private var calendarCard: some View {
        CuteCardView {
            VStack(spacing: 12) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(weekdayTitles, id: \.self) { title in
                        Text(title)
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(calendarDays, id: \.id) { item in
                        CalendarDayCell(
                            day: item.date,
                            isInMonth: item.isInMonth,
                            isToday: calendar.isDateInToday(item.date),
                            expense: total(on: item.date, type: .expense),
                            income: total(on: item.date, type: .income),
                            hasRecords: !records(on: item.date).isEmpty
                        ) {
                            selectedDay = item.date
                            isShowingDaySheet = true
                        }
                    }
                }
            }
        }
    }

    private var calendarDays: [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthDays = calendar.range(of: .day, in: .month, for: selectedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leading = firstWeekday - 1
        var days: [CalendarDay] = []

        for offset in stride(from: leading, to: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -offset, to: monthInterval.start) {
                days.append(CalendarDay(date: date, isInMonth: false))
            }
        }

        for day in monthDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(CalendarDay(date: date, isInMonth: true))
            }
        }

        while !days.count.isMultiple(of: 7) {
            if let last = days.last?.date,
               let date = calendar.date(byAdding: .day, value: 1, to: last) {
                days.append(CalendarDay(date: date, isInMonth: false))
            }
        }

        return days
    }

    private func records(on day: Date) -> [LedgerRecord] {
        viewModel.records
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    private func total(on day: Date, type: LedgerType) -> Double {
        records(on: day)
            .filter { $0.type == type }
            .map(\.amount)
            .reduce(0, +)
    }

    private func moveMonth(by value: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
    }
}

private struct CalendarDay: Identifiable {
    let date: Date
    let isInMonth: Bool

    var id: String {
        DateHelpers.dayKeyFormatter.string(from: date)
    }
}

private struct CalendarDayCell: View {
    let day: Date
    let isInMonth: Bool
    let isToday: Bool
    let expense: Double
    let income: Double
    let hasRecords: Bool
    var action: () -> Void

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: day))
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(isToday ? .white : isInMonth ? AppTheme.text : AppTheme.secondaryText.opacity(0.5))
                    .frame(width: 26, height: 26)
                    .background(isToday ? AppTheme.cherry : Color.clear, in: Circle())

                if expense > 0 {
                    Text("-\(shortAmount(expense))")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(AppTheme.expenseAmountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if income > 0 {
                    Text("+\(shortAmount(income))")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(AppTheme.incomeAmountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if hasRecords {
                    Circle()
                        .fill(AppTheme.cherry.opacity(0.65))
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background((hasRecords ? Color.white.opacity(0.82) : Color.white.opacity(0.48)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isInMonth ? 1 : 0.42)
        }
        .buttonStyle(CutePressButtonStyle())
    }

    private func shortAmount(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "%.1fw", locale: Locale(identifier: "en_US_POSIX"), value / 10000)
        }
        if value >= 1000 {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value)
        }
        return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

#if DEBUG
struct LedgerCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LedgerCalendarView(viewModel: LedgerViewModel())
        }
    }
}
#endif
