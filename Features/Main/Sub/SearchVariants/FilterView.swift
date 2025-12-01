import SwiftUI

struct FilterBuilderView: View {
    @Binding var filter: SearchFilter
    var onSearch: () -> Void

    @State private var prompt: String = SearchPrompts.random()
    @State private var keyToAdd: FilterKey = .city
    @FocusState private var focus: Field?

    @State private var playful = Bool.random() && Double.random(in: 0...1) < 0.2
    @State private var pulse = false

    enum Field { case city, rooms, beds }
    enum FilterKey: String, CaseIterable { case city, rooms, beds }
    
    @State private var roomsText = ""
    @State private var bedsText = ""

    private var hasAnyFilter: Bool {
        filter.city != nil || filter.rooms != nil || filter.beds != nil
    }

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
                        guard playful else { return }
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulse.toggle()
                        }
                    }
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    Button {
                        addCurrentKey()
                    } label: {
                        Label("Add Filter", systemImage: "plus.circle")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        onSearch()
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Picker("Filter", selection: $keyToAdd) {
                    ForEach(FilterKey.allCases, id: \.self) { key in
                        Text(key.rawValue.capitalized).tag(key)
                    }
                }
                .pickerStyle(.segmented)

                if hasAnyFilter {
                    VStack(spacing: 12) {
                        if filter.city != nil {
                            LabeledTextField(label: "City", text: Binding(
                                get: { filter.city ?? "" },
                                set: { filter.city = $0 })
                            )
                            .focused($focus, equals: .city)
                            .keyboardType(.default)
                            .submitLabel(.done)
                            .chipRemovable { filter.city = nil }
                        }

                        if filter.rooms != nil {
                            LabeledTextField(label: "Rooms", text: $roomsText)
                                .focused($focus, equals: .rooms)
                                .keyboardType(.numberPad)
                                .onChange(of: roomsText) { new in
                                    let t = new.trimmingCharacters(in: .whitespaces)
                                    if t.isEmpty {
                                        filter.rooms = nil
                                    } else if let v = Int(t) {
                                        filter.rooms = v
                                    }
                                }
                                .chipRemovable {
                                    filter.rooms = nil
                                    roomsText = ""
                                }
                        }

                        if filter.beds != nil {
                            LabeledTextField(label: "Beds", text: $bedsText)
                                .focused($focus, equals: .beds)
                                .keyboardType(.numberPad)
                                .onChange(of: bedsText) { new in
                                    let t = new.trimmingCharacters(in: .whitespaces)
                                    if t.isEmpty {
                                        filter.beds = nil
                                    } else if let v = Int(t) {
                                        filter.beds = v
                                    }
                                }
                                .chipRemovable {
                                    filter.beds = nil
                                    bedsText = ""
                                }
                        }
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func addCurrentKey() {
        switch keyToAdd {
        case .city:
            if filter.city == nil { 
                filter.city = ""
                focus = .city
            }
        case .rooms:
            if filter.rooms == nil {
                filter.rooms = 0
                roomsText = ""
                focus = .rooms
            }
        case .beds:
            if filter.beds == nil {
                filter.beds = 0
                bedsText = ""
                focus = .beds
            }
        }
    }
}

private struct LabeledTextField: View {
    var label: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundStyle(.secondary)
            TextField(label, text: $text)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct ChipRemove: ViewModifier {
    var onRemove: () -> Void

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(appBarColor)
                    .padding(.trailing, 2)
            }
            .buttonStyle(.plain)
        }
    }
}

extension View {
    func chipRemovable(onRemove: @escaping () -> Void) -> some View {
        self.modifier(ChipRemove(onRemove: onRemove))
    }
}
