import XCTest
@testable import HanziLock

final class PhraseTests: XCTestCase {
    private let hello = Phrase(id: 1, hanzi: "你好", pinyin: "nǐ hǎo", readingVi: "nỉ hảo",
                               meaningVi: "Xin chào", topic: "Giao tiếp", hanViet: "Nễ hảo")

    func testFoldedRemovesDiacritics() {
        XCTAssertEqual("Nỉ Hảo".folded, "ni hao")
        XCTAssertEqual("đi".folded, "di")
    }

    func testMatchesIgnoresDiacritics() {
        XCTAssertTrue(hello.matches("ni hao"))
        XCTAssertTrue(hello.matches("nỉ hảo"))
        XCTAssertTrue(hello.matches("chao"))
        XCTAssertTrue(hello.matches("你好"))
        XCTAssertFalse(hello.matches("tạm biệt"))
        XCTAssertTrue(hello.matches("   "))
    }

    func testHSKLevelFromTopic() {
        func make(_ topic: String, hsk: Int? = nil) -> Phrase {
            Phrase(id: 1, hanzi: "x", pinyin: "x", readingVi: "x", meaningVi: "x", topic: topic, hsk: hsk)
        }
        XCTAssertEqual(make("HSK 3").hskLevel, 3)
        XCTAssertEqual(make("HSK 7-9").hskLevel, 7)
        XCTAssertEqual(make("Giao tiếp", hsk: 2).hskLevel, 2)
        XCTAssertNil(make("Giao tiếp").hskLevel)
    }

    func testDecodeToleratesMissingOptionalFields() throws {
        let json = #"[{"id":5,"hanzi":"水","pinyin":"shuǐ","readingVi":"thủy","meaningVi":"Nước"}]"#
        let list = try JSONDecoder().decode([Phrase].self, from: Data(json.utf8))
        XCTAssertEqual(list.first?.topic, "Khác")
        XCTAssertNil(list.first?.example)
    }

    func testPhraseRotationSkipsLearned() {
        let list = (1...4).map {
            Phrase(id: $0, hanzi: "字\($0)", pinyin: "p", readingVi: "v", meaningVi: "m", topic: "T")
        }
        let date = Date(timeIntervalSince1970: 0)
        let picked = PhraseStore.phrase(at: date, in: list, learned: [1, 2, 3])
        XCTAssertEqual(picked.id, 4)
        // Đã thuộc hết thì vẫn trả về một từ
        let all = PhraseStore.phrase(at: date, in: list, learned: [1, 2, 3, 4])
        XCTAssertTrue((1...4).contains(all.id))
    }

    func testBundledDataIsValid() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "phrases", withExtension: "json"))
        let list = try JSONDecoder().decode([Phrase].self, from: Data(contentsOf: url))
        XCTAssertGreaterThan(list.count, 1000)
        XCTAssertEqual(Set(list.map(\.id)).count, list.count, "id bị trùng")
    }
}

final class ProgressStoreTests: XCTestCase {
    override func setUp() { ProgressStore.resetAll() }
    override func tearDown() { ProgressStore.resetAll() }

    func testNewWordBecomesLearnedAfterStreak() {
        XCTAssertEqual(ProgressStore.state(of: 1), .new)
        for i in 1...ProgressStore.streakToLearn {
            let learned = ProgressStore.record(1, correct: true)
            XCTAssertEqual(learned, i == ProgressStore.streakToLearn)
        }
        XCTAssertTrue(ProgressStore.learned.contains(1))
        XCTAssertEqual(ProgressStore.state(of: 1), .later)
    }

    func testWrongAnswerLowersStreakAndUnlearns() {
        ProgressStore.setLearned(2, true)
        XCTAssertFalse(ProgressStore.record(2, correct: false))
        XCTAssertFalse(ProgressStore.learned.contains(2))
        XCTAssertEqual(ProgressStore.state(of: 2), .due)
    }

