import SwiftUI

struct FilterBuilderView: View {
    @Binding var filter: SearchFilter
    var onSearch: () -> Void

    @State private var prompt: String = SearchPrompts.random()
    @FocusState private var focus: Field?

    @State private var playful = Bool.random() && Double.random(in: 0...1) < 0.2
    @State private var pulse = false

    enum Field { case city, rooms, beds }

    @State private var roomsText = ""
    @State private var bedsText = ""

    var body: some View {
        ZStack {
            appBarColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text(prompt)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .rotationEffect(.degrees(playful ? -5 : 0))
                    .offset(y: playful ? 6 : 0)
                    .scaleEffect(playful && pulse ? 1.04 : 1.0)
                    .onAppear {
                        roomsText = filter.rooms.map(String.init) ?? ""
                        bedsText  = filter.beds.map(String.init) ?? ""

                        guard playful else { return }
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulse.toggle()
                        }
                    }
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    // City
                    LabeledTextField(
                        label: "City",
                        text: Binding(
                            get: { filter.city ?? "" },
                            set: { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines) 
                                filter.city = trimmed.isEmpty ? nil : trimmed
                            }
                        )
                    )
                    .focused($focus, equals: .city)
                    .keyboardType(.default)
                    .submitLabel(.next)

                    HStack(spacing: 12) {
                        LabeledTextField(label: "Rooms", text: $roomsText)
                            .focused($focus, equals: .rooms)
                            .keyboardType(.numberPad)
                            .onChange(of: roomsText) { new in
                                let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    filter.rooms = nil
                                } else if let value = Int(trimmed) {
                                    filter.rooms = value
                                }
                            }

                        LabeledTextField(label: "Beds", text: $bedsText)
                            .focused($focus, equals: .beds)
                            .keyboardType(.numberPad)
                            .onChange(of: bedsText) { new in
                                let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    filter.beds = nil
                                } else if let value = Int(trimmed) {
                                    filter.beds = value
                                }
                            }
                    }
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    onSearch()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

private struct LabeledTextField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextField(label, text: $text)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
