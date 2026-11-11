import SwiftUI

/// Ôn tập trắc nghiệm. Chế độ `mixed`: nhìn chữ chọn nghĩa hoặc nhìn nghĩa chọn chữ.
/// Chế độ `listening`: nghe phát âm rồi chọn nghĩa đúng.
/// Chế độ `cloze`: câu ví dụ bị che một từ, chọn từ điền vào chỗ trống.
/// Đúng liên tiếp `ProgressStore.streakToLearn` lần thì từ được tính là đã thuộc.
struct QuizView: View {
    enum Mode { case mixed, listening, cloze }

    /// Từ được ôn
    let pool: [Phrase]
    /// Toàn bộ từ, để lấy đáp án nhiễu khi `pool` ít từ
    let all: [Phrase]
    var mode: Mode = .mixed
    /// Số câu mỗi lượt
    var length: Int = 10
    /// Nếu có (ví dụ 0.6) thì kết quả báo Đạt / Chưa đạt, dùng cho thi thử
    var passMark: Double? = nil
    var title: String? = nil
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correctCount = 0
    @State private var newlyLearned = 0
    @State private var started = false
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize: CGFloat = 52

    enum Kind { case hanziToMeaning, meaningToHanzi, listening, cloze }

    private var defaultTitle: String {
        switch mode {
        case .mixed: return "Ôn tập"
        case .listening: return "Luyện nghe"
        case .cloze: return "Điền chỗ trống"
        }
    }

