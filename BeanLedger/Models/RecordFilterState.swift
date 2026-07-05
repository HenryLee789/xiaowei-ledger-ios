import Foundation

struct RecordFilterState: Equatable {
    var searchText = ""
    var selectedMonth = Date()
    var selectedType: LedgerType?
    var selectedCategory: String?
    var minimumAmountText = ""
    var maximumAmountText = ""
    var useStartDate = false
    var startDate = Date()
    var useEndDate = false
    var endDate = Date()
    var sortOption: SortOption = .newestFirst

    mutating func reset() {
        searchText = ""
        selectedMonth = Date()
        selectedType = nil
        selectedCategory = nil
        minimumAmountText = ""
        maximumAmountText = ""
        useStartDate = false
        startDate = Date()
        useEndDate = false
        endDate = Date()
        sortOption = .newestFirst
    }
}

