import SwiftUI

/// Một âm trong bảng phiên âm: âm, chữ ví dụ và pinyin của chữ đó
struct PinyinItem: Identifiable {
    let sound: String
    let example: String
    let pinyin: String
    var id: String { sound }
}

enum PinyinData {
    /// 23 thanh mẫu (phụ âm đầu), mỗi âm kèm một chữ thông dụng để nghe
    static let initials: [PinyinItem] = [
        PinyinItem(sound: "b", example: "爸", pinyin: "bà"),
        PinyinItem(sound: "p", example: "怕", pinyin: "pà"),
        PinyinItem(sound: "m", example: "妈", pinyin: "mā"),
        PinyinItem(sound: "f", example: "飞", pinyin: "fēi"),
        PinyinItem(sound: "d", example: "大", pinyin: "dà"),
        PinyinItem(sound: "t", example: "他", pinyin: "tā"),
        PinyinItem(sound: "n", example: "那", pinyin: "nà"),
        PinyinItem(sound: "l", example: "拉", pinyin: "lā"),
        PinyinItem(sound: "g", example: "个", pinyin: "gè"),
        PinyinItem(sound: "k", example: "可", pinyin: "kě"),
        PinyinItem(sound: "h", example: "喝", pinyin: "hē"),
        PinyinItem(sound: "j", example: "家", pinyin: "jiā"),
        PinyinItem(sound: "q", example: "七", pinyin: "qī"),
        PinyinItem(sound: "x", example: "西", pinyin: "xī"),
        PinyinItem(sound: "zh", example: "知", pinyin: "zhī"),
        PinyinItem(sound: "ch", example: "吃", pinyin: "chī"),
        PinyinItem(sound: "sh", example: "是", pinyin: "shì"),
        PinyinItem(sound: "r", example: "日", pinyin: "rì"),
        PinyinItem(sound: "z", example: "字", pinyin: "zì"),
        PinyinItem(sound: "c", example: "次", pinyin: "cì"),
        PinyinItem(sound: "s", example: "四", pinyin: "sì"),
        PinyinItem(sound: "y", example: "一", pinyin: "yī"),
        PinyinItem(sound: "w", example: "五", pinyin: "wǔ"),
    ]

    /// 36 vận mẫu (vần), mỗi vần kèm một chữ thông dụng để nghe
    static let finals: [PinyinItem] = [
        PinyinItem(sound: "a", example: "啊", pinyin: "ā"),
        PinyinItem(sound: "o", example: "哦", pinyin: "ò"),
        PinyinItem(sound: "e", example: "鹅", pinyin: "é"),
        PinyinItem(sound: "i", example: "衣", pinyin: "yī"),
        PinyinItem(sound: "u", example: "五", pinyin: "wǔ"),
        PinyinItem(sound: "ü", example: "鱼", pinyin: "yú"),
        PinyinItem(sound: "ai", example: "爱", pinyin: "ài"),
        PinyinItem(sound: "ei", example: "黑", pinyin: "hēi"),
        PinyinItem(sound: "ao", example: "好", pinyin: "hǎo"),
        PinyinItem(sound: "ou", example: "狗", pinyin: "gǒu"),
        PinyinItem(sound: "an", example: "山", pinyin: "shān"),
        PinyinItem(sound: "en", example: "人", pinyin: "rén"),
        PinyinItem(sound: "ang", example: "忙", pinyin: "máng"),
        PinyinItem(sound: "eng", example: "冷", pinyin: "lěng"),
        PinyinItem(sound: "ong", example: "中", pinyin: "zhōng"),
        PinyinItem(sound: "ia", example: "家", pinyin: "jiā"),
        PinyinItem(sound: "ie", example: "谢", pinyin: "xiè"),
        PinyinItem(sound: "iao", example: "小", pinyin: "xiǎo"),
        PinyinItem(sound: "iu", example: "六", pinyin: "liù"),
        PinyinItem(sound: "ian", example: "天", pinyin: "tiān"),
        PinyinItem(sound: "in", example: "心", pinyin: "xīn"),
        PinyinItem(sound: "iang", example: "想", pinyin: "xiǎng"),
        PinyinItem(sound: "ing", example: "听", pinyin: "tīng"),
        PinyinItem(sound: "iong", example: "用", pinyin: "yòng"),
        PinyinItem(sound: "ua", example: "花", pinyin: "huā"),
        PinyinItem(sound: "uo", example: "我", pinyin: "wǒ"),
        PinyinItem(sound: "uai", example: "快", pinyin: "kuài"),
        PinyinItem(sound: "ui", example: "对", pinyin: "duì"),
        PinyinItem(sound: "uan", example: "玩", pinyin: "wán"),
        PinyinItem(sound: "un", example: "文", pinyin: "wén"),
        PinyinItem(sound: "uang", example: "王", pinyin: "wáng"),
        PinyinItem(sound: "ueng", example: "翁", pinyin: "wēng"),
        PinyinItem(sound: "üe", example: "月", pinyin: "yuè"),
        PinyinItem(sound: "üan", example: "远", pinyin: "yuǎn"),
        PinyinItem(sound: "ün", example: "云", pinyin: "yún"),
        PinyinItem(sound: "er", example: "二", pinyin: "èr"),
    ]

    /// Mẹo phát âm cho người Việt
    static let tips: [(title: String, text: String)] = [
        ("b, d, g và p, t, k", "b, d, g không bật hơi (như p, t, c trong tiếng Việt). p, t, k bật hơi mạnh: đặt tờ giấy trước miệng, đọc p t k thì tờ giấy phải bay."),
        ("j, q, x", "Đầu lưỡi chạm chân răng dưới, mặt lưỡi nâng lên. q là j nhưng có bật hơi. Chỉ ghép với i và ü."),
        ("zh, ch, sh, r", "Cong đầu lưỡi lên vòm miệng. Gần tr, ch, s, r kiểu cuốn lưỡi, nhưng lưỡi cong hơn tiếng Việt."),
        ("z, c, s", "Đầu lưỡi đặt sát mặt sau răng cửa, không cong. c bật hơi, z không bật hơi."),
        ("ü", "Chu môi tròn như đọc u, nhưng giữ lưỡi ở vị trí đọc i."),
        ("Thanh điệu", "Thanh 1 cao và đều, thanh 2 đi lên, thanh 3 xuống thấp rồi lên, thanh 4 rơi nhanh từ cao xuống. Thanh nhẹ đọc ngắn và nhẹ."),
    ]
}

/// Bảng phiên âm: chạm vào từng âm để nghe chữ ví dụ
struct PinyinChartView: View {
    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Chạm vào từng ô để nghe chữ ví dụ.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                section("Thanh mẫu (phụ âm đầu)", items: PinyinData.initials)
                section("Vận mẫu (vần)", items: PinyinData.finals)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mẹo cho người Việt").font(.headline)
                    ForEach(PinyinData.tips, id: \.title) { tip in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.title).font(.subheadline.weight(.semibold))
                            Text(tip.text).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Bảng phiên âm")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, items: [PinyinItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(title) · \(items.count) âm").font(.headline)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    Button {
                        Speaker.shared.speak(item.example)
                    } label: {
                        VStack(spacing: 2) {
                            Text(item.sound).font(.title3.weight(.bold))
                            Text(item.example).font(.title2)
                            Text(item.pinyin).font(.caption).foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.sound), chữ \(item.example), đọc \(item.pinyin)")
                }
            }
        }
    }
}
