import SwiftUI

// MARK: - Wander Calendar

struct WanderCalendar: View {
    let entries: [Entry]

    @EnvironmentObject private var store: EntryStore
    @EnvironmentObject private var lang: LanguageManager
    @State private var displayMonth: Date = Calendar.current.wanderMonthStart(Date())
    @State private var selectedDayEntries: [Entry] = []
    @State private var showDaySheet = false

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
        .fullScreenCover(isPresented: $showDaySheet) {
            DayEntriesSheet(entries: selectedDayEntries)
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
            ForEach(0..<firstWeekday, id: \.self) { _ in
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
                        selectedDayEntries = Array(dayEntries)
                        showDaySheet = true
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Date header
                    VStack(alignment: .leading, spacing: 3) {
                        Text(dateString)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.wanderInk)
                        Text(weekdayString)
                            .font(.system(size: 14))
                            .foregroundColor(.wanderMuted)
                    }
                    .padding(.top, 8)

                    // Cards list
                    ForEach(entries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            DayEntryCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.wanderWarm.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.s.close) { dismiss() }
                        .foregroundColor(.wanderMuted)
                }
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

    private var subtitleText: String {
        let cat = store.categoryDisplayName(for: entry, lang: lang.language)
        if entry.city.isEmpty {
            return "(\(cat))"
        } else {
            return "(\(cat) in \(entry.city))"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo
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
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            // Info
            VStack(spacing: 6) {
                Text(entry.name)
                    .font(.custom("Georgia-Italic", size: 22))
                    .foregroundColor(.wanderInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color(hex: "F2EDE4"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .task {
            if let filename = entry.firstPhotoFilename {
                photo = await Task.detached {
                    PhotoRepository.shared.load(filename)
                }.value
            }
        }
    }
}
