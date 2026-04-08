import SwiftUI
import MapKit

struct FullMapView: View {
    let entry: Entry
    let categoryIcon: String
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion

    init(entry: Entry, categoryIcon: String) {
        self.entry = entry
        self.categoryIcon = categoryIcon
        let coord = entry.coordinate ?? CLLocationCoordinate2D(latitude: 31.2, longitude: 121.5)
        _region = State(initialValue: MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let coord = entry.coordinate {
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: [entry]) { e in
                    MapAnnotation(coordinate: coord) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.wanderAccent)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Text(entry.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.wanderInk)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.wanderWarm)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                    }
                }
                .ignoresSafeArea()
            }

            // 顶部栏
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wanderInk)
                        .frame(width: 36, height: 36)
                        .background(Color.wanderWarm)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.wanderInk)
                    if !entry.city.isEmpty {
                        Text([entry.city, entry.country].filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.wanderMuted)
                    }
                }
                Spacer()
                // 跳转到地图 App
                Button {
                    if let coord = entry.coordinate {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
                        mapItem.name = entry.name
                        mapItem.openInMaps()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.wanderAccent)
                        .frame(width: 36, height: 36)
                        .background(Color.wanderWarm)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }
}
