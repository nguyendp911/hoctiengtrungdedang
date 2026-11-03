import UserNotifications

/// Nhắc học mỗi ngày bằng thông báo, mỗi ngày một từ khác nhau.
/// iOS chỉ cho lên lịch trước nội dung cố định, nên app đặt sẵn 14 ngày
/// và đặt lại mỗi lần mở app.
enum Reminder {
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func schedule(minutes: Int, phrases: [Phrase]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !phrases.isEmpty else { return }

        let learned = ProgressStore.learned
        var pool = phrases.filter { !learned.contains($0.id) }
        if pool.isEmpty { pool = phrases }
        pool.shuffle()

        let cal = Calendar.current
        for day in 0..<14 {
            // Hôm nay đã học rồi thì không nhắc nữa
            if day == 0 && ProgressStore.studiedToday { continue }
            guard let base = cal.date(byAdding: .day, value: day, to: Date()) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: base)
            comps.hour = minutes / 60
            comps.minute = minutes % 60
            guard let fire = cal.date(from: comps), fire > Date() else { continue }

            let phrase = pool[day % pool.count]
            let content = UNMutableNotificationContent()
            content.title = "\(phrase.hanzi) · \(phrase.pinyin)"
            content.body = "\(phrase.meaningVi) — đọc: \(phrase.readingVi)"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "daily-\(day)", content: content, trigger: trigger))
        }
    }
}
