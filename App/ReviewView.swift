import SwiftUI
import Charts

/// Tab "Ôn tập": chuỗi ngày, mục tiêu hôm nay, từ cần ôn, các chế độ luyện, tiến độ theo chủ đề
struct ReviewView: View {
    enum Sheet: Identifiable {
        case quiz([Phrase]), listening, flashcards, tones

        var id: String {
            switch self {
            case .quiz: return "quiz"
            case .listening: return "listening"
            case .flashcards: return "flashcards"
            case .tones: return "tones"
            }
        }
    }

    struct DayStat: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    @EnvironmentObject private var model: AppModel
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @State private var sheet: Sheet?

    var body: some View {
        NavigationStack {
            List {
                Section { streakCard }
                Section("Hôm nay") { todayCard }
                Section { dueCard }
                Section("Luyện tập khác") {
                    modeRow("Thẻ lật", subtitle: "Vuốt phải khi đã nhớ, vuốt trái để học lại",
                            icon: "rectangle.stack.fill", color: .purple) { sheet = .flashcards }
                    modeRow("Luyện nghe", subtitle: "Nghe phát âm rồi chọn nghĩa đúng",
                            icon: "ear.fill", color: .teal) { sheet = .listening }
                    modeRow("Luyện thanh điệu", subtitle: "Phân biệt 4 thanh bằng tai",
                            icon: "waveform", color: .orange) { sheet = .tones }
                }
                Section("Tiến độ theo chủ đề") {
                    ForEach(model.topics, id: \.self) { topic in
                        topicRow(topic)
                    }
                }
            }
            .navigationTitle("Ôn tập")
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .quiz(let pool):
                QuizView(pool: pool, all: model.phrases) { model.reloadProgress() }
            case .listening:
                QuizView(pool: model.phrases, all: model.phrases, mode: .listening) { model.reloadProgress() }
            case .flashcards:
                FlashcardView(pool: model.phrases) { model.reloadProgress() }
            case .tones:
                ToneDrillView(pool: model.phrases) { model.reloadProgress() }
            }
        }
    }

    // MARK: Chuỗi ngày

    private var streakCard: some View {
        let streak = ProgressStore.currentStreak
        return HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(streak > 0 ? .orange : .gray)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) ngày liên tiếp")
                    .font(.title3.weight(.bold))
                Text(ProgressStore.studiedToday ? "Hôm nay bạn đã học rồi, giữ vững nhé" : "Ôn một lượt để giữ chuỗi hôm nay")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Mục tiêu và biểu đồ tuần

    private var todayCard: some View {
        let today = ProgressStore.count(on: Date())
        let goal = max(dailyGoal, 1)
        let reached = today >= goal
        let week = lastSevenDays()
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: min(1, Double(today) / Double(goal)))
                        .stroke(reached ? Color.green : Color.accentColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(today)").font(.title2.weight(.bold))
                        Text("/ \(goal)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    Text(reached ? "Đạt mục tiêu hôm nay!" : "Còn \(goal - today) câu nữa")
                        .font(.headline)
                    Text("Mục tiêu \(goal) câu mỗi ngày. Đổi trong Cài đặt.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            Chart {
                ForEach(week) { item in
                    BarMark(x: .value("Ngày", item.date, unit: .day),
                            y: .value("Số câu", item.count))
                        .foregroundStyle(item.count >= goal ? Color.green : Color.accentColor)
                        .cornerRadius(4)
                }
                RuleMark(y: .value("Mục tiêu", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Color.secondary)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .frame(height: 110)
            .accessibilityLabel("Số câu đã làm trong 7 ngày gần nhất")
        }
        .padding(.vertical, 4)
    }

    private func lastSevenDays() -> [DayStat] {
        (0..<7).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())
        }.map { DayStat(date: $0, count: ProgressStore.count(on: $0)) }
    }

    // MARK: Từ cần ôn

    private var dueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 24) {
                stat(value: model.dueCount, label: "Cần ôn lại")
                stat(value: model.newCount, label: "Từ mới")
                stat(value: model.learned.count, label: "Đã thuộc")
            }
            Button {
                sheet = .quiz(model.phrases)
            } label: {
                Label(model.dueCount > 0 ? "Ôn \(model.dueCount) từ đến hạn" : "Học thêm từ mới",
                      systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            Text(model.dueCount > 0
                 ? "Mỗi lượt 10 câu: từ đến hạn ôn trước, rồi đến từ mới."
                 : "Hôm nay bạn đã ôn hết từ đến hạn. Học thêm vài từ mới nhé.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.title2.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Các dòng

    private func modeRow(_ title: String, subtitle: String, icon: String, color: Color,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.medium))
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .tint(.primary)
    }

    private func topicRow(_ topic: String) -> some View {
        let words = model.phrases.filter { $0.topic == topic }
        let done = words.filter { model.learned.contains($0.id) }.count
        return Button {
            sheet = .quiz(words)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(topic).font(.body.weight(.medium))
                    Spacer()
                    Text("\(done)/\(words.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                ProgressView(value: Double(done), total: Double(max(words.count, 1)))
                    .accessibilityLabel("Đã thuộc \(done) trên \(words.count) từ")
            }
            .padding(.vertical, 2)
        }
        .tint(.primary)
    }
}
