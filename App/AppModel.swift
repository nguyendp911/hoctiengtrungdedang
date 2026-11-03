import SwiftUI
import WidgetKit

/// Trạng thái dùng chung cho cả 3 tab
@MainActor
final class AppModel: ObservableObject {
    @Published var phrases = PhraseStore.load()
    @Published var learned = ProgressStore.learned
    @Published var favorites = ProgressStore.favorites
    /// Câu người dùng vừa chọn (chạm vào danh sách, widget); nil thì hiện câu của giờ hiện tại
    @Published var picked: Phrase?
    @Published var status: String?
    @Published var isUpdating = false

    var topics: [String] { PhraseStore.topics(in: phrases) }

    var dueCount: Int {
        let snap = ProgressStore.snapshot()
        return phrases.filter { snap.state(of: $0.id) == .due }.count
    }

    var newCount: Int {
        let snap = ProgressStore.snapshot()
        return phrases.filter { snap.state(of: $0.id) == .new && !learned.contains($0.id) }.count
    }

    func reloadProgress() {
        learned = ProgressStore.learned
        WidgetCenter.shared.reloadAllTimelines()
    }

    func toggleFavorite(_ phrase: Phrase) {
        ProgressStore.toggleFavorite(phrase.id)
        favorites = ProgressStore.favorites
    }

    func toggleLearned(_ phrase: Phrase) {
        ProgressStore.setLearned(phrase.id, !learned.contains(phrase.id))
        reloadProgress()
    }

    func update(silent: Bool = false) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            let before = Set(phrases.map(\.id))
            phrases = try await PhraseStore.refresh()
            let added = phrases.filter { !before.contains($0.id) }.count
            WidgetCenter.shared.reloadAllTimelines()
            if !silent || added > 0 {
                status = added > 0 ? "Đã thêm \(added) từ mới." : "Đã có bản mới nhất (\(phrases.count) từ)."
            }
        } catch {
            if !silent { status = "Không tải được từ mới. Kiểm tra mạng rồi thử lại." }
        }
    }
}
