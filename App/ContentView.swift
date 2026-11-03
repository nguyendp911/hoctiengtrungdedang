import SwiftUI

/// Tab "Học": thẻ từ, tìm kiếm, chọn chủ đề, danh sách từ
struct LearnView: View {
    @EnvironmentObject private var model: AppModel
    /// nil = tất cả chủ đề; `TopicPicker.favorites` = từ yêu thích
    @State private var topic: String?
    @State private var query = ""

    private var baseList: [Phrase] {
        if topic == TopicPicker.favorites {
            return model.phrases.filter { model.favorites.contains($0.id) }
        }
        return PhraseStore.phrases(in: model.phrases, topic: topic)
    }

    private var shown: [Phrase] {
        query.isEmpty ? baseList : baseList.filter { $0.matches(query) }
    }

    private var current: Phrase {
        model.picked ?? PhraseStore.phrase(at: Date(), topic: nil,
                                           in: baseList.isEmpty ? model.phrases : baseList,
                                           learned: model.learned)
    }

    private var listTitle: String {
        let name = topic == TopicPicker.favorites ? "Yêu thích" : (topic ?? "Tất cả")
        return "\(name) · \(shown.count) từ"
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        PhraseCard(phrase: current,
                                   isLearned: model.learned.contains(current.id),
                                   isFavorite: model.favorites.contains(current.id),
                                   onToggleLearned: {
                                       // Giữ nguyên thẻ đang xem, không nhảy sang từ khác khi vừa đánh dấu
                                       model.picked = current
                                       model.toggleLearned(current)
                                   },
                                   onToggleFavorite: { model.toggleFavorite(current) })
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        TopicPicker(topics: model.topics, selection: $topic)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                Section(listTitle) {
                    if shown.isEmpty {
                        Text(emptyMessage)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(shown) { item in
                        row(item)
                    }
                }

                if let status = model.status, query.isEmpty {
                    Section { Text(status).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Hán Tự")
            .searchable(text: $query, prompt: "Tìm chữ Hán, pinyin hoặc nghĩa")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.isUpdating {
                        ProgressView()
                    } else {
                        Button {
                            Task { await model.update() }
                        } label: {
                            Label("Cập nhật từ mới", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable { await model.update() }
        }
        .onChange(of: topic) { model.picked = nil }
    }

    private var emptyMessage: String {
        if !query.isEmpty { return "Không tìm thấy từ nào khớp." }
        if topic == TopicPicker.favorites { return "Chưa có từ yêu thích. Bấm ngôi sao trên thẻ từ để thêm." }
        return "Chưa có từ nào."
    }

    private func row(_ item: Phrase) -> some View {
        let isLearned = model.learned.contains(item.id)
        let isFavorite = model.favorites.contains(item.id)
        return Button {
            model.picked = item
            Speaker.shared.speak(item.hanzi)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.hanzi).font(.title3.bold())
                    Text(item.pinyin).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.meaningVi)
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
                if isFavorite {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                }
                if isLearned {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
        }
        .tint(.primary)
        .accessibilityHint("Chạm để nghe phát âm")
        .swipeActions(edge: .trailing) {
            Button(isLearned ? "Chưa thuộc" : "Đã thuộc") { model.toggleLearned(item) }
                .tint(isLearned ? .orange : .green)
        }
        .swipeActions(edge: .leading) {
            Button(isFavorite ? "Bỏ sao" : "Yêu thích") { model.toggleFavorite(item) }
                .tint(.yellow)
        }
    }
}

struct TopicPicker: View {
    /// Giá trị đặc biệt cho mục "Yêu thích"
    static let favorites = "★ Yêu thích"

    let topics: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Tất cả", value: nil)
                chip("Yêu thích", value: Self.favorites, icon: "star.fill")
                ForEach(topics, id: \.self) { chip($0, value: $0) }
            }
            .padding(.vertical, 4)
        }
    }

    private func chip(_ title: String, value: String?, icon: String? = nil) -> some View {
        let isOn = selection == value
        return Button {
            selection = value
        } label: {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.subheadline.weight(isOn ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isOn ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
            .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct PhraseCard: View {
    let phrase: Phrase
    let isLearned: Bool
    let isFavorite: Bool
    var onToggleLearned: () -> Void
    var onToggleFavorite: () -> Void
    @State private var isWriting = false
    @State private var isSpeaking = false
    /// Chữ Hán lớn theo cỡ chữ người dùng chọn trong Cài đặt iPhone
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 12) {
            Text(phrase.topic)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(phrase.hanzi)
                .font(.system(size: hanziSize, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(phrase.pinyin)
                .font(.title2)
                .foregroundStyle(.red)

            Text("Đọc: \(phrase.readingVi)")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let hanViet = phrase.hanViet {
                Text("Hán Việt: \(hanViet)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(phrase.meaningVi)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            if let example = phrase.example {
                Button {
                    Speaker.shared.speak(example.zh)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Label(example.zh, systemImage: "speaker.wave.1")
                            .font(.body.weight(.medium))
                        Text(example.pinyin).font(.footnote).foregroundStyle(.red)
                        Text(example.vi).font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Chạm để nghe câu ví dụ")
            }

            // Nút chính: phát âm, chiếm cả chiều ngang
            Button {
                Speaker.shared.speak(phrase.hanzi)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Phát âm")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            // Bốn nút phụ cùng kích thước: biểu tượng trên, chữ dưới
            HStack(spacing: 8) {
                CardTile(title: "Đọc chậm", icon: "tortoise.fill") {
                    Speaker.shared.speak(phrase.hanzi, slow: true)
                }
                CardTile(title: "Luyện nói", icon: "mic.fill") {
                    isSpeaking = true
                }
                CardTile(title: "Luyện viết", icon: "pencil.and.outline") {
                    isWriting = true
                }
                CardTile(title: "Đã thuộc",
                         icon: isLearned ? "checkmark.circle.fill" : "circle",
                         color: isLearned ? .green : .accentColor,
                         action: onToggleLearned)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                    .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Bỏ yêu thích" : "Thêm vào yêu thích")
        }
        .sheet(isPresented: $isWriting) {
            WritingView(phrase: phrase)
        }
        .sheet(isPresented: $isSpeaking) {
            SpeakingView(phrase: phrase)
        }
    }
}

/// Nút vuông nhỏ trên thẻ từ, các nút luôn rộng bằng nhau
struct CardTile: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(height: 24)
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
