import Foundation

/// Tiến độ học: từ nào đã thuộc, lịch ôn tập, chuỗi ngày học.
/// Lưu trong App Group để widget biết mà ưu tiên từ chưa thuộc. Nếu App Group
/// không có (ký lại làm mất quyền), app vẫn chạy, chỉ là widget không thấy tiến độ.
enum ProgressStore {
    static let groupID = "group.com.nguyendp.hanzilock"
    /// Trả lời đúng liên tiếp bấy nhiêu lần thì tính là đã thuộc
    static let streakToLearn = 3
    /// Số ngày đến lần ôn tiếp theo, theo số lần đúng liên tiếp (0, 1, 2, ...)
    static let intervals: [Double] = [0, 1, 2, 4, 7, 15, 30, 60]

    enum State { case new, due, later }

    private static let learnedKey = "learnedIDs"
    private static let streakKey = "streaks"
    private static let dueKey = "dueDates"
    private static let daysKey = "studyDays"
    private static let countsKey = "dayCounts"
    private static let newCountsKey = "dayNewCounts"
    private static let favoritesKey = "favoriteIDs"
    private static let easeKey = "eases"
    private static let intervalKey = "intervalDays"

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
            setInterval(id, intervals[streakToLearn])
            setDue(id, Date().addingTimeInterval(intervals[streakToLearn] * 86400))
        } else {
            ids.remove(id)
            setStreak(id, 0)
            setInterval(id, 0)
            setDue(id, Date())
        }
        defaults.set(Array(ids), forKey: learnedKey)
    }

    /// Mức tự đánh giá khi ôn (kiểu SM-2): quyết định khoảng cách đến lần ôn sau
    enum Grade { case again, hard, good, easy }

    static let defaultEase = 2.5
    static let minEase = 1.3
    static let maxIntervalDays = 180.0

    /// Ghi kết quả đúng/sai (câu trắc nghiệm): đúng = Tốt, sai = Học lại
    @discardableResult
    static func record(_ id: Int, correct: Bool) -> Bool {
        record(id, grade: correct ? .good : .again)
    }

    /// Ghi kết quả một lần ôn. Trả về true nếu từ vừa được tính là đã thuộc.
    @discardableResult
    static func record(_ id: Int, grade: Grade) -> Bool {
        markStudiedToday()
        incrementCount()
        if state(of: id) == .new { incrementNewWords() }

        let key = String(id)
        let oldStreak = streaks[key] ?? 0
        let ease = eases[key] ?? defaultEase
        // Từ cũ chưa có khoảng ôn riêng: suy ra từ bảng `intervals` theo số lần đúng
        let previous = intervalDays[key] ?? intervals[min(oldStreak, intervals.count - 1)]

        if grade == .again {
            // Sai thì lùi 2 bậc (không về 0), hỏi lại ngay, giảm hệ số dễ;
            // dưới ngưỡng thì không còn tính là đã thuộc
            let lowered = max(0, oldStreak - 2)
            setStreak(id, lowered)
            setEase(id, max(minEase, ease - 0.2))
            setInterval(id, 0)
            setDue(id, Date())
            if lowered < streakToLearn {
                var ids = learned
                if ids.remove(id) != nil { defaults.set(Array(ids), forKey: learnedKey) }
            }
            return false
        }

        let streak = oldStreak + 1
        var newEase = ease
        var days = 1.0
        switch grade {
        case .hard:
            newEase = max(minEase, ease - 0.15)
            days = streak <= 1 ? 1 : previous * 1.2
        case .good:
            days = streak <= 1 ? 1 : (streak == 2 ? 3 : previous * ease)
        case .easy:
            newEase = ease + 0.15
            days = streak <= 1 ? 3 : (streak == 2 ? 6 : previous * ease * 1.3)
        case .again:
            break // đã xử lý ở trên
        }
        days = min(maxIntervalDays, max(1, days))

        setStreak(id, streak)
        setEase(id, newEase)
        setInterval(id, days)
        setDue(id, Date().addingTimeInterval(days * 86400))
        if streak >= streakToLearn && !learned.contains(id) {
            var ids = learned
            ids.insert(id)
            defaults.set(Array(ids), forKey: learnedKey)
            return true
        }
        return false
    }

    // MARK: Lịch ôn

    /// Ảnh chụp lịch ôn tại một thời điểm. Đọc một lần rồi tra nhiều lần, nhanh hơn
    /// nhiều so với gọi `state(of:)` cho từng từ khi danh sách có hàng nghìn từ.
    struct Snapshot {
        private let dueDates: [String: Double]
        private let now = Date().timeIntervalSince1970

        fileprivate init(dueDates: [String: Double]) {
            self.dueDates = dueDates
        }

        func state(of id: Int) -> State {
            guard let due = dueDates[String(id)] else { return .new }
            return due <= now ? .due : .later
        }
    }

    static func snapshot() -> Snapshot {
        Snapshot(dueDates: dueDates)
    }

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

    private static var eases: [String: Double] {
        defaults.dictionary(forKey: easeKey) as? [String: Double] ?? [:]
    }

    private static var intervalDays: [String: Double] {
        defaults.dictionary(forKey: intervalKey) as? [String: Double] ?? [:]
    }

    private static func setEase(_ id: Int, _ value: Double) {
        var all = eases
        all[String(id)] = value
        defaults.set(all, forKey: easeKey)
    }

    private static func setInterval(_ id: Int, _ value: Double) {
        var all = intervalDays
        all[String(id)] = value
        defaults.set(all, forKey: intervalKey)
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

    // MARK: Từ mới mỗi ngày (cho kế hoạch học)

    private static var newCounts: [String: Int] {
        defaults.dictionary(forKey: newCountsKey) as? [String: Int] ?? [:]
    }

    /// Gọi trước khi ghi lịch ôn: từ chưa từng học thì tính là một từ mới của hôm nay
    private static func incrementNewWords() {
        var all = newCounts
        all[dayString(Date()), default: 0] += 1
        defaults.set(all, forKey: newCountsKey)
    }

    static func newWords(on date: Date) -> Int {
        newCounts[dayString(date)] ?? 0
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

    private static let allKeys = [learnedKey, streakKey, dueKey, daysKey, countsKey, newCountsKey, favoritesKey, easeKey, intervalKey]

    static func resetAll() {
        for key in allKeys { defaults.removeObject(forKey: key) }
    }

    // MARK: Sao lưu / khôi phục

    /// Toàn bộ tiến độ dưới dạng JSON, để lưu vào Tệp/iCloud Drive rồi khôi phục trên máy khác
    static func exportBackup() -> Data? {
        var payload: [String: Any] = [:]
        for key in allKeys {
            if let value = defaults.object(forKey: key) { payload[key] = value }
        }
        let wrapper: [String: Any] = ["version": 1, "exportedAt": Date().timeIntervalSince1970, "data": payload]
        return try? JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys])
    }

    /// Khôi phục từ file sao lưu (ghi đè tiến độ hiện tại). Trả về false nếu file không hợp lệ.
    @discardableResult
    static func importBackup(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              root["version"] as? Int == 1,
              let payload = root["data"] as? [String: Any]
        else { return false }
        for key in allKeys {
            if let value = payload[key] { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        return true
    }
}
