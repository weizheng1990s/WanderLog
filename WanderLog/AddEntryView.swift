import SwiftUI
import SwiftData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editingEntry: Entry? = nil

    @State private var name: String = ""
    @State private var category: PlaceCategory = .cafe
    @State private var note: String = ""
    @State private var mood: Mood = .relaxed
    @State private var rating: Int = 4
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var visitedAt: Date = Date()
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLocating = false

    private let locationManager = LocationManager.shared

    var isEditing: Bool { editingEntry != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    photoSection
                    categorySection
                    basicInfoSection
                    locationSection
                    ratingMoodSection
                    noteSection
                    tagsSection
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.wanderWarm)
            .navigationTitle(isEditing ? "编辑打卡" : "新建打卡")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.foregroundColor(.wanderMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .alert("保存失败", isPresented: $showError) {
                Button("好") {}
            } message: { Text(errorMessage) }
        }
        .onAppear { populateIfEditing() }
        .onChange(of: selectedItems) { _, items in Task { await loadSelectedPhotos(items) } }
        .onChange(of: locationManager.city) { _, val in
            if !val.isEmpty { city = val; isLocating = false }
        }
        .onChange(of: locationManager.country) { _, val in
            if !val.isEmpty { country = val }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            if isSaving {
                ProgressView().tint(.wanderInk)
            } else {
                Text("保存")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(name.isEmpty ? Color.wanderMuted : Color.wanderInk)
                    .clipShape(Capsule())
            }
        }
        .disabled(name.isEmpty || isSaving)
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("照片")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                        photoThumb(img, index: idx)
                    }
                    addPhotoButton
                }
            }
        }
    }

    private var addPhotoButton: some View {
        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.wanderBlush.opacity(0.5))
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.wanderAccent.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    )
                VStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 20))
                    Text("添加").font(.system(size: 11))
                }
                .foregroundColor(.wanderAccent)
            }
        }
    }

    private func photoThumb(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Button {
                selectedImages.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("类型")
            categoryGrid
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
            spacing: 8
        ) {
            ForEach(PlaceCategory.allCases) { cat in
                CategoryButton(cat: cat, isSelected: category == cat) {
                    category = cat
                }
            }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("名称")
            TextField("店名或地点", text: $name).textFieldStyle(WanderTextFieldStyle())
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("位置")
                Spacer()
                locationButton
            }
            HStack(spacing: 10) {
                TextField("城市", text: $city).textFieldStyle(WanderTextFieldStyle())
                TextField("国家", text: $country).textFieldStyle(WanderTextFieldStyle())
            }
            DatePicker("探访日期", selection: $visitedAt, displayedComponents: .date)
                .font(.system(size: 14)).tint(.wanderAccent)
        }
    }

    private var locationButton: some View {
        Button {
            isLocating = true
            locationManager.requestLocation()
        } label: {
            HStack(spacing: 4) {
                if isLocating {
                    ProgressView().scaleEffect(0.7).tint(.wanderAccent)
                } else {
                    Image(systemName: "location.fill")
                }
                Text(isLocating ? "定位中..." : "自动定位")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.wanderAccent)
        }
        .disabled(isLocating)
    }

    // MARK: - Rating & Mood

    private var ratingMoodSection: some View {
        HStack(spacing: 16) {
            ratingSection
            Spacer()
            moodSection
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("评分")
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .wanderAccent : .wanderBlush)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("心情")
            HStack(spacing: 10) {
                moodButton(.loved)
                moodButton(.relaxed)
                moodButton(.amazed)
                moodButton(.neutral)
                moodButton(.tired)
            }
        }
    }

    private func moodButton(_ m: Mood) -> some View {
        let isSelected = mood == m
        return Button {
            mood = m
        } label: {
            Image(systemName: m.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .wanderAccent : .wanderBlush)
                .padding(6)
                .background(isSelected ? Color.wanderBlush : Color.clear)
                .clipShape(Circle())
        }
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("我的感受")
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("写下你的感受，只给自己看...")
                        .font(.system(size: 14))
                        .foregroundColor(.wanderMuted)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }
                TextEditor(text: $note)
                    .font(.system(size: 14))
                    .foregroundColor(.wanderInk)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("标签")
            HStack {
                TextField("添加标签，按回车确认", text: $tagInput)
                    .textFieldStyle(WanderTextFieldStyle())
                    .onSubmit { addTag() }
                Button("添加") { addTag() }
                    .foregroundColor(.wanderAccent)
                    .font(.system(size: 14, weight: .medium))
            }
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.wanderAccent)
            Button {
                tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.wanderMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.wanderBlush)
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundColor(.wanderMuted)
            .textCase(.uppercase)
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) { tags.append(trimmed) }
        tagInput = ""
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) { images.append(img) }
        }
        selectedImages = images
    }

    private func populateIfEditing() {
        guard let entry = editingEntry else { return }
        name = entry.name; category = entry.category; note = entry.note
        mood = entry.mood; rating = entry.rating; city = entry.city
        country = entry.country; visitedAt = entry.visitedAt
        tags = entry.tags.map { $0.name }
        Task {
            let loaded = await Task.detached {
                PhotoRepository.shared.loadAll(entry.photoFilenames)
            }.value
            selectedImages = loaded
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let newFilenames = try PhotoRepository.shared.save(selectedImages)
            if let entry = editingEntry {
                PhotoRepository.shared.delete(entry.photoFilenames)
                entry.name = name; entry.category = category; entry.note = note
                entry.mood = mood; entry.rating = rating; entry.city = city
                entry.country = country; entry.visitedAt = visitedAt
                entry.photoFilenames = newFilenames; entry.tags = resolveTags()
            } else {
                let entry = Entry(
                    name: name, category: category, note: note, mood: mood,
                    rating: rating, city: city, country: country,
                    latitude: locationManager.coordinate?.latitude,
                    longitude: locationManager.coordinate?.longitude,
                    photoFilenames: newFilenames, visitedAt: visitedAt
                )
                entry.tags = resolveTags()
                context.insert(entry)
            }
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    @MainActor
    private func resolveTags() -> [Tag] {
        tags.map { tagName in
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
            if let existing = try? context.fetch(descriptor).first { return existing }
            let newTag = Tag(name: tagName)
            context.insert(newTag)
            return newTag
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let cat: PlaceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .wanderAccent)
                Text(cat.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? .white : .wanderInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.wanderInk : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - TextField Style

struct WanderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundColor(Color.wanderInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.wanderBlush, lineWidth: 1)
            )
    }
}
