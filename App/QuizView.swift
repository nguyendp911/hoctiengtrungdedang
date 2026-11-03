import SwiftUI

/// Ôn tập trắc nghiệm: nhìn chữ Hán chọn nghĩa, hoặc nhìn nghĩa chọn chữ Hán.
/// Đúng liên tiếp `ProgressStore.streakToLearn` lần thì từ được tính là đã thuộc.
struct QuizView: View {
    /// Từ của chủ đề đang chọn
    let pool: [Phrase]
    /// Toàn bộ từ, để lấy đáp án nhiễu khi chủ đề ít từ
    let all: [Phrase]
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correctCount = 0
    @State private var newlyLearned = 0

    static let length = 10

    struct Question {
        let phrase: Phrase
        let options: [Phrase]
        /// true: hỏi nghĩa của chữ Hán; false: hỏi chữ Hán của nghĩa
        let asksMeaning: Bool
    }

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    ProgressView()
                } else if index < questions.count {
                    questionView(questions[index])
                } else {
                    resultView
                }
            }
            .padding()
            .navigationTitle("Ôn tập")
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
            Text("Câu \(index + 1)/\(questions.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                if q.asksMeaning {
                    Text(q.phrase.hanzi)
                        .font(.system(size: 52, weight: .bold))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                    Text(q.phrase.pinyin).font(.title3).foregroundStyle(.red)
                    Text("nghĩa là gì?").foregroundStyle(.secondary)
                } else {
                    Text(q.phrase.meaningVi)
                        .font(.title.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text("tiếng Trung là gì?").foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 150)

            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { i, option in
                    Button {
                        answer(i, for: q)
                    } label: {
                        Text(q.asksMeaning ? option.meaningVi : option.hanzi)
                            .font(q.asksMeaning ? .body.weight(.medium) : .title2.weight(.semibold))
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
                    Button(index + 1 < questions.count ? "Câu tiếp" : "Xem kết quả") {
                        chosen = nil
                        index += 1
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: correctCount == questions.count ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Đúng \(correctCount)/\(questions.count)")
                .font(.largeTitle.bold())
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
        Speaker.shared.speak(q.phrase.hanzi)
        onChange()
    }

    private func start() {
        let learned = ProgressStore.learned
        // Từ chưa thuộc trước, thêm vài từ đã thuộc để ôn lại
        let fresh = pool.filter { !learned.contains($0.id) }.shuffled()
        let review = pool.filter { learned.contains($0.id) }.shuffled()
        let picked = Array((fresh + review).prefix(Self.length))

        questions = picked.map { phrase in
            let asksMeaning = Bool.random()
            var seen: Set<String> = [asksMeaning ? phrase.meaningVi : phrase.hanzi]
            let candidates = pool.shuffled() + all.shuffled()
            let distractors = candidates.filter { other in
                let key = asksMeaning ? other.meaningVi : other.hanzi
                return other.id != phrase.id && seen.insert(key).inserted
            }
            let options = ([phrase] + distractors.prefix(3)).shuffled()
            return Question(phrase: phrase, options: options, asksMeaning: asksMeaning)
        }
        index = 0
        chosen = nil
        correctCount = 0
        newlyLearned = 0
    }
}
