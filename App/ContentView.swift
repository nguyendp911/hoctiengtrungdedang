import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var phrases = PhraseStore.load()
    /// nil = tất cả chủ đề
    @State private var topic: String?
    /// Câu người dùng vừa chạm vào; nil thì hiện câu của giờ hiện tại
    @State private var picked: Phrase?
    @State private var status: String?
    @State private var isUpdating = false

    private var shown: [Phrase] { PhraseStore.phrases(in: phrases, topic: topic) }
    private var current: Phrase { picked ?? PhraseStore.phrase(at: .now, topic: topic, in: phrases) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PhraseCard(phrase: current)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    TopicPicker(topics: PhraseStore.topics(in: phrases), selection: $topic)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("\(topic ?? "Tất cả") · \(shown.count) từ") {
                    ForEach(shown) { item in
                        Button {
                            picked = item
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
                            }
                        }
                        .tint(.primary)
                    }
                }

                Section {
                    if let status {
                        Text(status).font(.footnote)
                    }
                    Text("Đổi chủ đề trên màn hình khoá: giữ màn hình khoá › Tuỳ chỉnh › chạm vào widget Hán Tự › chọn chủ đề. Kéo danh sách xuống để tải từ mới.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Hán Tự")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Button {
                            Task { await update() }
                        } label: {
                            Label("Cập nhật từ mới", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable { await update() }
        }
        .onChange(of: topic) { picked = nil }
        .onOpenURL { url in
            // hanzilock://phrase/<id> — được mở khi chạm vào widget
            guard url.host == "phrase",
                  let id = Int(url.lastPathComponent),
                  let tapped = phrases.first(where: { $0.id == id }) else { return }
            picked = tapped
            Speaker.shared.speak(tapped.hanzi)
        }
        .task { await update(silent: true) }
    }

    private func update(silent: Bool = false) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            let before = Set(phrases.map(\.id))
            phrases = try await PhraseStore.refresh()
            let added = phrases.filter { !before.contains($0.id) }.count
            WidgetCenter.shared.reloadAllTimelines()
            if !silent || added > 0 {
                status = added > 0 ? "Đã thêm \(added) từ mới." : "Đã có bản mới nhất (\(phrases.count) từ)."
            }
        } catch {
            if !silent { status = "Không tải được từ mới. Kiểm tra mạng rồi thử lại." }
        }
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

            Label(phrase.readingVi, systemImage: "text.bubble")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(phrase.meaningVi)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    Speaker.shared.speak(phrase.hanzi)
                } label: {
                    Label("Phát âm", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Speaker.shared.speak(phrase.hanzi, slow: true)
                } label: {
                    Label("Đọc chậm", systemImage: "tortoise.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentView()
}
