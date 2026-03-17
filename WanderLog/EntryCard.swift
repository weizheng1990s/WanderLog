import SwiftUI

struct EntryCard: View {
    let entry: Entry
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = thumbnail {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    categoryGradient
                }
            }
            .frame(height: 200)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) { Image(systemName: entry.category.icon).font(.system(size: 9)); Text(entry.category.rawValue) }
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Capsule())

                Text(entry.name)
                    .font(.wanderSerif(15))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !entry.city.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill").font(.system(size: 9))
                        Text([entry.city, entry.country].filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.system(size: 11)).lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .task {
            if let filename = entry.firstPhotoFilename {
                thumbnail = await Task.detached { PhotoRepository.shared.load(filename) }.value
            }
        }
    }

    private var categoryGradient: some View {
        Rectangle().fill(
            LinearGradient(colors: categoryColors(for: entry.category),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func categoryColors(for category: PlaceCategory) -> [Color] {
        switch category {
        case .cafe:       return [Color(hex:"3D2010"), Color(hex:"8B6040")]
        case .museum:     return [Color(hex:"1A2A3D"), Color(hex:"4A6A8A")]
        case .bar:        return [Color(hex:"2A1A3D"), Color(hex:"6A4A7A")]
        case .bookstore:  return [Color(hex:"3A2A1A"), Color(hex:"7A5C3E")]
        case .gallery:    return [Color(hex:"3A2010"), Color(hex:"C4956A")]
        case .selectShop: return [Color(hex:"1A1A2A"), Color(hex:"4A4A6A")]
        case .restaurant: return [Color(hex:"1A3020"), Color(hex:"4A7A5A")]
        case .other:      return [Color(hex:"2A2A2A"), Color(hex:"6A6A6A")]
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
