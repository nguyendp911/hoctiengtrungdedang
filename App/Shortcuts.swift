import AppIntents

/// "Từ hôm nay": đọc to từ đang hiện trên widget. Dùng được trong ứng dụng Phím tắt và với Siri.
struct TodayPhraseIntent: AppIntent {
    static var title: LocalizedStringResource = "Từ hôm nay"
    static var description = IntentDescription("Đọc to từ tiếng Trung đang hiện trên widget.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let phrase = PhraseStore.phrase(at: Date(), in: PhraseStore.load(), learned: ProgressStore.learned)
        Speaker.shared.speak(phrase.hanzi)
        return .result(dialog: IntentDialog("\(phrase.hanzi) (\(phrase.pinyin)): \(phrase.meaningVi)"))
    }
}

struct HanziShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TodayPhraseIntent(),
            phrases: [
                "Từ hôm nay trong \(.applicationName)",
                "Đọc từ hôm nay \(.applicationName)",
            ],
            shortTitle: "Từ hôm nay",
            systemImageName: "character.book.closed"
        )
    }
}
