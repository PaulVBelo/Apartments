import SwiftUI

enum AppTab: Hashable {
    case search
    case apartments
    case bookings
}

// MARK: - Header

struct MainHeaderView: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack(alignment: .top) {
            appBarColor
                .ignoresSafeArea(edges: .top)

            HStack(alignment: .center) {
                Text("BOOKING ADVISOR")
                    .font(.custom("HelveticaNeue-Bold", size: 32))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer()

                if !appState.userEmail.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(maskedEmail(appState.userEmail))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Button(action: logout) {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Quit")
                            }
                            .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
        .frame(height: UIConst.headerHeight)
    }

    // MARK: - Helpers

    private func maskedEmail(_ email: String) -> String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }

        let local = String(parts[0])
        let domain = String(parts[1])

        guard local.count > 2 else {
            let first = local.first ?? "?"
            return "\(first)***@\(domain)"
        }

        let first = local.first!
        let last = local.last!
        return "\(first)***\(last)@\(domain)"
    }

    private func logout() {
        appState.userId = ""
        appState.userEmail = ""
        RootSwitcher.toAuth(appState.api)
    }
}

// MARK: - Main container

struct MainContainerView: View {
    @State private var tab: AppTab = .search
    private let tabOrder: [AppTab] = [.search, .apartments, .bookings]

    init() {
        let bg = UIColor(appBarColor)
        let selected = UIColor.white
        let unselected = UIColor.white.withAlphaComponent(0.7)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bg

        appearance.stackedLayoutAppearance.selected.iconColor = selected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]
        appearance.stackedLayoutAppearance.normal.iconColor = unselected
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselected]

        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 4)
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 4)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = selected
        UITabBar.appearance().unselectedItemTintColor = unselected
    }

    var body: some View {
        TabView(selection: $tab) {
            SearchScreen()
                .tag(AppTab.search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            
            MyApartmentsScreen()
                .tag(AppTab.apartments)
                .tabItem { Label("My Apartments", systemImage: "house") }

            MyBookingsScreen()
                .tag(AppTab.bookings)
                .tabItem { Label("My Bookings", systemImage: "alarm") }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            MainHeaderView()
        }
        .enableTabSwipe(selection: $tab, order: tabOrder)
    }
}
