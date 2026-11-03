import SwiftUI

/// Thanh điệu 1-4 của một âm tiết pinyin; nil nếu là thanh nhẹ hoặc không có dấu.
enum Tone {
    static func of(_ pinyin: String) -> Int? {
        for scalar in pinyin.decomposedStringWithCanonicalMapping.unicodeScalars {
            switch scalar.value {
            case 0x0304: return 1   // ā
            case 0x0301: return 2   // á
            case 0x030C: return 3   // ǎ
            case 0x0300: return 4   // à
            default: continue
            }
        }
        return nil
    }

    /// Mức cao độ 1 (thấp) đến 5 (cao) của từng thanh, theo cách ghi chuẩn 55, 35, 214, 51
    static func contour(_ tone: Int) -> [Double] {
        switch tone {
        case 1: return [5, 5]
        case 2: return [3, 5]
        case 3: return [2, 1, 4]
        default: return [5, 1]
        }
    }

    static func hint(_ tone: Int) -> String {
        switch tone {
        case 1: return "Cao và đều, kéo dài"
        case 2: return "Đi lên, như dấu sắc"
        case 3: return "Xuống thấp rồi lên, như dấu hỏi"
        default: return "Rơi nhanh từ cao xuống, như ra lệnh"
        }
    }
}

/// Đường đi của cao độ, vẽ bằng một nét
struct ToneContour: View {
    let tone: Int
    var color: Color = .accentColor

    var body: some View {
        GeometryReader { geo in
            let levels = Tone.contour(tone)
            let points = levels.enumerated().map { i, level in
                CGPoint(x: geo.size.width * (0.12 + 0.76 * Double(i) / Double(levels.count - 1)),
                        y: geo.size.height * (0.88 - 0.76 * (level - 1) / 4))
            }
            ZStack {
                Path { path in
                    path.move(to: points[0])
                    for p in points.dropFirst() { path.addLine(to: p) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                if let end = points.last {
                    Circle().fill(color).frame(width: 9, height: 9).position(end)
                }
            }
        }
    }
}

/// Luyện thanh điệu: học 4 thanh, rồi nghe một chữ và chọn thanh đúng.
struct ToneDrillView: View {
    /// Các từ một chữ, có thanh điệu rõ ràng
    let pool: [Phrase]
    var onChange: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Phrase] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correct = 0
    @State private var showGuide = true

    static let length = 10

    static func candidates(from phrases: [Phrase]) -> [Phrase] {
        phrases.filter { phrase in
            phrase.hanzi.count == 1 && Tone.of(phrase.pinyin) != nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if showGuide {
                    guideView
                } else if questions.isEmpty {
                    Text("Chưa đủ từ một chữ để luyện thanh điệu.")
                        .foregroundStyle(.secondary)
                } else if index < questions.count {
                    questionView(questions[index])
                } else {
                    resultView
                }
            }
            .padding()
            .navigationTitle("Luyện thanh điệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !showGuide {
                        Button("Bốn thanh") { showGuide = true }
                    }
                }
            }
        }
    }

    // MARK: Hướng dẫn 4 thanh

    private var guideView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Tiếng Trung có 4 thanh. Cùng một âm, đổi thanh là đổi nghĩa.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ForEach(1...4, id: \.self) { tone in
                    HStack(spacing: 14) {
                        ToneContour(tone: tone)
                            .frame(width: 70, height: 56)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Thanh \(tone)").font(.headline)
                            Text(Tone.hint(tone)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityElement(children: .combine)
                }

                Button {
                    start()
                } label: {
                    Label("Bắt đầu luyện", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
    }

    // MARK: Câu hỏi

    private func questionView(_ phrase: Phrase) -> some View {
        let answer = Tone.of(phrase.pinyin) ?? 1
        return VStack(spacing: 18) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .accessibilityLabel("Câu \(index + 1) trên \(questions.count)")
            Text("Câu \(index + 1)/\(questions.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Button {
                    Speaker.shared.speak(phrase.hanzi)
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                        .frame(width: 84, height: 84)
                        .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nghe lại")
                Text(chosen == nil ? "Nghe và chọn thanh điệu" : "\(phrase.hanzi) · \(phrase.pinyin) · \(phrase.meaningVi)")
                    .font(chosen == nil ? .body : .headline)
                    .foregroundStyle(chosen == nil ? .secondary : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 140)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(1...4, id: \.self) { tone in
                    Button {
                        guard chosen == nil else { return }
                        chosen = tone
                        if tone == answer { correct += 1 }
                        ProgressStore.markStudiedToday()
                        onChange()
                    } label: {
                        VStack(spacing: 4) {
                            ToneContour(tone: tone, color: color(for: tone, answer: answer))
                                .frame(height: 44)
                            Text("Thanh \(tone)").font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(color(for: tone, answer: answer).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(color(for: tone, answer: answer))
                    }
                    .buttonStyle(.plain)
                }
            }

            if chosen != nil {
                Button(index + 1 < questions.count ? "Câu tiếp" : "Xem kết quả") {
                    chosen = nil
                    index += 1
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer(minLength: 0)
        }
        .task(id: index) {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if chosen == nil { Speaker.shared.speak(phrase.hanzi) }
        }
    }

    private func color(for tone: Int, answer: Int) -> Color {
        guard let chosen else { return .accentColor }
        if tone == answer { return .green }
        return tone == chosen ? .red : .gray
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ear.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Đúng \(correct)/\(questions.count)")
                .font(.largeTitle.bold())
            Text(correct >= questions.count - 1 ? "Tai bạn bắt thanh điệu rất tốt!" : "Nghe thêm vài lượt nữa, thanh 2 và thanh 3 hay bị nhầm nhất.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

    private func start() {
        questions = Array(Self.candidates(from: pool).shuffled().prefix(Self.length))
        index = 0
        chosen = nil
        correct = 0
        showGuide = false
    }
}
