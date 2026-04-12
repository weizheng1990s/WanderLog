import SwiftUI

enum CategoryFilter: Equatable {
    case standard(PlaceCategory)
    case custom(UUID)
}

struct HomeView: View {
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedFilter: CategoryFilter? = nil
    @AppStorage("profile_name") private var profileName: String = ""
    @AppStorage("profile_tagline") private var profileTagline: String = ""

    var entries: [Entry] {
        store.entries.sorted { $0.visitedAt > $1.visitedAt }
    }

    var filteredEntries: [Entry] {
        guard let filter = selectedFilter else { return entries }
        switch filter {
        case .standard(let cat):
            return entries.filter { $0.category == cat && $0.customCategoryID == nil }
        case .custom(let id):
            return entries.filter { $0.customCategoryID == id }
        }
    }

    var uniqueCities: Int {
        Set(entries.map { $0.city }.filter { !$0.isEmpty }).count
    }

    var uniqueCountries: Int {
        Set(entries.map { $0.country }.filter { !$0.isEmpty }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .zIndex(1)

                    statsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    categoryFilter
                        .padding(.bottom, 20)

                    if entries.isEmpty {
                        emptyState
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    } else {
                        WanderCalendar(entries: filteredEntries)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color.wanderWarm)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text("✦ Kiro Book")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(3)
                    .foregroundColor(.wanderAccent)
                Spacer()
                LanguageDropdown(selection: $lang.language)
            }
            Text(profileName.isEmpty ? "Hello" : profileName)
                .font(.wanderSerif(22))
                .foregroundColor(.wanderInk)
            Text(profileTagline.isEmpty ? "Explorer." : profileTagline)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.wanderMuted)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(entries.count)", label: lang.s.homeCheckIns)
            StatPill(value: "\(uniqueCities)", label: lang.s.cities)
            StatPill(value: "\(uniqueCountries)", label: lang.s.countries)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: lang.s.all, isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(store.customCategories) { cat in
                    CategoryChip(
                        icon: cat.icon,
                        label: store.displayName(for: cat, lang: lang.language),
                        isSelected: selectedFilter == .custom(cat.id)
                    ) {
                        selectedFilter = selectedFilter == .custom(cat.id) ? nil : .custom(cat.id)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✈️").font(.system(size: 48))
            Text(lang.s.homeNoEntries).font(.wanderSerif(20)).foregroundColor(.wanderInk)
            Text(lang.s.homeNoEntriesHint)
                .font(.system(size: 14))
                .foregroundColor(.wanderMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.wanderSerif(24, weight: .bold))
                .foregroundColor(.wanderInk)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.wanderMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.7))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wanderBlush, lineWidth: 1))
    }
}

struct CategoryChip: View {
    var icon: String? = nil
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(label)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .wanderInk : .wanderMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(isSelected ? Color.wanderAccent : Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct LanguageDropdown: View {
    @Binding var selection: AppLanguage
    @State private var isExpanded = false

    var body: some View {
        // 触发按钮
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 3) {
                Text(selection.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wanderMuted)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.wanderMuted)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isExpanded {
                // 浮层列表，不占布局空间
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { idx, lang in
                        Button {
                            selection = lang
                            withAnimation(.easeInOut(duration: 0.15)) { isExpanded = false }
                        } label: {
                            HStack(spacing: 8) {
                                Text(lang.displayName)
                                    .font(.system(size: 13))
                                    .foregroundColor(selection == lang ? .wanderAccent : .wanderInk)
                                if selection == lang {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.wanderAccent)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                        }
                        if idx < AppLanguage.allCases.count - 1 {
                            Divider().padding(.horizontal, 8)
                        }
                    }
                }
                .fixedSize()
                .background(Color.wanderWarm)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .offset(y: 28)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
                .zIndex(100)
            }
        }
    }
}
