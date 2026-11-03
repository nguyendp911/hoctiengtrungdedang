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
    /// Chủ đề, ví dụ "Giao tiếp"
    let topic: String

    init(id: Int, hanzi: String, pinyin: String, readingVi: String, meaningVi: String, topic: String) {
        self.id = id
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.readingVi = readingVi
        self.meaningVi = meaningVi
        self.topic = topic
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        hanzi = try c.decode(String.self, forKey: .hanzi)
        pinyin = try c.decode(String.self, forKey: .pinyin)
        readingVi = try c.decode(String.self, forKey: .readingVi)
        meaningVi = try c.decode(String.self, forKey: .meaningVi)
        // Từ không ghi chủ đề thì xếp vào "Khác"
        topic = try c.decodeIfPresent(String.self, forKey: .topic) ?? "Khác"
    }

    static let sample = Phrase(id: 0, hanzi: "你好", pinyin: "nǐ hǎo", readingVi: "nỉ hảo", meaningVi: "Xin chào", topic: "Giao tiếp")

    /// Link mở app từ widget: hanzilock://phrase/<id>
    var deepLink: URL { URL(string: "hanzilock://phrase/\(id)")! }
}

enum PhraseStore {
    /// Đổi câu mới sau mỗi khoảng thời gian này (giây)
    static let rotationInterval: TimeInterval = 60 * 60

    /// Danh sách từ trên GitHub. Sửa file này trên GitHub là app và widget
    /// tự lấy từ mới, không cần build hay cài lại.
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/nguyendp911/hoctiengtrungdedang/main/Shared/phrases.json")!

    /// Widget tự tải lại danh sách nếu bản đã lưu cũ hơn khoảng này
    static let staleAfter: TimeInterval = 6 * 60 * 60

    private static var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("phrases.json")
    }

    /// Bản đã tải về nếu có, không thì dùng bản đóng gói sẵn trong app
    static func load() -> [Phrase] {
        if let list = decode(try? Data(contentsOf: cacheURL)) { return list }
        if let url = Bundle.main.url(forResource: "phrases", withExtension: "json"),
           let list = decode(try? Data(contentsOf: url)) { return list }
        return [.sample]
    }

    private static func decode(_ data: Data?) -> [Phrase]? {
        guard let data,
              let list = try? JSONDecoder().decode([Phrase].self, from: data),
              !list.isEmpty
        else { return nil }
        return list
    }

    /// Tải danh sách mới từ GitHub và lưu lại. File lỗi thì giữ bản cũ.
    @discardableResult
    static func refresh() async throws -> [Phrase] {
        let request = URLRequest(url: remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200, let list = decode(data) else {
            throw URLError(.cannotParseResponse)
        }
        try data.write(to: cacheURL, options: .atomic)
        return list
    }

    static func refreshIfStale() async {
        let saved = try? cacheURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        if let saved, Date().timeIntervalSince(saved) < staleAfter { return }
        _ = try? await refresh()
    }

    /// Các chủ đề theo thứ tự xuất hiện trong file
    static func topics(in list: [Phrase]) -> [String] {
        var seen = Set<String>()
        return list.map(\.topic).filter { seen.insert($0).inserted }
    }

    /// `topic` = nil nghĩa là tất cả chủ đề
    static func phrases(in list: [Phrase], topic: String?) -> [Phrase] {
        guard let topic else { return list }
        let filtered = list.filter { $0.topic == topic }
        return filtered.isEmpty ? list : filtered
    }

    /// Câu hiển thị tại một thời điểm. Tính theo thời gian nên app và widget
    /// luôn ra cùng một câu mà không cần chia sẻ dữ liệu (App Group).
    /// Từ trong `learned` bị bỏ qua, trừ khi cả chủ đề đã thuộc hết.
    static func phrase(at date: Date, topic: String? = nil, in list: [Phrase], learned: Set<Int> = []) -> Phrase {
        let all = phrases(in: list, topic: topic)
        let unlearned = all.filter { !learned.contains($0.id) }
        let pool = unlearned.isEmpty ? all : unlearned
        let slot = Int(floor(date.timeIntervalSince1970 / rotationInterval))
        let count = pool.count
        return pool[((slot % count) + count) % count]
    }

    /// Thời điểm bắt đầu của khung giờ chứa `date`
    static func slotStart(for date: Date) -> Date {
        let slot = floor(date.timeIntervalSince1970 / rotationInterval)
        return Date(timeIntervalSince1970: slot * rotationInterval)
    }
}
