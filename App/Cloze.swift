import Foundation

/// Ôn theo ngữ cảnh: che từ cần học trong câu ví dụ, người học chọn từ điền vào chỗ trống
enum Cloze {
    static let blank = "＿＿"

    /// Câu ví dụ với từ được che, hoặc nil nếu câu không chứa từ (hoặc câu chỉ có mỗi từ đó)
    static func sentence(for phrase: Phrase) -> String? {
        guard let zh = phrase.example?.zh, let range = zh.range(of: phrase.hanzi) else { return nil }
        let blanked = zh.replacingCharacters(in: range, with: blank)
        let context = blanked
            .replacingOccurrences(of: blank, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return context.isEmpty ? nil : blanked
    }

    /// Đáp án nhiễu: ưu tiên từ cùng số chữ và cùng cấp HSK (khó đoán hơn), không trùng chữ
    static func distractors(for phrase: Phrase, in pool: [Phrase], count: Int = 3) -> [Phrase] {
        let length = phrase.hanzi.count
        let tiers: [(Phrase) -> Bool] = [
            { $0.hanzi.count == length && $0.hskLevel == phrase.hskLevel },
            { $0.hanzi.count == length },
            { _ in true },
        ]
        let shuffled = pool.shuffled()
        var seen: Set<String> = [phrase.hanzi]
        var result: [Phrase] = []
        for tier in tiers {
            for other in shuffled {
                if result.count == count { return result }
                if other.id != phrase.id, tier(other), seen.insert(other.hanzi).inserted {
                    result.append(other)
                }
            }
        }
        return result
    }
}
