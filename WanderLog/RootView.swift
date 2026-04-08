import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAddEntry = false
    @Environment(\.scenePhase) private var scenePhase


    enum Tab {
        case home, map, collection, profile
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                MapTabView()
                    .tag(Tab.map)
                CollectionView()
                    .tag(Tab.collection)
                ProfileView()
                    .tag(Tab.profile)
            }
            .toolbar(.hidden, for: .tabBar)

            CustomTabBar(selectedTab: $selectedTab, showAddEntry: $showAddEntry)
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: RootView.Tab
    @Binding var showAddEntry: Bool
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: lang.s.tabHome, tab: .home, selected: $selectedTab)
            TabBarItem(icon: "map.fill", label: lang.s.tabMap, tab: .map, selected: $selectedTab)

            Button {
                showAddEntry = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.wanderInk)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.wanderCream)
                }
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)

            TabBarItem(icon: "bookmark.fill", label: lang.s.tabCollection, tab: .collection, selected: $selectedTab)
            TabBarItem(icon: "person.fill", label: lang.s.tabProfile, tab: .profile, selected: $selectedTab)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea()
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let tab: RootView.Tab
    @Binding var selected: RootView.Tab

    var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .wanderAccent : .wanderMuted)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .wanderAccent : .wanderMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
