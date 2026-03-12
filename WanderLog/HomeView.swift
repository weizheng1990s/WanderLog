import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: EntryStore
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var selectedEntry: Entry? = nil
    @State private var showDetail = false

    var entries: [Entry] {
        store.entries.sorted { $0.visitedAt > $1.visitedAt }
    }

    var filteredEntries: [Entry] {
        guard let cat = selectedCategory else { return entries }
        return entries.filter { $0.category == cat }
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

                    statsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    categoryFilter
                        .padding(.bottom, 20)

                    if filteredEntries.isEmpty {
                        emptyState
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    } else {
                        entriesGrid
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color.wanderWarm)
            .navigationDestination(isPresented: $showDetail) {
                if let entry = selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✦ WANDER")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundColor(.wanderAccent)
            Text("Hello,\nExplorer.")
                .font(.wanderSerif(36))
                .foregroundColor(.wanderInk)
                .lineSpacing(2)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(entries.count)", label: "打卡")
            StatPill(value: "\(uniqueCities)", label: "城市")
            StatPill(value: "\(uniqueCountries)", label: "国家")
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "全部", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PlaceCategory.allCases) { cat in
                    CategoryChip(
                        icon: cat.icon,
                        label: cat.rawValue,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var entriesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(filteredEntries) { entry in
                EntryCard(entry: entry)
                    .onTapGesture {
                        selectedEntry = entry
                        showDetail = true
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✈️").font(.system(size: 48))
            Text("还没有打卡记录").font(.wanderSerif(20)).foregroundColor(.wanderInk)
            Text("点击下方 + 开始记录你的第一个探店")
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
