import Foundation

/// Một bài học trong cấp HSK
struct HSKUnit: Identifiable {
    let no: Int
    let name: String
    let words: [Phrase]
    var id: Int { no }
}

/// Lộ trình HSK: cấp độ, bài học và số từ chính thức để so sánh
enum Curriculum {
    static let levels = [1, 2, 3]

    /// Số từ mới của từng cấp theo chuẩn HSK 2.0 (cộng dồn: 150, 300, 600)
    static let officialNewWords = [1: 150, 2: 150, 3: 300]

    /// Từ của một cấp, xếp theo bài rồi theo thứ tự trong file
    static func words(level: Int, in phrases: [Phrase]) -> [Phrase] {
        phrases.enumerated()
            .filter { $0.element.hskLevel == level }
            .sorted { a, b in
                (a.element.unitNo ?? Int.max, a.offset) < (b.element.unitNo ?? Int.max, b.offset)
            }
            .map { $0.element }
    }

    static func units(level: Int, in phrases: [Phrase]) -> [HSKUnit] {
        let ordered = words(level: level, in: phrases)
        var order: [Int] = []
        var groups: [Int: [Phrase]] = [:]
        var names: [Int: String] = [:]
        for word in ordered {
            let no = word.unitNo ?? 0
            if groups[no] == nil { order.append(no) }
            groups[no, default: []].append(word)
            if names[no] == nil { names[no] = word.unit ?? "Khác" }
        }
        return order.map { HSKUnit(no: $0, name: names[$0] ?? "Khác", words: groups[$0] ?? []) }
    }
}
