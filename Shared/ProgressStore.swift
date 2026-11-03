import Foundation

/// Tiến độ học: từ nào đã thuộc, lịch ôn tập, chuỗi ngày học.
/// Lưu trong App Group để widget biết mà ưu tiên từ chưa thuộc. Nếu App Group
/// không có (ký lại làm mất quyền), app vẫn chạy, chỉ là widget không thấy tiến độ.
enum ProgressStore {
    static let groupID = "group.com.nguyendp.hanzilock"
    /// Trả lời đúng liên tiếp bấy nhiêu lần thì tính là đã thuộc
    static let streakToLearn = 3
    /// Số ngày đến lần ôn tiếp theo, theo số lần đúng liên tiếp (0, 1, 2, ...)
    static let intervals: [Double] = [0, 1, 2, 4, 7, 15]

    enum State { case new, due, later }

    private static let learnedKey = "learnedIDs"
    private static let streakKey = "streaks"
    private static let dueKey = "dueDates"
    private static let daysKey = "studyDays"
    private static let countsKey = "dayCounts"
    private static let favoritesKey = "favoriteIDs"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    // MARK: Đã thuộc

    static var learned: Set<Int> {
        Set(defaults.array(forKey: learnedKey) as? [Int] ?? [])
    }

    static func setLearned(_ id: Int, _ isLearned: Bool) {
        var ids = learned
        if isLearned {
            ids.insert(id)
            setStreak(id, streakToLearn)
            setDue(id, Date().addingTimeInterval(intervals[streakToLearn] * 86400))
        } else {
            ids.remove(id)
            setStreak(id, 0)
            setDue(id, Date())
        }
        defaults.set(Array(ids), forKey: learnedKey)
    }

    /// Ghi kết quả một câu ôn tập. Trả về true nếu từ vừa được tính là đã thuộc.
    @discardableResult
    static func record(_ id: Int, correct: Bool) -> Bool {
        markStudiedToday()
        incrementCount()
        guard correct else {
            setLearned(id, false)
            return false
        }
        let streak = (streaks[String(id)] ?? 0) + 1
        setStreak(id, streak)
        setDue(id, Date().addingTimeInterval(intervals[min(streak, intervals.count - 1)] * 86400))
        if streak >= streakToLearn && !learned.contains(id) {
            var ids = learned
            ids.insert(id)
            defaults.set(Array(ids), forKey: learnedKey)
            return true
        }
        return false
    }

    // MARK: Lịch ôn

    static func state(of id: Int, now: Date = Date()) -> State {
        guard let due = dueDates[String(id)] else { return .new }
        return due <= now.timeIntervalSince1970 ? .due : .later
    }

    private static var streaks: [String: Int] {
        defaults.dictionary(forKey: streakKey) as? [String: Int] ?? [:]
    }

    private static var dueDates: [String: Double] {
        defaults.dictionary(forKey: dueKey) as? [String: Double] ?? [:]
    }

    private static func setStreak(_ id: Int, _ value: Int) {
        var all = streaks
        all[String(id)] = value
        defaults.set(all, forKey: streakKey)
    }

    private static func setDue(_ id: Int, _ date: Date) {
        var all = dueDates
        all[String(id)] = date.timeIntervalSince1970
        defaults.set(all, forKey: dueKey)
    }

    // MARK: Chuỗi ngày học

    private static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private static var studyDays: Set<String> {
        Set(defaults.stringArray(forKey: daysKey) ?? [])
    }

    static func markStudiedToday() {
        var days = studyDays
        days.insert(dayString(Date()))
        defaults.set(Array(days), forKey: daysKey)
    }

    static func didStudy(on date: Date) -> Bool {
        studyDays.contains(dayString(date))
    }

    static var studiedToday: Bool { didStudy(on: Date()) }

    /// Số ngày học liên tiếp tính đến hôm nay (hôm nay chưa học thì tính đến hôm qua)
    static var currentStreak: Int {
        let days = studyDays
        let cal = Calendar.current
        var date = Date()
        if !days.contains(dayString(date)) {
            date = cal.date(byAdding: .day, value: -1, to: date) ?? date
        }
        var count = 0
        while days.contains(dayString(date)) {
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return count
    }

    // MARK: Số câu trả lời mỗi ngày (cho mục tiêu và biểu đồ)

    private static var dayCounts: [String: Int] {
        defaults.dictionary(forKey: countsKey) as? [String: Int] ?? [:]
    }

    private static func incrementCount() {
        var all = dayCounts
        let key = dayString(Date())
        all[key, default: 0] += 1
        defaults.set(all, forKey: countsKey)
    }

    static func count(on date: Date) -> Int {
        dayCounts[dayString(date)] ?? 0
    }

    // MARK: Yêu thích

    static var favorites: Set<Int> {
        Set(defaults.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    static func toggleFavorite(_ id: Int) {
        var ids = favorites
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        defaults.set(Array(ids), forKey: favoritesKey)
    }

    static func resetAll() {
        for key in [learnedKey, streakKey, dueKey, daysKey, countsKey] {
            defaults.removeObject(forKey: key)
        }
    }
}