    /// Số ngày từ bây giờ đến lần ôn sau của một từ (qua bản chụp lịch ôn: dùng backup để đọc `dueDates`)
    private func daysUntilDue(_ id: Int) throws -> Double {
        let data = try XCTUnwrap(ProgressStore.exportBackup())
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(root["data"] as? [String: Any])
        let due = try XCTUnwrap((payload["dueDates"] as? [String: Double])?[String(id)])
        return (due - Date().timeIntervalSince1970) / 86400
    }

    func testGradesSpaceReviewsDifferently() throws {
        // Lần đầu: Khó = 1 ngày, Dễ = 3 ngày
        ProgressStore.record(20, grade: .hard)
        ProgressStore.record(21, grade: .easy)
        XCTAssertEqual(try daysUntilDue(20), 1, accuracy: 0.01)
        XCTAssertEqual(try daysUntilDue(21), 3, accuracy: 0.01)
    }

    func testGoodIntervalsGrowAndAgainResets() throws {
        ProgressStore.record(22, grade: .good)               // 1 ngày
        ProgressStore.record(22, grade: .good)               // 3 ngày
        XCTAssertEqual(try daysUntilDue(22), 3, accuracy: 0.01)
        ProgressStore.record(22, grade: .good)               // 3 × 2,5 = 7,5 ngày
        XCTAssertEqual(try daysUntilDue(22), 7.5, accuracy: 0.01)
        ProgressStore.record(22, grade: .again)              // hỏi lại ngay
        XCTAssertLessThan(try daysUntilDue(22), 0.01)
        XCTAssertEqual(ProgressStore.state(of: 22), .due)
    }

    func testIntervalIsCapped() throws {
        for _ in 0..<30 { ProgressStore.record(23, grade: .easy) }
        XCTAssertLessThanOrEqual(try daysUntilDue(23), ProgressStore.maxIntervalDays + 0.01)
    }

    func testStudyStreakAndCounts() {
        XCTAssertEqual(ProgressStore.currentStreak, 0)
        ProgressStore.record(3, correct: true)
        XCTAssertTrue(ProgressStore.studiedToday)
        XCTAssertEqual(ProgressStore.currentStreak, 1)
        XCTAssertEqual(ProgressStore.count(on: Date()), 1)
        XCTAssertEqual(ProgressStore.newWords(on: Date()), 1)
    }

    func testFavoritesToggleAndReset() {
        ProgressStore.toggleFavorite(7)
        XCTAssertTrue(ProgressStore.favorites.contains(7))
        ProgressStore.resetAll()
        XCTAssertTrue(ProgressStore.favorites.isEmpty)
    }

    func testBackupRoundTrip() throws {
        ProgressStore.setLearned(10, true)
        ProgressStore.toggleFavorite(11)
        ProgressStore.record(12, correct: true)
        let backup = try XCTUnwrap(ProgressStore.exportBackup())

        ProgressStore.resetAll()
        XCTAssertTrue(ProgressStore.learned.isEmpty)

        XCTAssertTrue(ProgressStore.importBackup(backup))
        XCTAssertTrue(ProgressStore.learned.contains(10))
        XCTAssertTrue(ProgressStore.favorites.contains(11))
        XCTAssertNotEqual(ProgressStore.state(of: 12), .new)
        XCTAssertFalse(ProgressStore.importBackup(Data("không phải json".utf8)))
    }
}

final class ClozeTests: XCTestCase {
    private func make(_ id: Int, _ hanzi: String, example: String? = nil, topic: String = "HSK 1") -> Phrase {
        Phrase(id: id, hanzi: hanzi, pinyin: "p", readingVi: "v", meaningVi: "m\(id)", topic: topic,
               example: example.map { Phrase.Example(zh: $0, pinyin: "p", vi: "v") })
    }

