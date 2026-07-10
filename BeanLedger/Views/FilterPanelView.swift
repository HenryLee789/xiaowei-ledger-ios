import SwiftUI

struct FilterPanelView: View {
    @Binding var filter: RecordFilterState
    let categoryOptions: [String]
    var moveMonth: (Int) -> Void
    var clearFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            searchBox
            monthFilter
            typeFilter
            categoryFilter
            rangeFilter
            sortFilter
        }
    }

    private var searchBox: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.cherry)
            TextField("搜索备注、类型、类目或金额", text: $filter.searchText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(15)
        .background(AppTheme.elevatedSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var monthFilter: some View {
        CuteCardView(padding: 14, cornerRadius: 22) {
            HStack(spacing: 12) {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.primary.opacity(0.12), in: Circle())
                }
                .buttonStyle(CutePressButtonStyle())

                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.cherry)
                Text(filter.selectedMonth.monthTitle)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Spacer()

                Button {
                    moveMonth(1)
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

    private var typeFilter: some View {
        filterSection(title: "一级类型筛选") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryPill(title: "全部", isSelected: filter.selectedType == nil, color: AppTheme.cherry) {
                        filter.selectedType = nil
                        filter.selectedCategory = nil
                    }
                    ForEach(LedgerType.allCases) { type in
                        CategoryPill(title: type.displayName, isSelected: filter.selectedType == type, color: type.tint) {
                            filter.selectedType = type
                            filter.selectedCategory = nil
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var categoryFilter: some View {
        filterSection(title: "二级类目筛选") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryPill(title: "全部类目", isSelected: filter.selectedCategory == nil, color: AppTheme.primaryDeep) {
                        filter.selectedCategory = nil
                    }
                    ForEach(categoryOptions, id: \.self) { category in
                        CategoryPill(title: category, isSelected: filter.selectedCategory == category, color: filter.selectedType?.tint ?? AppTheme.primaryDeep) {
                            filter.selectedCategory = category
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var rangeFilter: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("高级范围")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Button(action: clearFilters) {
                        Label("清空筛选", systemImage: "xmark.circle.fill")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(AppTheme.cherry)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(AppTheme.primary.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(CutePressButtonStyle())
                }

                HStack(spacing: 10) {
                    amountField("最小金额", text: $filter.minimumAmountText)
                    amountField("最大金额", text: $filter.maximumAmountText)
                }

                Toggle("启用开始日期", isOn: $filter.useStartDate)
                    .font(.system(size: 13, weight: .bold))
                    .tint(AppTheme.cherry)
                if filter.useStartDate {
                    DatePicker("开始日期", selection: $filter.startDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .tint(AppTheme.cherry)
                }

                Toggle("启用结束日期", isOn: $filter.useEndDate)
                    .font(.system(size: 13, weight: .bold))
                    .tint(AppTheme.cherry)
                if filter.useEndDate {
                    DatePicker("结束日期", selection: $filter.endDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .tint(AppTheme.cherry)
                }
            }
        }
    }

    private var sortFilter: some View {
        filterSection(title: "排序") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SortOption.allCases) { option in
                        CategoryPill(title: option.displayName, isSelected: filter.sortOption == option, color: AppTheme.cherry) {
                            filter.sortOption = option
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            content()
        }
    }

    private func amountField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
            TextField("不限", text: text)
                .decimalPadKeyboard()
                .font(.system(size: 14, weight: .semibold))
                .padding(12)
                .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) { value in
                    text.wrappedValue = sanitizedAmount(value)
                }
        }
    }

    private func sanitizedAmount(_ input: String) -> String {
        var result = ""
        var hasDecimalPoint = false
        for character in input {
            if character.isNumber {
                result.append(character)
            } else if character == ".", !hasDecimalPoint {
                hasDecimalPoint = true
                result.append(character)
            }
        }
        return result
    }
}

