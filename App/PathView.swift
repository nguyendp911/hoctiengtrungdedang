import SwiftUI

/// Mở một màn luyện từ tab Lộ trình hoặc từ một bài học
enum PathSheet: Identifiable {
    case flashcards([Phrase])
    case quiz(title: String, pool: [Phrase], length: Int, passMark: Double?)

    var id: String {
        switch self {
        case .flashcards: return "flashcards"
        case .quiz: return "quiz"
        }
    }
}

/// Tab "Lộ trình": chọn cấp HSK, kế hoạch học hôm nay, danh sách bài, thi thử
struct PathView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("pathLevel") private var level = 1
    @AppStorage("newPerDay") private var newPerDay = 5
    @State private var sheet: PathSheet?

    private var words: [Phrase] { Curriculum.words(level: level, in: model.phrases) }
    private var units: [HSKUnit] { Curriculum.units(level: level, in: model.phrases) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Cấp độ", selection: $level) {
                        ForEach(Curriculum.levels, id: \.self) { Text("HSK \($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section { overviewCard }
                Section("Kế hoạch hôm nay") { planCard }

                Section("Các bài học") {
                    if units.isEmpty {
                        Text("Chưa có từ HSK \(level) trong app.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(units) { unit in
                        NavigationLink {
                            UnitDetailView(unit: unit, level: level)
                        } label: {
                            unitRow(unit)
                        }
                    }
                }

                Section {
                    Button {
                        sheet = .quiz(title: "Thi thử HSK \(level)", pool: words, length: 20, passMark: 0.6)
                    } label: {
                        Label("Thi thử HSK \(level)", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                    }
                    .disabled(words.count < 4)
                } footer: {
                    Text("20 câu trộn các từ của HSK \(level), đạt từ 60%. Bài thi này kiểm tra từ vựng, không thay thế đề HSK thật.")
                }
            }
            .navigationTitle("Lộ trình")
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .flashcards(let pool):
                FlashcardView(pool: pool) { model.reloadProgress() }
            case .quiz(let title, let pool, let length, let passMark):
                QuizView(pool: pool, all: model.phrases, length: length, passMark: passMark, title: title) {
                    model.reloadProgress()
                }
            }
        }
    }

    // MARK: Tổng quan cấp

    private var overviewCard: some View {
        let total = words.count
        let done = words.filter { model.learned.contains($0.id) }.count
        let untouched = words.filter { ProgressStore.state(of: $0.id) == .new && !model.learned.contains($0.id) }.count
        let official = Curriculum.officialNewWords[level] ?? total
        let perDay = max(newPerDay, 1)
        let days = (untouched + perDay - 1) / perDay
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("HSK \(level)").font(.title2.weight(.bold))
                Spacer()
                Text("\(done)/\(total) từ đã thuộc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .accessibilityLabel("Đã thuộc \(done) trên \(total) từ")
            Text(days > 0
                 ? "Còn \(untouched) từ chưa học. Với \(newPerDay) từ mới mỗi ngày, bạn học xong trong khoảng \(days) ngày."
                 : "Bạn đã học qua toàn bộ từ HSK \(level) có trong app.")
                .font(.footnote)
            Text("App hiện có \(total) trong \(official) từ mới của HSK \(level). Thêm từ bằng cách sửa file từ vựng trên GitHub.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: Kế hoạch hôm nay

    private var planCard: some View {
        let newDone = ProgressStore.newWords(on: Date())
        let remainingNew = max(0, newPerDay - newDone)
        let candidates = words.filter { ProgressStore.state(of: $0.id) == .new && !model.learned.contains($0.id) }
        let todayNew = Array(candidates.prefix(remainingNew))
        let due = words.filter { ProgressStore.state(of: $0.id) == .due }
        let finished = todayNew.isEmpty && due.isEmpty
        return VStack(alignment: .leading, spacing: 12) {
            planRow(done: remainingNew == 0 || candidates.isEmpty,
                    title: "Học từ mới",
                    detail: "\(min(newDone, newPerDay))/\(newPerDay) từ hôm nay")
            planRow(done: due.isEmpty,
                    title: "Ôn lại từ đến hạn",
                    detail: due.isEmpty ? "Không còn từ nào" : "\(due.count) từ cần ôn")

            Button {
                if finished {
                    sheet = .flashcards(Array(candidates.prefix(5)))
                } else {
                    sheet = .flashcards(due + todayNew)
                }
            } label: {
                Label(finished ? "Học thêm 5 từ" : "Bắt đầu hôm nay",
                      systemImage: finished ? "plus" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .opacity(finished && candidates.isEmpty ? 0.4 : 1)

            Text(finished
                 ? (candidates.isEmpty ? "Bạn đã hết từ mới ở HSK \(level)." : "Hôm nay bạn đã xong kế hoạch. Học thêm nếu còn sức.")
                 : "Thẻ lật gồm từ đến hạn trước, rồi từ mới của bài tiếp theo. Đổi số từ mới mỗi ngày trong Cài đặt.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func planRow(done: Bool, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? Color.green : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body.weight(.medium))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Danh sách bài

    private func unitRow(_ unit: HSKUnit) -> some View {
        let done = unit.words.filter { model.learned.contains($0.id) }.count
        let complete = done == unit.words.count && !unit.words.isEmpty
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(complete ? Color.green.opacity(0.18) : Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                if complete {
                    Image(systemName: "checkmark").font(.headline).foregroundStyle(.green)
                } else {
                    Text("\(unit.no)").font(.headline).foregroundStyle(Color.accentColor)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("Bài \(unit.no) · \(unit.name)").font(.body.weight(.medium))
                ProgressView(value: Double(done), total: Double(max(unit.words.count, 1)))
                Text("\(done)/\(unit.words.count) từ đã thuộc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// Chi tiết một bài: danh sách từ, học bằng thẻ lật, kiểm tra bài
struct UnitDetailView: View {
    @EnvironmentObject private var model: AppModel
    let unit: HSKUnit
    let level: Int
    @State private var sheet: PathSheet?

    var body: some View {
        List {
            Section {
                Button {
                    sheet = .flashcards(unit.words)
                } label: {
                    Label("Học bài này bằng thẻ lật", systemImage: "rectangle.stack.fill")
                }
                Button {
                    sheet = .quiz(title: "Kiểm tra bài \(unit.no)", pool: unit.words,
                                  length: min(10, unit.words.count), passMark: 0.6)
                } label: {
                    Label("Kiểm tra bài", systemImage: "checklist")
                }
                .disabled(unit.words.count < 4)
            }

            Section("\(unit.words.count) từ") {
                ForEach(unit.words) { word in
                    Button {
                        Speaker.shared.speak(word.hanzi)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(word.hanzi).font(.title3.bold())
                                Text(word.pinyin).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(word.meaningVi)
                                .font(.subheadline)
                                .multilineTextAlignment(.trailing)
                            if model.learned.contains(word.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                    .tint(.primary)
                    .accessibilityHint("Chạm để nghe phát âm")
                }
            }
        }
        .navigationTitle("Bài \(unit.no) · HSK \(level)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { item in
            switch item {
            case .flashcards(let pool):
                FlashcardView(pool: pool) { model.reloadProgress() }
            case .quiz(let title, let pool, let length, let passMark):
                QuizView(pool: pool, all: model.phrases, length: length, passMark: passMark, title: title) {
                    model.reloadProgress()
                }
            }
        }
    }
}
