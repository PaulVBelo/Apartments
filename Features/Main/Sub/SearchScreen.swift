import SwiftUI

struct SearchScreen: View {
    @ObservedObject private var state = AppState.shared

    @State private var allItems: [ShortApartmentResponse] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedApartmentId: String?
    @State private var pageIndex: Int = 0

    var body: some View {
        Group {
            switch state.search.mode {
            case .builder:
                FilterBuilderView(
                    filter: $state.search.filter,
                    onSearch: { Task { await runSearch() } }
                )
            case .results:
                ResultsListView(
                    items: filteredAndPaged(),
                    totalCount: filteredItems().count,
                    pageSize: $state.search.pageSize,
                    priceMin: Binding(get: { state.search.priceMin?.string ?? "" },
                                      set: { state.search.priceMin = Double($0) }),
                    priceMax: Binding(get: { state.search.priceMax?.string ?? "" },
                                      set: { state.search.priceMax = Double($0) }),
                    pageIndex: $pageIndex,
                    onChangeFilters: { state.search.mode = .builder },
                    isLoading: isLoading,
                    errorText: errorText,
                    onRetry: { Task { await runSearch() } },
                    onTapRow: { id in selectedApartmentId = id }
                )
            }
        }
        .respectsTopHeader()
        .sheet(isPresented: Binding(get: { selectedApartmentId != nil },
                                    set: { if !$0 { selectedApartmentId = nil } })) {
            if let id = selectedApartmentId {
                ApartmentDetailsSheet(apartmentId: id, referer: .search) {
                    selectedApartmentId = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Search flow
    private func runSearch() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        pageIndex = 0

        do {
            let f = state.search.filter
            let dto = try await AppState.shared.api.searchApartments(
                city: f.city.nilIfBlank,
                rooms: f.rooms,
                beds:  f.beds
            )
            await MainActor.run {
                self.allItems = dto.apartments
                self.isLoading = false
                self.state.search.mode = .results
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorText = "Failed to load: \(error)"
                self.state.search.mode = .results
            }
        }
    }

    // MARK: - Client-side price filter + pagination
    private func filteredItems() -> [ShortApartmentResponse] {
        var items = allItems
        if let min = state.search.priceMin { items = items.filter { $0.price >= min } }
        if let max = state.search.priceMax { items = items.filter { $0.price <= max } }
        return items
    }

    private func filteredAndPaged() -> [ShortApartmentResponse] {
        let items = filteredItems()
        let ps = max(state.search.pageSize, 1)
        let start = pageIndex * ps
        let end   = min(start + ps, items.count)
        if start >= end { return [] }
        return Array(items[start..<end])
    }
}
