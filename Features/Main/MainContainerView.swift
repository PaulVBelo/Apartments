import SwiftUI

enum AppTab: Hashable {
    case search, apartments, bookings
}

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
            ZStack(alignment: .top) {
                appBarColor
                    .ignoresSafeArea(edges: .top)
                Text("BOOKING ADVISOR")
                    .font(.custom("HelveticaNeue-Bold", size: 28))
                    .foregroundColor(.white)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: UIConst.headerHeight)
        }
        .enableTabSwipe(selection: $tab, order: tabOrder)
    }
}
