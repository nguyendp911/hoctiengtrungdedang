import SwiftUI

/// Gõ pinyin: nhìn chữ Hán và nghĩa, tự gõ cách đọc. Đúng cả âm và thanh điệu mới tính là đúng;
/// đúng âm nhưng sai thanh vẫn được báo riêng để biết lỗi nằm ở đâu.
struct PinyinTypingView: View {
    let pool: [Phrase]
    var length = 10
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Phrase] = []
    @State private var index = 0
    @State private var text = ""
    @State private var result: PinyinInput.Result?
    @State private var correctCount = 0
    @State private var toneMistakes = 0
    @State private var started = false
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize: CGFloat = 52

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    if started {
                        ContentUnavailableView("Chưa có từ để luyện", systemImage: "keyboard",
                                               description: Text("Không có từ nào phù hợp trong nhóm này."))
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
            .navigationTitle("Gõ pinyin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .onAppear { if questions.isEmpty { start() } }
    }

    private func questionView(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .accessibilityLabel("Câu \(index + 1) trên \(questions.count)")
            Text("Câu \(index + 1)/\(questions.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(phrase.hanzi)
                    .font(.system(size: hanziSize, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(phrase.meaningVi)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 130)

            TextField("Gõ pinyin, ví dụ ni3 hao3 hoặc nǐ hǎo", text: $text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .focused($focused)
                .disabled(result != nil)
                .onSubmit { check(phrase) }
                .accessibilityLabel("Pinyin")

            if let result {
                feedback(result, phrase: phrase)
                Button(index + 1 < questions.count ? "Câu tiếp" : "Xem kết quả") {
                    next()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Kiểm tra") { check(phrase) }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                Text("Gõ số thanh sau mỗi âm tiết (1 đến 4, thanh nhẹ không cần số). Dùng v cho ü: nv3 = nǚ.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)
        }
        .onAppear { focused = true }
    }

    private func feedback(_ result: PinyinInput.Result, phrase: Phrase) -> some View {
        VStack(spacing: 6) {
            switch result {
            case .correct:
                Label("Chính xác", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            case .wrongTone:
                Label("Đúng âm nhưng sai thanh điệu", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            case .wrong:
                Label("Chưa đúng", systemImage: "xmark.circle.fill").foregroundStyle(.red)
            }
            Text(phrase.pinyin).font(.title3.weight(.semibold)).foregroundStyle(.red)
            Text("Đọc: \(phrase.readingVi)").font(.footnote).foregroundStyle(.secondary)
            Button {
                Speaker.shared.speak(phrase.hanzi)
            } label: {
                Label("Nghe lại", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
        }
        .font(.headline)
        .accessibilityElement(children: .contain)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: correctCount == questions.count ? "star.circle.fill" : "keyboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Đúng \(correctCount)/\(questions.count)")
                .font(.largeTitle.bold())
            if toneMistakes > 0 {
                Text("\(toneMistakes) câu đúng âm nhưng sai thanh điệu. Thử Luyện thanh điệu để phân biệt tốt hơn.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack {
                Button("Luyện tiếp") { start() }
                    .buttonStyle(.borderedProminent)
                Button("Xong") { dismiss() }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 40)
    }

    private func check(_ phrase: Phrase) {
        guard result == nil,
              !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let graded = PinyinInput.grade(text, expected: phrase.pinyin)
        result = graded
        if graded == .correct { correctCount += 1 }
        if graded == .wrongTone { toneMistakes += 1 }
        ProgressStore.record(phrase.id, correct: graded == .correct)
        Speaker.shared.speak(phrase.hanzi)
        onChange()
    }

    private func next() {
        index += 1
        text = ""
        result = nil
        focused = true
    }

    private func start() {
        let learned = ProgressStore.learned
        let snap = ProgressStore.snapshot()
        // Chỉ dùng từ toàn chữ Hán và có pinyin
        let source = pool.filter { phrase in
            !phrase.pinyin.isEmpty && phrase.hanzi.allSatisfy { ("\u{4e00}"..."\u{9fff}").contains($0) }
        }
        let due = source.filter { snap.state(of: $0.id) == .due }.shuffled()
        let new = source.filter { snap.state(of: $0.id) == .new && !learned.contains($0.id) }.shuffled()
        let dueOrNew = Set((due + new).map(\.id))
        let later = source.filter { !dueOrNew.contains($0.id) }.shuffled()
        questions = Array((due + new + later).prefix(length))
        index = 0
        text = ""
        result = nil
        correctCount = 0
        toneMistakes = 0
        started = true
    }
}
