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
