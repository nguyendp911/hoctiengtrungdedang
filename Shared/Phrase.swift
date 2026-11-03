import Foundation

struct Phrase: Codable, Identifiable, Hashable {
    let id: Int
    /// Chữ Hán, ví dụ "你好"
    let hanzi: String
    /// Pinyin có dấu thanh, ví dụ "nǐ hǎo"
    let pinyin: String
    /// Cách đọc phiên âm bằng tiếng Việt, ví dụ "nỉ hảo"
    let readingVi: String
    /// Nghĩa tiếng Việt
    let meaningVi: String

    static let sample = Phrase(id: 0, hanzi: "你好", pinyin: "nǐ hǎo", readingVi: "nỉ hảo", meaningVi: "Xin chào")

    /// Link mở app từ widget: hanzilock://phrase/<id>
    var deepLink: URL { URL(string: "hanzilock://phrase/\(id)")! }
}

enum PhraseStore {
    /// Đổi câu mới sau mỗi khoảng thời gian này (giây)
    static let rotationInterval: TimeInterval = 60 * 60

    static let all: [Phrase] = {
        guard let url = Bundle.main.url(forResource: "phrases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Phrase].self, from: data),
              !list.isEmpty
        else { return [Phrase.sample] }
        return list
    }()

    /// Câu hiển thị tại một thời điểm. Tính theo thời gian nên app và widget
    /// luôn ra cùng một câu mà không cần chia sẻ dữ liệu (App Group).
    static func phrase(at date: Date) -> Phrase {
        let slot = Int(floor(date.timeIntervalSince1970 / rotationInterval))
        let count = all.count
        return all[((slot % count) + count) % count]
    }

    static func phrase(id: Int) -> Phrase? {
        all.first { $0.id == id }
    }

    /// Thời điểm bắt đầu của khung giờ chứa `date`
    static func slotStart(for date: Date) -> Date {
        let slot = floor(date.timeIntervalSince1970 / rotationInterval)
        return Date(timeIntervalSince1970: slot * rotationInterval)
    }
}
