import AppIntents

/// Nút loa trên widget: đọc to từ mà không cần mở app.
/// `AudioPlaybackIntent` chạy trong app (ở chế độ nền) nên phát được âm thanh.
struct SpeakPhraseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Phát âm"

    @Parameter(title: "Mã từ")
    var phraseID: Int

    init() {}

    init(phraseID: Int) {
        self.phraseID = phraseID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let phrase = PhraseStore.loadForWidget().first(where: { $0.id == phraseID }) {
            Speaker.shared.speak(phrase.hanzi)
        }
        return .result()
    }
}
