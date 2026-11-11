import Foundation

/// Một trong 214 bộ thủ Khang Hy
struct Radical: Identifiable, Hashable {
    /// Số thứ tự 1...214
    let no: Int
    /// Dạng Khang Hy, ví dụ "言"
    let char: String
    /// Dạng biến thể / giản thể hay gặp, ví dụ "讠" (có thể rỗng)
    let variants: String
    /// Tên Hán Việt, ví dụ "Ngôn"
    let name: String
    /// Nghĩa tiếng Việt
    let meaning: String

    var id: Int { no }
    /// Hiển thị: "言 讠"
    var display: String { variants.isEmpty ? char : "\(char) \(variants)" }
    /// Tên đầy đủ: "Bộ Ngôn (lời nói)"
    var title: String { "Bộ \(name) (\(meaning))" }
}

/// Bộ thủ của từng chữ (dữ liệu kRSUnicode của Unicode, đóng gói trong `radicals.json`)
enum RadicalStore {
    static let all: [Radical] = table.map { Radical(no: $0.0, char: $0.1, variants: $0.2, name: $0.3, meaning: $0.4) }

    static func radical(no: Int) -> Radical? {
        guard (1...all.count).contains(no) else { return nil }
        return all[no - 1]
    }

    /// Chữ Hán -> số bộ thủ
    static let map: [String: Int] = {
        guard let url = Bundle.main.url(forResource: "radicals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return map
    }()

    static func radical(of char: Character) -> Radical? {
        map[String(char)].flatMap { radical(no: $0) }
    }

    /// Một bộ thủ cùng các chữ và từ trong app có chứa bộ đó
    struct Group: Identifiable {
        let radical: Radical
        /// Các chữ thuộc bộ này, theo thứ tự xuất hiện đầu tiên trong danh sách từ
        let chars: [Character]
        /// Các từ có chứa ít nhất một chữ thuộc bộ này
        let words: [Phrase]
        var id: Int { radical.no }
    }

    /// Nhóm từ theo bộ thủ, bộ có nhiều chữ nhất đứng trước
    static func groups(in phrases: [Phrase], map: [String: Int] = RadicalStore.map) -> [Group] {
        var chars: [Int: [Character]] = [:]
        var seenChars = Set<Character>()
        var words: [Int: [Phrase]] = [:]
        for phrase in phrases {
            var radicalsInWord = Set<Int>()
            for c in phrase.hanzi {
                guard let no = map[String(c)] else { continue }
                if seenChars.insert(c).inserted { chars[no, default: []].append(c) }
                if radicalsInWord.insert(no).inserted { words[no, default: []].append(phrase) }
            }
        }
        return chars.compactMap { no, list in
            radical(no: no).map { Group(radical: $0, chars: list, words: words[no] ?? []) }
        }
        .sorted { ($0.chars.count, -$0.radical.no) > ($1.chars.count, -$1.radical.no) }
    }

    // (số, Khang Hy, biến thể, Hán Việt, nghĩa)
    private static let table: [(Int, String, String, String, String)] = [
        (1, "一", "", "Nhất", "số một"), (2, "丨", "", "Cổn", "nét sổ"), (3, "丶", "", "Chủ", "dấu chấm"),
        (4, "丿", "", "Phiệt", "nét phẩy"), (5, "乙", "乚", "Ất", "can Ất"), (6, "亅", "", "Quyết", "nét sổ móc"),
        (7, "二", "", "Nhị", "số hai"), (8, "亠", "", "Đầu", "nắp, đầu"), (9, "人", "亻", "Nhân", "người"),
        (10, "儿", "", "Nhân", "người đi"), (11, "入", "", "Nhập", "vào"), (12, "八", "丷", "Bát", "số tám"),
        (13, "冂", "", "Quynh", "vùng biên giới"), (14, "冖", "", "Mịch", "trùm, che"), (15, "冫", "", "Băng", "nước đá"),
        (16, "几", "", "Kỷ", "ghế dựa"), (17, "凵", "", "Khảm", "há miệng"), (18, "刀", "刂", "Đao", "con dao"),
        (19, "力", "", "Lực", "sức"), (20, "勹", "", "Bao", "bao bọc"), (21, "匕", "", "Chủy", "cái thìa"),
        (22, "匚", "", "Phương", "tủ đựng"), (23, "匸", "", "Hễ", "che đậy"), (24, "十", "", "Thập", "số mười"),
        (25, "卜", "", "Bốc", "xem bói"), (26, "卩", "㔾", "Tiết", "đốt tre"), (27, "厂", "", "Hán", "sườn núi"),
        (28, "厶", "", "Khư", "riêng tư"), (29, "又", "", "Hựu", "lại nữa, bàn tay"), (30, "口", "", "Khẩu", "miệng"),
        (31, "囗", "", "Vi", "vây quanh"), (32, "土", "", "Thổ", "đất"), (33, "士", "", "Sĩ", "học trò"),
        (34, "夂", "", "Truy", "đến sau"), (35, "夊", "", "Tuy", "đi chậm"), (36, "夕", "", "Tịch", "buổi tối"),
        (37, "大", "", "Đại", "to lớn"), (38, "女", "", "Nữ", "con gái"), (39, "子", "", "Tử", "con"),
        (40, "宀", "", "Miên", "mái nhà"), (41, "寸", "", "Thốn", "tấc"), (42, "小", "⺌", "Tiểu", "nhỏ"),
        (43, "尢", "", "Uông", "yếu đuối"), (44, "尸", "", "Thi", "thây, thân người"), (45, "屮", "", "Triệt", "mầm non"),
        (46, "山", "", "Sơn", "núi"), (47, "巛", "川", "Xuyên", "sông"), (48, "工", "", "Công", "thợ, công việc"),
        (49, "己", "", "Kỷ", "bản thân"), (50, "巾", "", "Cân", "khăn"), (51, "干", "", "Can", "thiên can, phạm"),
        (52, "幺", "", "Yêu", "nhỏ nhắn"), (53, "广", "", "Nghiễm", "mái nhà rộng"), (54, "廴", "", "Dẫn", "bước dài"),
        (55, "廾", "", "Củng", "chắp tay"), (56, "弋", "", "Dặc", "bắn"), (57, "弓", "", "Cung", "cái cung"),
        (58, "彐", "⺕", "Kệ", "đầu con nhím"), (59, "彡", "", "Sam", "lông tóc dài"), (60, "彳", "", "Xích", "bước chân trái"),
        (61, "心", "忄", "Tâm", "tim, lòng"), (62, "戈", "", "Qua", "cây mác"), (63, "戶", "户", "Hộ", "cửa một cánh"),
        (64, "手", "扌", "Thủ", "tay"), (65, "支", "", "Chi", "cành nhánh"), (66, "攴", "攵", "Phộc", "đánh khẽ"),
        (67, "文", "", "Văn", "văn vẻ"), (68, "斗", "", "Đẩu", "cái đấu"), (69, "斤", "", "Cân", "cái rìu"),
        (70, "方", "", "Phương", "vuông, phương hướng"), (71, "无", "", "Vô", "không"), (72, "日", "", "Nhật", "mặt trời, ngày"),
        (73, "曰", "", "Viết", "nói rằng"), (74, "月", "", "Nguyệt", "mặt trăng"), (75, "木", "", "Mộc", "cây"),
        (76, "欠", "", "Khiếm", "thiếu"), (77, "止", "", "Chỉ", "dừng lại"), (78, "歹", "", "Đãi", "xấu, chết"),
        (79, "殳", "", "Thù", "binh khí dài"), (80, "毋", "", "Vô", "chớ, đừng"), (81, "比", "", "Tỷ", "so sánh"),
        (82, "毛", "", "Mao", "lông"), (83, "氏", "", "Thị", "họ"), (84, "气", "", "Khí", "hơi"),
        (85, "水", "氵", "Thủy", "nước"), (86, "火", "灬", "Hỏa", "lửa"), (87, "爪", "爫", "Trảo", "móng vuốt"),
        (88, "父", "", "Phụ", "cha"), (89, "爻", "", "Hào", "hào (quẻ bói)"), (90, "爿", "丬", "Tường", "mảnh gỗ"),
        (91, "片", "", "Phiến", "tấm, mảnh"), (92, "牙", "", "Nha", "răng"), (93, "牛", "牜", "Ngưu", "trâu bò"),
        (94, "犬", "犭", "Khuyển", "chó"), (95, "玄", "", "Huyền", "màu đen huyền"), (96, "玉", "王", "Ngọc", "đá quý"),
        (97, "瓜", "", "Qua", "quả dưa"), (98, "瓦", "", "Ngõa", "ngói"), (99, "甘", "", "Cam", "ngọt"),
        (100, "生", "", "Sinh", "sinh sống"), (101, "用", "", "Dụng", "dùng"), (102, "田", "", "Điền", "ruộng"),
        (103, "疋", "⺪", "Sơ", "đơn vị đo vải"), (104, "疒", "", "Nạch", "bệnh tật"), (105, "癶", "", "Bát", "gạt ngược lại"),
        (106, "白", "", "Bạch", "màu trắng"), (107, "皮", "", "Bì", "da"), (108, "皿", "", "Mãnh", "bát đĩa"),
        (109, "目", "", "Mục", "mắt"), (110, "矛", "", "Mâu", "cây giáo"), (111, "矢", "", "Thỉ", "mũi tên"),
        (112, "石", "", "Thạch", "đá"), (113, "示", "礻", "Thị", "thần đất, chỉ bảo"), (114, "禸", "", "Nhựu", "vết chân thú"),
        (115, "禾", "", "Hòa", "lúa"), (116, "穴", "", "Huyệt", "hang lỗ"), (117, "立", "", "Lập", "đứng"),
        (118, "竹", "⺮", "Trúc", "tre"), (119, "米", "", "Mễ", "gạo"), (120, "糸", "纟", "Mịch", "sợi tơ"),
        (121, "缶", "", "Phẫu", "đồ sành"), (122, "网", "罒", "Võng", "lưới"), (123, "羊", "", "Dương", "con dê"),
        (124, "羽", "", "Vũ", "lông vũ"), (125, "老", "耂", "Lão", "già"), (126, "而", "", "Nhi", "mà, và"),
        (127, "耒", "", "Lỗi", "cái cày"), (128, "耳", "", "Nhĩ", "tai"), (129, "聿", "", "Duật", "cây bút"),
        (130, "肉", "月", "Nhục", "thịt"), (131, "臣", "", "Thần", "bề tôi"), (132, "自", "", "Tự", "tự bản thân"),
        (133, "至", "", "Chí", "đến"), (134, "臼", "", "Cữu", "cái cối"), (135, "舌", "", "Thiệt", "lưỡi"),
        (136, "舛", "", "Suyễn", "sai lầm"), (137, "舟", "", "Chu", "thuyền"), (138, "艮", "", "Cấn", "bền, quẻ Cấn"),
        (139, "色", "", "Sắc", "màu sắc"), (140, "艸", "艹", "Thảo", "cỏ"), (141, "虍", "", "Hô", "vằn hổ"),
        (142, "虫", "", "Trùng", "sâu bọ"), (143, "血", "", "Huyết", "máu"), (144, "行", "", "Hành", "đi"),
        (145, "衣", "衤", "Y", "áo"), (146, "襾", "覀", "Á", "che đậy"), (147, "見", "见", "Kiến", "thấy"),
        (148, "角", "", "Giác", "sừng"), (149, "言", "讠", "Ngôn", "lời nói"), (150, "谷", "", "Cốc", "khe suối"),
        (151, "豆", "", "Đậu", "hạt đậu"), (152, "豕", "", "Thỉ", "con lợn"), (153, "豸", "", "Trãi", "loài thú không chân"),
        (154, "貝", "贝", "Bối", "vỏ sò, tiền"), (155, "赤", "", "Xích", "màu đỏ"), (156, "走", "", "Tẩu", "chạy"),
        (157, "足", "⻊", "Túc", "chân"), (158, "身", "", "Thân", "thân thể"), (159, "車", "车", "Xa", "xe"),
        (160, "辛", "", "Tân", "cay"), (161, "辰", "", "Thần", "chi Thìn"), (162, "辵", "辶", "Sước", "chợt đi chợt dừng"),
        (163, "邑", "阝", "Ấp", "vùng đất (阝 bên phải)"), (164, "酉", "", "Dậu", "rượu"), (165, "釆", "", "Biện", "phân biệt"),
        (166, "里", "", "Lý", "dặm, làng"), (167, "金", "钅", "Kim", "kim loại"), (168, "長", "长", "Trường", "dài"),
        (169, "門", "门", "Môn", "cửa hai cánh"), (170, "阜", "阝", "Phụ", "gò đất (阝 bên trái)"), (171, "隶", "", "Đãi", "kịp"),
        (172, "隹", "", "Chuy", "chim đuôi ngắn"), (173, "雨", "", "Vũ", "mưa"), (174, "靑", "青", "Thanh", "màu xanh"),
        (175, "非", "", "Phi", "không phải"), (176, "面", "", "Diện", "mặt"), (177, "革", "", "Cách", "da thú"),
        (178, "韋", "韦", "Vi", "da đã thuộc"), (179, "韭", "", "Cửu", "rau hẹ"), (180, "音", "", "Âm", "âm thanh"),
        (181, "頁", "页", "Hiệt", "đầu, trang"), (182, "風", "风", "Phong", "gió"), (183, "飛", "飞", "Phi", "bay"),
        (184, "食", "饣", "Thực", "ăn"), (185, "首", "", "Thủ", "đầu"), (186, "香", "", "Hương", "mùi thơm"),
        (187, "馬", "马", "Mã", "ngựa"), (188, "骨", "", "Cốt", "xương"), (189, "高", "", "Cao", "cao"),
        (190, "髟", "", "Tiêu", "tóc dài"), (191, "鬥", "", "Đấu", "đánh nhau"), (192, "鬯", "", "Sưởng", "rượu nếp"),
        (193, "鬲", "", "Cách", "nồi đỉnh"), (194, "鬼", "", "Quỷ", "ma quỷ"), (195, "魚", "鱼", "Ngư", "cá"),
        (196, "鳥", "鸟", "Điểu", "chim"), (197, "鹵", "卤", "Lỗ", "đất mặn"), (198, "鹿", "", "Lộc", "hươu"),
        (199, "麥", "麦", "Mạch", "lúa mạch"), (200, "麻", "", "Ma", "cây gai"), (201, "黃", "黄", "Hoàng", "màu vàng"),
        (202, "黍", "", "Thử", "lúa nếp"), (203, "黑", "", "Hắc", "màu đen"), (204, "黹", "", "Chỉ", "may vá"),
        (205, "黽", "黾", "Mãnh", "con ếch"), (206, "鼎", "", "Đỉnh", "cái đỉnh"), (207, "鼓", "", "Cổ", "cái trống"),
        (208, "鼠", "", "Thử", "con chuột"), (209, "鼻", "", "Tỵ", "mũi"), (210, "齊", "齐", "Tề", "ngang bằng"),
        (211, "齒", "齿", "Xỉ", "răng"), (212, "龍", "龙", "Long", "rồng"), (213, "龜", "龟", "Quy", "rùa"),
        (214, "龠", "", "Dược", "sáo ba lỗ"),
    ]
}
