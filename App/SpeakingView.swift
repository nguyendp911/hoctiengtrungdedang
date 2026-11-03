import SwiftUI
import UIKit

/// Luyện nói: nghe mẫu, bấm micro đọc lại, app chấm độ giống nhau.
struct SpeakingView: View {
    let phrase: Phrase

    @Environment(\.dismiss) private var dismiss
    @StateObject private var checker = SpeechChecker()
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize: CGFloat = 48

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(phrase.hanzi)
                        .font(.system(size: hanziSize, weight: .bold))
                        .minimumScaleFactor(0.4)
                        .lineLimit(2)
                    Text(phrase.pinyin).font(.title3).foregroundStyle(.red)
                    Text(phrase.meaningVi).foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Button {
                    Speaker.shared.speak(phrase.hanzi)
                } label: {
                    Label("Nghe mẫu", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer(minLength: 0)

                resultArea
                    .frame(maxWidth: .infinity, minHeight: 130)

                micButton

                Text(checker.phase == .listening ? "Bấm lần nữa để dừng" : "Bấm micro rồi đọc to")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Luyện nói")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
        }
        .onDisappear { checker.reset() }
        .onChange(of: checker.phase) {
            if checker.phase == .finished { ProgressStore.markStudiedToday() }
        }
    }

    private var micButton: some View {
        let listening = checker.phase == .listening
        return Button {
            Speaker.shared.stop()
            checker.toggle()
        } label: {
            Image(systemName: listening ? "stop.fill" : "mic.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(listening ? Color.red : Color.accentColor, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(listening ? "Dừng" : "Bắt đầu nói")
    }

    @ViewBuilder
    private var resultArea: some View {
        switch checker.phase {
        case .idle:
            Text("Đọc to chữ trên, app sẽ nghe và chấm điểm.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .listening:
            VStack(spacing: 8) {
                Text("Đang nghe…").font(.headline)
                Text(checker.heard.isEmpty ? " " : checker.heard)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        case .processing:
            ProgressView("Đang chấm…")
        case .finished:
            resultCard
        case .denied:
            VStack(spacing: 10) {
                Text("App chưa được phép dùng micro hoặc nhận dạng giọng nói.")
                    .multilineTextAlignment(.center)
                Button("Mở Cài đặt iPhone") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        case .unavailable:
            Text("Máy chưa nhận dạng được giọng tiếng Trung. Kiểm tra kết nối mạng rồi thử lại.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var resultCard: some View {
        let score = SpeechScore.evaluate(heard: checker.heard, target: phrase.hanzi)
        let percent = Int((score * 100).rounded())
        let color: Color = score >= 0.9 ? .green : (score >= 0.6 ? .orange : .red)
        let message: String
        if checker.heard.isEmpty {
            message = "Không nghe thấy gì. Thử lại gần micro hơn nhé."
        } else if score >= 0.9 {
            message = "Tuyệt vời, bạn đọc rất chuẩn!"
        } else if score >= 0.6 {
            message = "Gần đúng rồi, nghe mẫu và thử lại nhé."
        } else {
            message = "Chưa đúng, nghe mẫu rồi thử lại nhé."
        }
        return VStack(spacing: 8) {
            Text("\(percent)%")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(color)
            Text(message).font(.headline).multilineTextAlignment(.center)
            if !checker.heard.isEmpty {
                Text("Máy nghe được: \(checker.heard)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