    func testSentenceBlanksTheWord() {
        XCTAssertEqual(Cloze.sentence(for: make(1, "谢谢", example: "谢谢你的帮助。")), "＿＿你的帮助。")
    }

    func testSentenceNeedsContext() {
        XCTAssertNil(Cloze.sentence(for: make(1, "你好", example: "你好！")))
        XCTAssertNil(Cloze.sentence(for: make(2, "你好", example: "早上好。")))
        XCTAssertNil(Cloze.sentence(for: make(3, "你好")))
    }

    func testDistractorsPreferSameLengthAndAreUnique() {
        let target = make(1, "学习")
        let pool = [target, make(2, "工作"), make(3, "吃饭"), make(4, "书"), make(5, "老师"), make(6, "工作")]
        let options = Cloze.distractors(for: target, in: pool)
        XCTAssertEqual(options.count, 3)
        XCTAssertFalse(options.contains { $0.id == target.id })
        XCTAssertEqual(Set(options.map(\.hanzi)).count, 3)
        XCTAssertTrue(options.allSatisfy { $0.hanzi.count == 2 })
    }
}

final class RadicalTests: XCTestCase {
    func testTableHas214RadicalsInOrder() {
        XCTAssertEqual(RadicalStore.all.count, 214)
        XCTAssertEqual(RadicalStore.all.map(\.no), Array(1...214))
        XCTAssertEqual(RadicalStore.radical(no: 149)?.name, "Ngôn")
        XCTAssertNil(RadicalStore.radical(no: 0))
    }

    func testBundledMapKnowsCommonCharacters() {
        XCTAssertEqual(RadicalStore.radical(of: "说")?.no, 149)
        XCTAssertEqual(RadicalStore.radical(of: "妈")?.no, 38)
        XCTAssertEqual(RadicalStore.radical(of: "河")?.no, 85)
    }

    func testGroupsCollectCharsAndWords() {
        func make(_ id: Int, _ hanzi: String) -> Phrase {
            Phrase(id: id, hanzi: hanzi, pinyin: "p", readingVi: "v", meaningVi: "m", topic: "T")
        }
        let words = [make(1, "妈妈"), make(2, "好"), make(3, "河水"), make(4, "你好")]
        let map = ["妈": 38, "好": 38, "河": 85, "水": 85, "你": 9]
        let groups = RadicalStore.groups(in: words, map: map)
        XCTAssertEqual(groups.first?.radical.no, 38)              // nhiều chữ nhất (妈, 好), số bộ nhỏ hơn bộ 85
        XCTAssertEqual(groups.first?.chars, ["妈", "好"])
        XCTAssertEqual(groups.first?.words.map(\.id), [1, 2, 4])
        XCTAssertEqual(groups.first { $0.radical.no == 85 }?.words.map(\.id), [3])
        XCTAssertEqual(groups.count, 3)
    }
}

final class SpeechSettingsTests: XCTestCase {
    func testRateIsClamped() {
        XCTAssertEqual(SpeechSettings.clampedRate(0.0), SpeechSettings.rateRange.lowerBound)
        XCTAssertEqual(SpeechSettings.clampedRate(0.9), SpeechSettings.rateRange.upperBound)
        XCTAssertEqual(SpeechSettings.clampedRate(0.42), 0.42, accuracy: 0.0001)
    }

    func testSlowRateIsSlowerButNotTooSlow() {
        for normal in stride(from: SpeechSettings.rateRange.lowerBound, through: SpeechSettings.rateRange.upperBound, by: 0.05) {
            let slow = SpeechSettings.slowRate(from: normal)
            XCTAssertLessThan(slow, normal)
            XCTAssertGreaterThanOrEqual(slow, 0.22)
        }
    }

    func testQualityRanking() {
        XCTAssertGreaterThan(SpeechSettings.qualityRank(.premium), SpeechSettings.qualityRank(.enhanced))
        XCTAssertGreaterThan(SpeechSettings.qualityRank(.enhanced), SpeechSettings.qualityRank(.default))
    }

