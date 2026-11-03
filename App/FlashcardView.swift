import SwiftUI

/// Thẻ lật: vuốt phải = đã nhớ, vuốt trái = học lại, chạm vào thẻ để lật.
struct FlashcardView: View {
    let pool: [Phrase]
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var deck: [Phrase] = []
    @State private var index = 0
    @State private var flipped = false
    @State private var offset: CGFloat = 0
    @State private var remembered = 0
    @State private var again = 0
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize: CGFloat = 60

    static let length = 15

    var body: some View {
        NavigationStack {
            Group {
                if deck.isEmpty {
                    ProgressView()
                } else if index < deck.count {
                    cardScreen(deck[index])
                } else {
                    resultView
                }
            }
            .padding()
            .navigationTitle("Thẻ lật")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .onAppear { if deck.isEmpty { start() } }
    }

    private func cardScreen(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(deck.count))
                .accessibilityLabel("Thẻ \(index + 1) trên \(deck.count)")
            Text("Thẻ \(index + 1)/\(deck.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(offset > 40 ? Color.green : (offset < -40 ? Color.red : Color.clear), lineWidth: 3)
                    )
                cardFace(phrase)
                    .padding(20)
            }
            .frame(maxHeight: 420)
            .offset(x: offset)
            .rotationEffect(.degrees(Double(offset) / 20))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { flipped.toggle() }
                if flipped { Speaker.shared.speak(phrase.hanzi) }
            }
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation.width }
                    .onEnded { value in
                        if value.translation.width > 110 {
                            finish(phrase, correct: true)
                        } else if value.translation.width < -110 {
                            finish(phrase, correct: false)
                        } else {
                            withAnimation(.spring()) { offset = 0 }
                        }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Chạm hai lần để lật thẻ")

            Text(flipped ? "Bạn nhớ từ này chưa?" : "Chạm vào thẻ để xem đáp án")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                actionButton("Học lại", icon: "arrow.counterclockwise", color: .red) {
                    finish(phrase, correct: false)
                }
                actionButton("Nghe", icon: "speaker.wave.2.fill", color: .accentColor) {
                    Speaker.shared.speak(phrase.hanzi)
                }
                actionButton("Đã nhớ", icon: "checkmark", color: .green) {
                    finish(phrase, correct: true)
                }
            }
        }
    }

    @ViewBuilder
    private func cardFace(_ phrase: Phrase) -> some View {
        if flipped {
            VStack(spacing: 10) {
                Text(phrase.hanzi)
                    .font(.system(size: hanziSize * 0.6, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                Text(phrase.pinyin).font(.title2).foregroundStyle(.red)
                Text("Đọc: \(phrase.readingVi)").font(.headline).foregroundStyle(.secondary)
                if let hanViet = phrase.hanViet {
                    Text("Hán Việt: \(hanViet)").font(.subheadline).foregroundStyle(.secondary)
                }
                Text(phrase.meaningVi)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let example = phrase.example {
                    Text(example.zh).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
        } else {
            Text(phrase.hanzi)
                .font(.system(size: hanziSize, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(color)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.fill.badge.person.crop")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Hoàn thành \(deck.count) thẻ")
                .font(.title.bold())
            Text("Đã nhớ \(remembered) · Cần học lại \(again)")
                .foregroundStyle(.secondary)
            HStack {
                Button("Chơi tiếp") { start() }
                    .buttonStyle(.borderedProminent)
                Button("Xong") { dismiss() }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 40)
    }

    private func finish(_ phrase: Phrase, correct: Bool) {
        ProgressStore.record(phrase.id, correct: correct)
        if correct { remembered += 1 } else { again += 1 }
        onChange()
        withAnimation(.easeIn(duration: 0.18)) { offset = correct ? 500 : -500 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            flipped = false
            offset = 0
            index += 1
        }
    }

    private func start() {
        let learned = ProgressStore.learned
        let due = pool.filter { ProgressStore.state(of: $0.id) == .due }.shuffled()
        let new = pool.filter { ProgressStore.state(of: $0.id) == .new && !learned.contains($0.id) }.shuffled()
        let later = pool.filter { !due.contains($0) && !new.contains($0) }.shuffled()
        deck = Array((due + new + later).prefix(Self.length))
        index = 0
        flipped = false
        offset = 0
        remembered = 0
        again = 0
    }
}
