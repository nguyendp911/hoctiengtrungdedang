import AppIntents
import WidgetKit

/// Nút "Đã thuộc" ngay trên widget màn hình chính: đánh dấu rồi widget chuyển sang từ khác.
struct MarkLearnedIntent: AppIntent {
    static var title: LocalizedStringResource = "Đánh dấu đã thuộc"

    @Parameter(title: "Mã từ")
    var phraseID: Int

    init() {}

    init(phraseID: Int) {
        self.phraseID = phraseID
    }

    func perform() async throws -> some IntentResult {
        ProgressStore.setLearned(phraseID, true)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
