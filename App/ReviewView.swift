import SwiftUI

/// Tab "Ôn tập": chuỗi ngày học, từ cần ôn hôm nay, tiến độ theo chủ đề
struct ReviewView: View {
    @EnvironmentObject private var model: AppModel
    @State private var quizPool: [Phrase] = []
    @State private var isQuizzing = false

    var body: some View {
        NavigationStack {
            List {
                Section { streakCard }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 24) {
                            stat(value: model.dueCount, label: "Cần ôn lại")
                            stat(value: model.newCount, label: "Từ mới")
                            stat(value: model.learned.count, label: "Đã thuộc")
                        }
                        Button {
                            start(model.phrases)
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

                Section("Tiến độ theo chủ đề") {
                    ForEach(model.topics, id: \.self) { topic in
                        let words = model.phrases.filter { $0.topic == topic }
                        let done = words.filter { model.learned.contains($0.id) }.count
                        Button {
                            start(words)
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
                            }
                            .padding(.vertical, 2)
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Ôn tập")
        }
        .sheet(isPresented: $isQuizzing) {
            QuizView(pool: quizPool, all: model.phrases) { model.reloadProgress() }
        }
    }

    private var streakCard: some View {
        let streak = ProgressStore.currentStreak
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
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
            HStack {
                ForEach(lastSevenDays(), id: \.self) { day in
                    let studied = ProgressStore.didStudy(on: day)
                    VStack(spacing: 4) {
                        Image(systemName: studied ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(studied ? Color.orange : Color.secondary.opacity(0.4))
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.title2.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lastSevenDays() -> [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
    }

    private func start(_ pool: [Phrase]) {
        quizPool = pool
        isQuizzing = true
    }
}
