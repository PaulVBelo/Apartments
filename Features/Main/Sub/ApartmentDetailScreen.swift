import SwiftUI

enum DetailsReferer {
    case search, bookings, myApartments
}

struct ApartmentDetailsSheet: View {
    let apartmentId: String
    var referer: DetailsReferer = .search
    var onClose: () -> Void = {}

    @State private var dto: ApartmentByIdDTO?
    @State private var isLoading = false
    @State private var errorText: String?
    
    @State private var selectedApartmentId: String?

    private var userId: String { AppState.shared.userId }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(8)
                }
                .tint(.primary)

                Spacer()
                Text("Details")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 8)
            .frame(height: 48)

            Divider()

            Group {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading…").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = errorText {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28, weight: .semibold))
                        Text(err).multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let dto {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Apartment")
                            KeyValueTable([
                                ("Address", dto.apartment.address),
                                ("Price", priceString(dto.apartment.price))
                            ])
                            
                            let info = dto.apartment.info
                            let filtered = info.filter { $0.key.lowercased() != "text_desc" }
                            if !filtered.isEmpty {
                                SectionHeader("Info")
                                KeyValueTable(filtered
                                    .sorted { $0.key < $1.key }
                                    .map { (prettyKey($0.key), $0.value) }
                                )
                            }
                            
                            if let desc = info["text_desc"], !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                SectionHeader("Description")
                                Text(desc)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                                                    
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let dto {
                if referer == .myApartments {
                    PrimaryBottomButton(title: "EDIT") {
                        let vc = ApartmentEditorViewController(mode: .edit(existing: dto.apartment))
                        let nav = UINavigationController(rootViewController: vc)
                        RootSwitcher.presentModally(nav)
                    }
                } else if dto.apartment.owner_id != userId {
                    PrimaryBottomButton(title: "BOOK") {
                        let vc = BookingViewController(
                            apartment: dto.apartment,
                            bookings: dto.bookings
                        )
                        let nav = UINavigationController(rootViewController: vc)
                        RootSwitcher.presentModally(nav)
                    }
                }
            }
        }
        .task { await load() }
        .onAppear() { Task {await load()} }
        .onReceive(NotificationCenter.default.publisher(for: .apartmentsChanged), perform: { _ in
            Task {await load()}
        })
        .onReceive(NotificationCenter.default.publisher(for: .bookingsChanged), perform: { _ in
            Task {await load()}
        })
    }

    private func load() async {
        if isLoading {return}
        
        isLoading = true
        errorText = nil
        do {
            let res = try await AppState.shared.api.apartmentDetails(id: apartmentId)
            await MainActor.run { self.dto = res; self.isLoading = false }
        } catch {
            await MainActor.run {
                self.errorText = "Failed to load: \(error)"
                self.isLoading = false
            }
        }
    }

    private func priceString(_ p: Double) -> String {
        String(format: "%.2f", p)
    }
    private func prettyKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Small UI pieces

private struct SectionHeader: View {
    let title: String
    init(_ t: String) { title = t }
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

private struct KeyValueTable: View {
    let rows: [(String, String)]
    init(_ rows: [(String, String)]) { self.rows = rows }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { i in
                let row = rows[i]
                HStack(alignment: .firstTextBaseline) {
                    Text(row.0)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 12)
                    Text(row.1)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 10)

                if i < rows.count - 1 {
                    Divider().opacity(0.35)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PrimaryBottomButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(title == "EDIT" ? Color(.systemBlue) : Color(.systemGreen))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}