    struct Question {
        let phrase: Phrase
        let options: [Phrase]
        let kind: Kind
    }

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    if started {
                        ContentUnavailableView("Chưa có câu để luyện", systemImage: "text.badge.xmark",
                                               description: Text("Các từ đã chọn chưa có câu ví dụ phù hợp."))
                    } else {
                        ProgressView()
                    }
                } else if index < questions.count {
                    questionView(questions[index])
                } else {
                    resultView
                }
            }
            .padding()
            .navigationTitle(title ?? defaultTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .onAppear { if questions.isEmpty { start() } }
    }

    private func questionView(_ q: Question) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .accessibilityLabel("Câu \(index + 1) trên \(questions.count)")
            Text("Câu \(index + 1)/\(questions.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            prompt(q)
                .frame(minHeight: 150)

            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { i, option in
                    Button {
                        answer(i, for: q)
                    } label: {
                        let showHanzi = q.kind == .meaningToHanzi || q.kind == .cloze
                        Text(showHanzi ? option.hanzi : option.meaningVi)
                            .font(showHanzi ? .title2.weight(.semibold) : .body.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(tint(for: i, in: q))
                }
            }

            if chosen != nil {
                VStack(spacing: 6) {
                    Text("\(q.phrase.hanzi) · \(q.phrase.pinyin) · \(q.phrase.readingVi)")
                        .font(.subheadline)
                    if q.kind == .cloze, let example = q.phrase.example {
                        Text(example.zh).font(.subheadline.weight(.semibold))
                        Text(example.pinyin).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button(index + 1 < questions.count ? "Câu tiếp" : "Xem kết quả") {
                        chosen = nil
                        index += 1
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer(minLength: 0)
        }
        // Câu nghe tự phát âm khi hiện ra
        .task(id: index) {
            if q.kind == .listening && chosen == nil {
                try? await Task.sleep(nanoseconds: 350_000_000)
                Speaker.shared.speak(q.phrase.hanzi)
            }
        }
    }

    @ViewBuilder
    private func prompt(_ q: Question) -> some View {
        switch q.kind {
        case .hanziToMeaning:
            VStack(spacing: 6) {
                Text(q.phrase.hanzi)
                    .font(.system(size: hanziSize, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(q.phrase.pinyin).font(.title3).foregroundStyle(.red)
                Text("nghĩa là gì?").foregroundStyle(.secondary)
            }
        case .meaningToHanzi:
            VStack(spacing: 6) {
                Text(q.phrase.meaningVi)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("tiếng Trung là gì?").foregroundStyle(.secondary)
            }
        case .listening:
            VStack(spacing: 12) {
                Button {
                    Speaker.shared.speak(q.phrase.hanzi)
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: 88, height: 88)
                        .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nghe lại")
                Text("Nghe và chọn nghĩa đúng").foregroundStyle(.secondary)
            }
        case .cloze:
            VStack(spacing: 10) {
                Text(Cloze.sentence(for: q.phrase) ?? Cloze.blank)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                if let vi = q.phrase.example?.vi {
                    Text(vi)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text("Chọn từ điền vào chỗ trống").font(.footnote).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: correctCount == questions.count ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Đúng \(correctCount)/\(questions.count)")
                .font(.largeTitle.bold())
            if let passMark, !questions.isEmpty {
                let passed = Double(correctCount) / Double(questions.count) >= passMark
                Text(passed ? "Đạt" : "Chưa đạt (cần từ \(Int(passMark * 100))%)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(passed ? Color.green : Color.orange)
            }
            if newlyLearned > 0 {
                Text("Đã thuộc thêm \(newlyLearned) từ")
                    .foregroundStyle(.secondary)
            }
            Text("Trả lời đúng \(ProgressStore.streakToLearn) lần liên tiếp thì từ được tính là đã thuộc; sai sẽ phải học lại.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Ôn tiếp") { start() }
                    .buttonStyle(.borderedProminent)
                Button("Xong") { dismiss() }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 40)
    }

    private func tint(for i: Int, in q: Question) -> Color? {
        guard let chosen else { return nil }
        if q.options[i].id == q.phrase.id { return .green }
        return i == chosen ? .red : .gray
    }

    private func answer(_ i: Int, for q: Question) {
        // Không dùng .disabled vì nút bị vô hiệu hoá sẽ mất màu xanh/đỏ
        guard chosen == nil else { return }
        chosen = i
        let correct = q.options[i].id == q.phrase.id
        if correct { correctCount += 1 }
        if ProgressStore.record(q.phrase.id, correct: correct) { newlyLearned += 1 }
        // Điền chỗ trống: đọc cả câu để nghe từ trong ngữ cảnh
        Speaker.shared.speak(q.kind == .cloze ? (q.phrase.example?.zh ?? q.phrase.hanzi) : q.phrase.hanzi)
        onChange()
    }

    private func start() {
        let learned = ProgressStore.learned
        let snap = ProgressStore.snapshot()
        // Điền chỗ trống chỉ dùng từ có câu ví dụ chứa đúng từ đó
        let source = mode == .cloze ? pool.filter { Cloze.sentence(for: $0) != nil } : pool
        // Từ đến hạn ôn trước, rồi từ mới, cuối cùng là từ chưa đến hạn
        let due = source.filter { snap.state(of: $0.id) == .due }.shuffled()
        let new = source.filter { snap.state(of: $0.id) == .new && !learned.contains($0.id) }.shuffled()
        let dueOrNew = Set((due + new).map(\.id))
        let later = source.filter { !dueOrNew.contains($0.id) }.shuffled()
        let picked = Array((due + new + later).prefix(length))

        questions = picked.map { phrase in
            if mode == .cloze {
                let options = ([phrase] + Cloze.distractors(for: phrase, in: all)).shuffled()
                return Question(phrase: phrase, options: options, kind: .cloze)
            }
            let kind: Kind = mode == .listening ? .listening : (Bool.random() ? .hanziToMeaning : .meaningToHanzi)
            func key(_ p: Phrase) -> String { kind == .meaningToHanzi ? p.hanzi : p.meaningVi }
            var seen: Set<String> = [key(phrase)]
            let candidates = pool.shuffled() + all.shuffled()
            let distractors = candidates.filter { other in
                other.id != phrase.id && seen.insert(key(other)).inserted
            }
            let options = ([phrase] + distractors.prefix(3)).shuffled()
            return Question(phrase: phrase, options: options, kind: kind)
        }
        index = 0
        chosen = nil
        correctCount = 0
        newlyLearned = 0
        started = true
    }
}
