import SwiftUI

struct ResultsListView: View {
    let items: [ShortApartmentResponse]
    let totalCount: Int

    @Binding var pageSize: Int
    @Binding var priceMin: String
    @Binding var priceMax: String
    @Binding var pageIndex: Int

    var onChangeFilters: () -> Void
    var isLoading: Bool
    var errorText: String?
    var onRetry: () -> Void
    var onTapRow: (String) -> Void

    private let pageSizes = [15, 30, 60]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Change Filters") { onChangeFilters() }
                Spacer()
            }
            .padding(.horizontal, 16)

            // controls
            HStack(alignment: .bottom, spacing: 16) {
                // Entries per page
                VStack(alignment: .leading, spacing: 6) {
                    Text("Entries on Page").font(.footnote).foregroundStyle(.secondary)
                    Picker("", selection: $pageSize) {
                        ForEach(pageSizes, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: pageSize) { _ in pageIndex = 0 }
                }

                // Price range
                VStack(alignment: .leading, spacing: 6) {
                    Text("Price Range").font(.footnote).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        TextField("Min", text: $priceMin)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("-")
                        TextField("Max", text: $priceMax)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            Divider()

            if isLoading {
                Spacer()
                ProgressView("Loading…")
                Spacer()
            } else if let err = errorText {
                Spacer()
                VStack(spacing: 10) {
                    Text(err).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Retry") { onRetry() }.buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if items.isEmpty {
                Spacer()
                Text("No results").foregroundStyle(.secondary)
                Spacer()
            } else {
                List(items) { ap in
                    HStack {
                        Text(ap.address).font(.headline).lineLimit(2)
                        Spacer(minLength: 12)
                        Text(String(format: "%.2f", ap.price))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onTapRow(ap.id) }
                }
                .listStyle(.plain)

                let pageCount = max(Int(ceil(Double(totalCount) / Double(max(pageSize, 1)))), 1)
                HStack(spacing: 12) {
                    Button {
                        pageIndex = max(pageIndex - 1, 0)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(pageIndex == 0)

                    Text("Page \(pageIndex + 1) of \(pageCount)")
                        .font(.footnote).foregroundStyle(.secondary)

                    Button {
                        pageIndex = min(pageIndex + 1, pageCount - 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(pageIndex >= pageCount - 1)
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
    }
}
