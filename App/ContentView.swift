import SwiftUI

/// Tab "Học": thẻ từ, chọn chủ đề, danh sách từ
struct LearnView: View {
    @EnvironmentObject private var model: AppModel
    /// nil = tất cả chủ đề
    @State private var topic: String?

    private var shown: [Phrase] { PhraseStore.phrases(in: model.phrases, topic: topic) }
    private var current: Phrase {
        model.picked ?? PhraseStore.phrase(at: Date(), topic: topic, in: model.phrases, learned: model.learned)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PhraseCard(phrase: current, isLearned: model.learned.contains(current.id)) {
                        // Giữ nguyên thẻ đang xem, không nhảy sang từ khác khi vừa đánh dấu
                        model.picked = current
                        model.toggleLearned(current)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    TopicPicker(topics: model.topics, selection: $topic)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("\(topic ?? "Tất cả") · \(shown.count) từ") {
                    ForEach(shown) { item in
                        Button {
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
                                if model.learned.contains(item.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .tint(.primary)
                        .swipeActions {
                            let isLearned = model.learned.contains(item.id)
                            Button(isLearned ? "Chưa thuộc" : "Đã thuộc") { model.toggleLearned(item) }
                                .tint(isLearned ? .orange : .green)
                        }
                    }
                }

                if let status = model.status {
                    Section { Text(status).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Hán Tự")
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
}

struct TopicPicker: View {
    let topics: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Tất cả", value: nil)
                ForEach(topics, id: \.self) { chip($0, value: $0) }
            }
            .padding(.vertical, 4)
        }
    }

    private func chip(_ title: String, value: String?) -> some View {
        let isOn = selection == value
        return Button(title) { selection = value }
            .font(.subheadline.weight(isOn ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isOn ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .buttonStyle(.plain)
    }
}

struct PhraseCard: View {
    let phrase: Phrase
    let isLearned: Bool
    var onToggleLearned: () -> Void
    @State private var isWriting = false
    @State private var isSpeaking = false

    var body: some View {
        VStack(spacing: 12) {
            Text(phrase.topic)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(phrase.hanzi)
                .font(.system(size: 56, weight: .bold))
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
