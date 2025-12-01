import SwiftUI

struct MyBookingsScreen: View {
    @State private var items: [BookingResponse] = []
    @State private var isLoading = false
    @State private var errorText: String?

    @State private var selectedApartmentId: String?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isLoading {
                ProgressView("Loading bookings…")
            } else if let err = errorText {
                VStack {
                    Text("Error: \(err)")
                    Button("Retry") { Task { await load() } }
                }
                .padding(.top, 64)
            } else if items.isEmpty {
                Text("You have no bookings yet.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 64)
            } else {
                List(items) { b in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(b.address).font(.headline)
                        Text("\(b.time_from.formatted()) — \(b.time_to.formatted())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedApartmentId = b.ap_id }
                    .listRowSeparator(.visible)
                }
                .listStyle(.plain)
                .padding(.top, 32)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("* To cancel a booking, contact the owner by email")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.95))
        }
        .task { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .bookingsChanged), perform: { _ in
            Task {await load()}
        })

        .sheet(isPresented: Binding(
            get: { selectedApartmentId != nil },
            set: { if !$0 { selectedApartmentId = nil } })
        ) {
            if let apId = selectedApartmentId {
                ApartmentDetailsSheet(apartmentId: apId, referer: .bookings) {
                    selectedApartmentId = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil

        do {
            let uid = AppState.shared.userId
            let result = try await AppState.shared.api.bookingsByUser(userId: uid)
            await MainActor.run {
                self.items = result.bookings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorText = "Failed to load bookings: \(error)"
                self.isLoading = false
            }
        }
    }
}