    func testAvailableVoicesAreMandarinAndBestFirst() {
        let voices = SpeechSettings.availableVoices()
        XCTAssertTrue(voices.allSatisfy { $0.language == "zh-CN" })
        let ranks = voices.map { SpeechSettings.qualityRank($0.quality) }
        XCTAssertEqual(ranks, ranks.sorted(by: >))
    }
}

final class PinyinInputTests: XCTestCase {
    func testToneNumbersBecomeMarks() {
        XCTAssertEqual(PinyinInput.applyToneNumbers("ni3 hao3"), "nǐ hǎo")
        XCTAssertEqual(PinyinInput.applyToneNumbers("xie4xie"), "xièxie")
        XCTAssertEqual(PinyinInput.applyToneNumbers("nv3"), "nǚ")
        XCTAssertEqual(PinyinInput.applyToneNumbers("liu2"), "liú")
        XCTAssertEqual(PinyinInput.applyToneNumbers("gui4"), "guì")
        XCTAssertEqual(PinyinInput.applyToneNumbers("dou1"), "dōu")
        XCTAssertEqual(PinyinInput.applyToneNumbers("duo1"), "duō")
        XCTAssertEqual(PinyinInput.applyToneNumbers("lve4"), "lüè")
    }

    func testGradeAcceptsMarksAndNumbers() {
        XCTAssertEqual(PinyinInput.grade("ni3 hao3", expected: "nǐ hǎo"), .correct)
        XCTAssertEqual(PinyinInput.grade("nǐ hǎo", expected: "nǐ hǎo"), .correct)
        XCTAssertEqual(PinyinInput.grade("NI3HAO3", expected: "nǐ hǎo"), .correct)
        XCTAssertEqual(PinyinInput.grade("xie4xie", expected: "xièxie"), .correct)
        XCTAssertEqual(PinyinInput.grade("nv3er2", expected: "nǚ'ér"), .correct)
        XCTAssertEqual(PinyinInput.grade("xi1an1", expected: "Xī'ān"), .correct)
    }

    func testGradeTellsToneMistakeFromWrongSound() {
        XCTAssertEqual(PinyinInput.grade("ni2 hao3", expected: "nǐ hǎo"), .wrongTone)
        XCTAssertEqual(PinyinInput.grade("ni hao", expected: "nǐ hǎo"), .wrongTone)
        XCTAssertEqual(PinyinInput.grade("ni3 hei3", expected: "nǐ hǎo"), .wrong)
        XCTAssertEqual(PinyinInput.grade("   ", expected: "nǐ hǎo"), .wrong)
    }

    func testPunctuationInExpectedIsIgnored() {
        XCTAssertEqual(PinyinInput.grade("ni3 jiao4 shen2me ming2zi", expected: "nǐ jiào shénme míngzi?"), .correct)
    }
}

final class DifficultWordsTests: XCTestCase {
    override func setUp() { ProgressStore.resetAll() }
    override func tearDown() { ProgressStore.resetAll() }

    func testWordBecomesDifficultAfterRepeatedLapses() {
        ProgressStore.record(40, grade: .again)
        XCTAssertTrue(ProgressStore.difficultIDs().isEmpty)
        ProgressStore.record(40, grade: .again)
        XCTAssertEqual(ProgressStore.difficultIDs(), [40])
        XCTAssertEqual(ProgressStore.lapseCount(of: 40), 2)
    }

    func testMostForgottenComesFirstAndLearnedLeaves() {
        for _ in 0..<2 { ProgressStore.record(41, grade: .again) }
        for _ in 0..<3 { ProgressStore.record(42, grade: .again) }
        XCTAssertEqual(ProgressStore.difficultIDs(), [42, 41])
        ProgressStore.setLearned(42, true)
        XCTAssertEqual(ProgressStore.difficultIDs(), [41])
    }
}
