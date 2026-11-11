import Foundation

/// Chấm bài gõ pinyin. Chấp nhận pinyin có dấu ("nǐ hǎo") hoặc số thanh ("ni3 hao3", "nv3" = "nǚ"),
/// bỏ qua khoảng trắng, dấu nháy, gạch nối, dấu câu và chữ hoa.
enum PinyinInput {
    enum Result: Equatable {
        /// Đúng cả âm lẫn thanh điệu
        case correct
        /// Đúng âm nhưng sai hoặc thiếu thanh điệu
        case wrongTone
        case wrong
    }

    static func grade(_ answer: String, expected: String) -> Result {
        let given = canonical(answer)
        let target = canonical(expected)
        guard !given.isEmpty else { return .wrong }
        if given == target { return .correct }
        if stripTones(given) == stripTones(target) { return .wrongTone }
        return .wrong
    }

    /// Dạng so sánh: chữ thường, chỉ còn chữ cái, số thanh đổi thành dấu, v thành ü
    static func canonical(_ text: String) -> String {
        let marked = applyToneNumbers(text.lowercased())
        return String(marked.precomposedStringWithCanonicalMapping.filter { $0.isLetter })
    }

    /// Bỏ dấu thanh, giữ ü
    static func stripTones(_ text: String) -> String {
        let tones: Set<UInt32> = [0x0300, 0x0301, 0x0304, 0x030C]
        var scalars = String.UnicodeScalarView()
        for s in text.decomposedStringWithCanonicalMapping.unicodeScalars where !tones.contains(s.value) {
            scalars.append(s)
        }
        return String(scalars).precomposedStringWithCanonicalMapping
    }

    // MARK: Đổi số thanh thành dấu

    /// Thứ tự: thanh 1, 2, 3, 4
    private static let toneMarks: [Character: [Character]] = [
        "a": ["ā", "á", "ǎ", "à"], "e": ["ē", "é", "ě", "è"], "i": ["ī", "í", "ǐ", "ì"],
        "o": ["ō", "ó", "ǒ", "ò"], "u": ["ū", "ú", "ǔ", "ù"], "ü": ["ǖ", "ǘ", "ǚ", "ǜ"],
    ]

    /// "ni3 hao3" -> "nǐ hǎo". Số 5 hoặc 0 (thanh nhẹ) chỉ bị bỏ. Âm tiết không có số giữ nguyên.
    static func applyToneNumbers(_ text: String) -> String {
        var result = ""
        var syllable = ""
        func flush(tone: Int?) {
            let s = syllable.replacingOccurrences(of: "v", with: "ü")
            result += tone.map { markTone(s, tone: $0) } ?? s
            syllable = ""
        }
        for c in text {
            if let d = c.wholeNumberValue, (0...5).contains(d) {
                flush(tone: (1...4).contains(d) ? d : nil)
            } else {
                syllable.append(c)
            }
        }
        flush(tone: nil)
        return result
    }

    /// Đặt dấu thanh đúng quy tắc: a, e ưu tiên; "ou" đặt ở o; còn lại đặt ở nguyên âm cuối
    static func markTone(_ syllable: String, tone: Int) -> String {
        var chars = Array(syllable)
        let vowels = chars.indices.filter { toneMarks[chars[$0]] != nil }
        guard let lastVowel = vowels.last, (1...4).contains(tone) else { return syllable }
        let target: Int
        if let i = chars.firstIndex(of: "a") ?? chars.firstIndex(of: "e") {
            target = i
        } else if syllable.contains("ou"), let i = chars.firstIndex(of: "o") {
            target = i
        } else {
            target = lastVowel
        }
        chars[target] = toneMarks[chars[target]]![tone - 1]
        return String(chars)
    }
}
