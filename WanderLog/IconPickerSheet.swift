import SwiftUI

struct IconPickerSheet: View {
    let title: String
    @Binding var name: String
    @Binding var icon: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    // 图标库，按主题分组
    let iconGroups: [(String, [String])] = [
        ("餐饮", [
            "cup.and.saucer.fill", "mug.fill", "wineglass.fill",
            "fork.knife", "cart.fill", "takeoutbag.and.cup.and.straw.fill",
            "birthday.cake.fill", "popcorn.fill"
        ]),
        ("文化", [
            "building.columns.fill", "books.vertical.fill", "photo.artframe",
            "music.note", "theatermasks.fill", "film.fill",
            "paintbrush.fill", "guitars.fill"
        ]),
        ("购物", [
            "bag.fill", "cart.fill", "handbag.fill",
            "tag.fill", "giftcard.fill", "gift.fill",
            "tshirt.fill", "eyeglasses"
        ]),
        ("休闲", [
            "figure.walk", "bicycle", "sportscourt.fill",
            "beach.umbrella.fill", "tent.fill", "mountain.2.fill",
            "pawprint.fill", "leaf.fill"
        ]),
        ("场所", [
            "mappin.and.ellipse", "house.fill", "building.2.fill",
            "building.fill", "ferry.fill", "airplane",
            "train.side.front.car", "car.fill"
        ]),
        ("其他", [
            "star.fill", "heart.fill", "sparkles",
            "camera.fill", "photo.fill", "bolt.fill",
            "flame.fill", "crown.fill"
        ]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 名称输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("类型名称")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1).foregroundColor(.wanderMuted)
                            .textCase(.uppercase)
                        TextField("输入类型名称", text: $name)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16).padding(.vertical, 13)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.wanderBlush, lineWidth: 1))
                    }

                    // 预览
                    VStack(spacing: 8) {
                        Text("预览")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1).foregroundColor(.wanderMuted)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 12) {
                            // 未选中样式
                            VStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.wanderAccent)
                                Text(name.isEmpty ? "类型名称" : name)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .foregroundColor(.wanderInk)
                            }
                            .frame(width: 80).padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.wanderBlush, lineWidth: 1))

                            // 选中样式
                            VStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Text(name.isEmpty ? "类型名称" : name)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80).padding(.vertical, 12)
                            .background(Color.wanderInk)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    // 图标选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择图标")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1).foregroundColor(.wanderMuted)
                            .textCase(.uppercase)

                        ForEach(iconGroups, id: \.0) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.0)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.wanderMuted)

                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                                    spacing: 10
                                ) {
                                    ForEach(group.1, id: \.self) { sym in
                                        Button {
                                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                icon = sym
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(icon == sym ? Color.wanderInk : Color.white)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(icon == sym ? Color.clear : Color.wanderBlush, lineWidth: 1)
                                                    )
                                                Image(systemName: sym)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(icon == sym ? .white : .wanderAccent)
                                            }
                                            .frame(height: 48)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.wanderWarm)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.wanderMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        onConfirm()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? .wanderMuted : .wanderAccent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
