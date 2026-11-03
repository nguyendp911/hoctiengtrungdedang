import SwiftUI
import WidgetKit

struct PhraseEntry: TimelineEntry {
    let date: Date
    let phrase: Phrase
}

struct PhraseProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PhraseEntry {
        PhraseEntry(date: .now, phrase: .sample)
    }

    func snapshot(for configuration: SelectTopicIntent, in context: Context) async -> PhraseEntry {
        let list = PhraseStore.load()
        let topic = configuration.topic?.filter
        return PhraseEntry(date: .now, phrase: PhraseStore.phrase(at: .now, topic: topic, in: list))
    }

    func timeline(for configuration: SelectTopicIntent, in context: Context) async -> Timeline<PhraseEntry> {
        // Lấy từ mới trên GitHub (nếu bản đã lưu quá cũ), lỗi mạng thì dùng bản cũ
        await PhraseStore.refreshIfStale()
        let list = PhraseStore.load()
        let topic = configuration.topic?.filter

        // Lên lịch sẵn 24 câu cho 24 khung giờ tới, hết thì iOS gọi lại
        let start = PhraseStore.slotStart(for: .now)
        let entries = (0..<24).map { i in
            let date = start.addingTimeInterval(Double(i) * PhraseStore.rotationInterval)
            return PhraseEntry(date: date, phrase: PhraseStore.phrase(at: date, topic: topic, in: list))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct HanziWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PhraseEntry

    private var phrase: Phrase { entry.phrase }

    var body: some View {
        content
            .widgetURL(phrase.deepLink)
            .containerBackground(for: .widget) {
                if family == .systemSmall || family == .systemMedium {
                    Color(.systemBackground)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            // Dòng nhỏ phía trên đồng hồ
            Text("\(phrase.hanzi) · \(phrase.meaningVi)")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text(phrase.hanzi)
                    .font(.system(size: 22, weight: .bold))
                    .minimumScaleFactor(0.35)
                    .lineLimit(2)
                    .padding(4)
            }

        case .accessoryRectangular:
            // Ô chữ nhật dưới đồng hồ: chữ Hán lớn ở giữa, pinyin · cách đọc bên dưới.
            // Nghĩa nằm ở dòng nhỏ phía trên đồng hồ (accessoryInline).
            VStack(spacing: 1) {
                Text(phrase.hanzi)
                    .font(.system(size: 30, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .widgetAccentable()
                Text("\(phrase.pinyin) · \(phrase.readingVi)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
            }
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        default:
            // Widget màn hình chính
            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.hanzi)
                    .font(.system(size: 34, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                Text(phrase.pinyin)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                Text("Đọc: \(phrase.readingVi)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                HStack {
                    Text(phrase.meaningVi)
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.tint)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct HanziWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HanziWidget", intent: SelectTopicIntent.self, provider: PhraseProvider()) { entry in
            HanziWidgetView(entry: entry)
        }
        .configurationDisplayName("Hán Tự mỗi giờ")
        .description("Một từ/câu tiếng Trung theo chủ đề. Chạm để nghe phát âm, sửa widget để đổi chủ đề.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
            .systemMedium,
        ])
    }
}

@main
struct HanziWidgetBundle: WidgetBundle {
    var body: some Widget {
        HanziWidget()
    }
}

#Preview(as: .accessoryRectangular) {
    HanziWidget()
} timeline: {
    PhraseEntry(date: .now, phrase: .sample)
}
