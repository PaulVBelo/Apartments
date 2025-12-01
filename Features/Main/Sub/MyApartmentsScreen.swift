import SwiftUI
import UIKit

struct MyApartmentsScreen: View {
    @State private var items: [FullApartmentResponse] = []
    @State private var isLoading = false
    @State private var errorText: String?

    @State private var selectedApartmentId: String?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isLoading {
                ProgressView("Loading apartments…")
            } else if let err = errorText {
                VStack(spacing: 12) {
                    Text("Error: \(err)")
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            } else if items.isEmpty {
                Text("You have no apartments yet.")
                    .foregroundStyle(.secondary)
            } else {
                List(items) { ap in
                    HStack(alignment: .firstTextBaseline) {
                        Text(ap.address)
                            .font(.headline)
                            .lineLimit(2)
                        Spacer(minLength: 12)
                        Text(priceString(ap.price))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedApartmentId = ap.id }
                }
                .listStyle(.plain)
            }
        }
        .respectsTopHeader()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                let vc = ApartmentEditorViewController(mode: .create)
                let nav = UINavigationController(rootViewController: vc)
                RootSwitcher.presentModally(nav)
            } label: {
                Text("ADD")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.systemBlue))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color(.systemBackground).opacity(0.95))
        }
        .task { await load() }
        .onAppear() { Task {await load()} }
        .onReceive(NotificationCenter.default.publisher(for: .apartmentsChanged), perform: { _ in
            Task {await load()}
        })
        .sheet(isPresented: Binding(
            get: { selectedApartmentId != nil },
            set: { if !$0 { selectedApartmentId = nil } })
        ) {
            if let id = selectedApartmentId {
                ApartmentDetailsSheet(apartmentId: id, referer: .myApartments) {
                    selectedApartmentId = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true; errorText = nil
        do {
            let ownerId = AppState.shared.userId
            let dto = try await AppState.shared.api.apartmentsByOwner(ownerId: ownerId)
            await MainActor.run {
                self.items = dto.apartments
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorText = "Failed to load apartments: \(error)"
                self.isLoading = false
            }
        }
    }

    private func priceString(_ p: Double) -> String {
        String(format: "%.2f", p)
    }
}
