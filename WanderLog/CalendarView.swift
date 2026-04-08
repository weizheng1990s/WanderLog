import SwiftUI

// MARK: - Day Sheet Item (avoids isPresented race condition)

struct DaySheetItem: Identifiable {
    let id = UUID()
    let entries: [Entry]
}

// MARK: - Wander Calendar

struct WanderCalendar: View {
    let entries: [Entry]

    @EnvironmentObject private var store: EntryStore
    @EnvironmentObject private var lang: LanguageManager
    @State private var displayMonth: Date = Calendar.current.wanderMonthStart(Date())
    @State private var daySheetItem: DaySheetItem? = nil

    private let cal = Calendar.current

    private var monthStart: Date { cal.wanderMonthStart(displayMonth) }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var firstWeekday: Int {
        cal.component(.weekday, from: monthStart) - 1  // 0=Sun
    }

    private var entriesByDay: [Int: [Entry]] {
        let mc = cal.dateComponents([.year, .month], from: monthStart)
        var dict: [Int: [Entry]] = [:]
        for entry in entries {
            let ec = cal.dateComponents([.year, .month, .day], from: entry.visitedAt)
            if ec.year == mc.year && ec.month == mc.month, let d = ec.day {
                dict[d, default: []].append(entry)
            }
        }
        return dict
    }

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            calendarGrid
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { v in
                    guard abs(v.translation.width) > abs(v.translation.height) else { return }
                    if v.translation.width < -50 { changeMonth(by: 1) }
                    else if v.translation.width > 50 { changeMonth(by: -1) }
                }
        )
        .sheet(item: $daySheetItem) { item in
            DayEntriesSheet(entries: item.entries)
                .environmentObject(store)
                .environmentObject(lang)
        }
    }

    // MARK: Month Header

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wanderMuted)
                    .frame(width: 40, height: 40)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(yearString)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.wanderMuted)
                Text(monthString)
                    .font(.wanderSerif(22))
                    .foregroundColor(.wanderInk)
            }
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wanderMuted)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: Weekday Row

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Su","Mo","Tu","We","Th","Fr","Sa"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.wanderMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Days Grid

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 2
        ) {
            ForEach(Array(0..<firstWeekday).map { -($0 + 1) }, id: \.self) { _ in
                Color.clear.frame(height: 64)
            }
            ForEach(1...max(daysInMonth, 1), id: \.self) { day in
                let dayEntries = entriesByDay[day] ?? []
                CalendarDayCell(
                    day: day,
                    icons: dayEntries.prefix(2).map { store.categoryIcon(for: $0) },
                    isToday: isToday(day)
                ) {
                    if !dayEntries.isEmpty {
                        daySheetItem = DaySheetItem(entries: Array(dayEntries))
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private var yearString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy"
        return f.string(from: monthStart)
    }

    private var monthString: String {
        let f = DateFormatter(); f.dateFormat = "MMMM"
        return f.string(from: monthStart)
    }

    private func isToday(_ day: Int) -> Bool {
        let tc = cal.dateComponents([.year, .month, .day], from: Date())
        let mc = cal.dateComponents([.year, .month], from: monthStart)
        return tc.year == mc.year && tc.month == mc.month && tc.day == day
    }

    private func changeMonth(by n: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayMonth = cal.date(byAdding: .month, value: n, to: displayMonth) ?? displayMonth
        }
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func wanderMonthStart(_ date: Date) -> Date {
        let c = dateComponents([.year, .month], from: date)
        return self.date(from: c) ?? date
    }
}

// MARK: - Day Cell

struct CalendarDayCell: View {
    let day: Int
    let icons: [String]
    let isToday: Bool
    let onTap: () -> Void

    var hasEntries: Bool { !icons.isEmpty }

    var body: some View {
        VStack(spacing: 4) {
            if icons.count >= 2 {
                HStack(spacing: 2) {
                    Image(systemName: icons[0]).font(.system(size: 13))
                    Image(systemName: icons[1]).font(.system(size: 13))
                }
                .foregroundColor(.wanderAccent)
            } else if icons.count == 1 {
                Image(systemName: icons[0])
                    .font(.system(size: 22))
                    .foregroundColor(.wanderAccent)
            } else {
                Spacer()
            }

            Text("\(day)")
                .font(.system(
                    size: hasEntries ? 10 : 14,
                    weight: isToday ? .semibold : .regular
                ))
                .foregroundColor(
                    isToday ? .wanderAccent :
                    hasEntries ? .wanderMuted :
                    Color(.systemGray3)
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .contentShape(Rectangle())
        .onTapGesture { if hasEntries { onTap() } }
    }
}

// MARK: - Day Entries Sheet (Full Screen)

struct DayEntriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    let entries: [Entry]
    @State private var currentIndex: Int = 0
    @State private var navigateToDetail = false
    @State private var selectedEntry: Entry? = nil
    @Environment(\.scenePhase) private var scenePhase
  

    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    VStack(spacing: 12) {
                        // Centered date header
                        VStack(spacing: 4) {
                            Text(dateString)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.wanderInk)
                            Text(weekdayString)
                                .font(.system(size: 13))
                                .foregroundColor(.wanderMuted)
                        }
                        .frame(maxWidth: .infinity)

                        DayEntryCard(entry: entry)
                            .padding(.horizontal, 24)
                            .onTapGesture {
                                selectedEntry = entry
                                navigateToDetail = true
                            }

                        Spacer(minLength: 0)
                    }
                    .padding(.top, 12)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: entries.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .background(Color.wanderWarm.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToDetail) {
                if let entry = selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.s.close) { dismiss() }
                        .foregroundColor(.wanderMuted)
                }
            }
            .onChange(of: scenePhase) { phase in
                // 后台回来时保持当前页，不做任何跳转
                if phase == .active { }
            }
        }
    }

    private var dateString: String {
        guard let entry = entries.first else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMMM d"
        return f.string(from: entry.visitedAt)
    }

    private var weekdayString: String {
        guard let entry = entries.first else { return "" }
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: entry.visitedAt)
    }
}

// MARK: - Day Entry Card

struct DayEntryCard: View {
    let entry: Entry
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var photo: UIImage? = nil

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width
            let photoHeight = cardWidth * 4 / 3

            VStack(spacing: 0) {
                // Photo 3:4
                Group {
                    if let img = photo {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "3A2A1A"), Color(hex: "8B6040")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: cardWidth, height: photoHeight)
                .clipped()

                // Store name centered
                Text(entry.name)
                    .font(.custom("Georgia-Italic", size: 22))
                    .foregroundColor(.wanderInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(hex: "F2EDE4"))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        }
        .aspectRatio(3.0 / (4.0 + 0.22), contentMode: .fit)
        .task {
            if let filename = entry.firstPhotoFilename {
                photo = await Task.detached {
                    PhotoRepository.shared.load(filename)
                }.value
            }
        }
    }
}
