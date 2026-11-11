import SwiftUI

/// Học theo bộ thủ: các bộ thủ có trong từ vựng của app (bộ gặp nhiều nhất đứng đầu),
/// chạm vào một bộ để xem các chữ, các từ cùng bộ và ôn riêng nhóm từ đó.
struct RadicalsView: View {
    let phrases: [Phrase]
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var groups: [RadicalStore.Group] = []
    @State private var query = ""
    @ScaledMetric(relativeTo: .title) private var badge: CGFloat = 56

    private var filtered: [RadicalStore.Group] {
        let raw = query.trimmingCharacters(in: .whitespaces)
        let q = raw.folded
        guard !q.isEmpty else { return groups }
        return groups.filter { g in
            g.radical.name.folded.contains(q)
                || g.radical.meaning.folded.contains(q)
                || g.radical.display.contains(raw)
                || g.chars.contains { raw.contains($0) }
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { group in
                NavigationLink {
                    RadicalDetailView(group: group, all: phrases, onChange: onChange)
                } label: {
                    row(group)
                }
            }
            .overlay {
                if groups.isEmpty {
                    ProgressView()
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: "Tên bộ, nghĩa hoặc chữ Hán")
            .navigationTitle("Bộ thủ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .task {
                if groups.isEmpty { groups = RadicalStore.groups(in: phrases) }
            }
        }
    }

    private func row(_ group: RadicalStore.Group) -> some View {
        HStack(spacing: 14) {
            Text(group.radical.display)
                .font(.title)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: badge * 1.4, height: badge)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(group.radical.title).font(.headline)
                Text("\(group.chars.count) chữ · \(group.words.count) từ")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(String(group.chars.prefix(12)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.radical.title), \(group.chars.count) chữ, \(group.words.count) từ")
    }
}

/// Chi tiết một bộ thủ: chữ thuộc bộ (chạm để nghe và lọc), danh sách từ, nút ôn
struct RadicalDetailView: View {
    let group: RadicalStore.Group
    let all: [Phrase]
    var onChange: () -> Void

    @State private var quiz = false
    @State private var selectedChar: Character?
    @ScaledMetric(relativeTo: .title) private var cell: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var big: CGFloat = 64

    private var shownWords: [Phrase] {
        guard let c = selectedChar else { return group.words }
        return group.words.filter { $0.hanzi.contains(c) }
    }

    private var wordsTitle: String {
        if let c = selectedChar { return "Từ có chữ \(String(c)) (\(shownWords.count))" }
        return "Từ có bộ này (\(group.words.count))"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text(group.radical.display).font(.system(size: big))
                    Text(group.radical.title).font(.headline)
                    Text("Bộ số \(group.radical.no) trong 214 bộ thủ Khang Hy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: cell), spacing: 8)], spacing: 8) {
                    ForEach(group.chars, id: \.self) { c in
                        charButton(c)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Chữ thuộc bộ này (\(group.chars.count))")
            } footer: {
                Text("Chạm vào một chữ để nghe và chỉ xem các từ có chữ đó.")
            }

            Section {
                Button {
                    quiz = true
                } label: {
                    Label(selectedChar == nil ? "Ôn các từ của bộ này" : "Ôn các từ có chữ này",
                          systemImage: "checklist")
                }
            }

            Section(wordsTitle) {
                ForEach(shownWords.prefix(200)) { phrase in
                    Button {
                        Speaker.shared.speak(phrase.hanzi)
                    } label: {
                        HStack(spacing: 12) {
                            Text(phrase.hanzi).font(.title3.weight(.semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phrase.pinyin).font(.subheadline).foregroundStyle(.red)
                                Text(phrase.meaningVi)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Chạm để nghe phát âm")
                }
            }
        }
        .navigationTitle("Bộ \(group.radical.name)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $quiz) {
            QuizView(pool: shownWords, all: all, title: "Ôn bộ \(group.radical.name)", onChange: onChange)
        }
    }

    private func charButton(_ c: Character) -> some View {
        let isOn = selectedChar == c
        return Button {
            selectedChar = isOn ? nil : c
            Speaker.shared.speak(String(c))
        } label: {
            Text(String(c))
                .font(.title)
                .frame(width: cell, height: cell)
                .background(isOn ? Color.accentColor.opacity(0.25) : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint("Chạm để nghe và lọc các từ có chữ này")
    }
}
