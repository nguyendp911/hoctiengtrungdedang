import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var phrase = PhraseStore.phrase(at: .now)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PhraseCard(phrase: phrase)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Tất cả từ / câu") {
                    ForEach(PhraseStore.all) { item in
                        Button {
                            phrase = item
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
                    Text("Thêm widget vào màn hình khoá: giữ màn hình khoá › Tuỳ chỉnh › Màn hình khoá › chạm vào ô widget › chọn \"Hán Tự\". Chạm vào widget để mở app và nghe phát âm.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Hán Tự")
        }
        .onOpenURL { url in
            // hanzilock://phrase/<id> — được mở khi chạm vào widget
            guard url.host == "phrase",
                  let id = Int(url.lastPathComponent),
                  let tapped = PhraseStore.phrase(id: id) else { return }
            phrase = tapped
            Speaker.shared.speak(tapped.hanzi)
        }
        .onAppear {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

struct PhraseCard: View {
    let phrase: Phrase

    var body: some View {
        VStack(spacing: 12) {
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
