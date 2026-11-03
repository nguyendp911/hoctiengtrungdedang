import Foundation

/// Một bài học trong cấp HSK
struct HSKUnit: Identifiable {
    let no: Int
    let name: String
    let words: [Phrase]
    var id: Int { no }
}

/// Lộ trình HSK theo chuẩn HSK 3.0: cấp 0 (phiên âm), 1 đến 6, và cấp 7-9 gộp chung
enum Curriculum {
    /// 0 = nhập môn phiên âm, 1...6 = các cấp, 7 = cấp 7-9 (chuẩn 3.0 gộp ba cấp này)
    static let levels = Array(0...7)

    static func name(_ level: Int) -> String {
        level == 7 ? "HSK 7–9" : "HSK \(level)"
    }

    /// Số từ mới của từng cấp theo chuẩn HSK 3.0 (cộng dồn khoảng 11.000 từ)
    static let officialNewWords = [1: 500, 2: 772, 3: 973, 4: 1000, 5: 1071, 6: 1140, 7: 5636]

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
