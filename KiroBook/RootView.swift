import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAddEntry = false
    @State private var showSubscriptionUpgrade = false
    @State private var requiredTier: SubscriptionTier = .free
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var subscription: AppleSubscriptionManager


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

            CustomTabBar(
                selectedTab: $selectedTab,
                showFirstCheckInHint: store.entries.isEmpty,
                onAdd: {
                    Task {
                        await subscription.refreshEntitlements()
                        if subscription.canAddEntry(currentEntryCount: store.entries.count) {
                            showAddEntry = true
                        } else {
                            requiredTier = subscription.requiredTierForEntryCount(store.entries.count + 1)
                            showSubscriptionUpgrade = true
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
        }
        .fullScreenCover(isPresented: $showSubscriptionUpgrade) {
            SubscriptionUpgradeSheet(
                currentEntryCount: store.entries.count,
                requiredTier: requiredTier
            )
        }
        .task {
            subscription.initialize()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await subscription.refreshEntitlements() }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: RootView.Tab
    let showFirstCheckInHint: Bool
    let onAdd: () -> Void
    @EnvironmentObject var lang: LanguageManager
    @State private var isHintPulsing = false

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: lang.s.tabHome, tab: .home, selected: $selectedTab)
            TabBarItem(icon: "map.fill", label: lang.s.tabMap, tab: .map, selected: $selectedTab)

            Button {
                onAdd()
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
                .overlay {
                    if showFirstCheckInHint {
                        Circle()
                            .stroke(Color.wanderAccent.opacity(isHintPulsing ? 0 : 0.75), lineWidth: 2)
                            .frame(width: 68, height: 68)
                            .scaleEffect(isHintPulsing ? 1.35 : 0.85)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(alignment: .top) {
                    if showFirstCheckInHint {
                        FirstCheckInHintBubble(text: lang.s.firstCheckInStart)
                            .offset(y: -58)
                    }
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
        .onAppear { isHintPulsing = true }
        .animation(
            showFirstCheckInHint ? .easeInOut(duration: 1.15).repeatForever(autoreverses: false) : .default,
            value: isHintPulsing
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

struct FirstCheckInHintBubble: View {
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.wanderAccent)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.wanderInk)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .layoutPriority(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 188, alignment: .leading)
        .background(Color.white.opacity(0.97))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wanderAccent.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
        .fixedSize(horizontal: true, vertical: false)
            .allowsHitTesting(false)
    }
}

struct FirstCheckInHighlight: ViewModifier {
    let isActive: Bool
    let text: String
    let cornerRadius: CGFloat
    let bubbleAlignment: Alignment
    let bubbleOffset: CGSize
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .shadow(color: Color.wanderAccent.opacity(isPulsing ? 0.36 : 0.12), radius: isPulsing ? 10 : 4)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: bubbleAlignment) {
                if isActive {
                    FirstCheckInHintBubble(text: text)
                        .offset(bubbleOffset)
                }
            }
            .onAppear { isPulsing = true }
            .onChange(of: isActive) { active in
                guard active else { return }
                isPulsing = false
                DispatchQueue.main.async {
                    isPulsing = true
                }
            }
            .animation(
                isActive ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
    }
}

extension View {
    func firstCheckInHighlight(
        isActive: Bool,
        text: String,
        cornerRadius: CGFloat = 14,
        bubbleAlignment: Alignment = .top,
        bubbleOffset: CGSize = CGSize(width: 0, height: -48)
    ) -> some View {
        modifier(
            FirstCheckInHighlight(
                isActive: isActive,
                text: text,
                cornerRadius: cornerRadius,
                bubbleAlignment: bubbleAlignment,
                bubbleOffset: bubbleOffset
            )
        )
    }
}
