import Foundation

/// Tiến độ học: từ nào đã thuộc, trả lời đúng liên tiếp bao nhiêu lần.
/// Lưu trong App Group để widget biết mà ưu tiên từ chưa thuộc. Nếu App Group
/// không có (ký lại làm mất quyền), app vẫn chạy, chỉ là widget không thấy tiến độ.
enum ProgressStore {
    static let groupID = "group.com.nguyendp.hanzilock"
    /// Trả lời đúng liên tiếp bấy nhiêu lần thì tính là đã thuộc
    static let streakToLearn = 3

    private static let learnedKey = "learnedIDs"
    private static let streakKey = "streaks"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    static var learned: Set<Int> {
        Set(defaults.array(forKey: learnedKey) as? [Int] ?? [])
    }

    static func setLearned(_ id: Int, _ isLearned: Bool) {
        var ids = learned
        if isLearned { ids.insert(id) } else { ids.remove(id) }
        defaults.set(Array(ids), forKey: learnedKey)
        if !isLearned { setStreak(id, 0) }
    }

    /// Ghi kết quả một câu ôn tập. Trả về true nếu từ vừa được tính là đã thuộc.
    @discardableResult
    static func record(_ id: Int, correct: Bool) -> Bool {
        guard correct else {
            setLearned(id, false)
            return false
        }
        let streak = (streaks[String(id)] ?? 0) + 1
        setStreak(id, streak)
        if streak >= streakToLearn && !learned.contains(id) {
            setLearned(id, true)
            return true
        }
        return false
    }

    private static var streaks: [String: Int] {
        defaults.dictionary(forKey: streakKey) as? [String: Int] ?? [:]
    }

    private static func setStreak(_ id: Int, _ value: Int) {
        var all = streaks
        all[String(id)] = value
        defaults.set(all, forKey: streakKey)
    }
}
