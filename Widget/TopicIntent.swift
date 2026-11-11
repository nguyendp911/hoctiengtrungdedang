import AppIntents
import WidgetKit

/// Một chủ đề để chọn khi sửa widget. id rỗng = tất cả chủ đề.
struct TopicEntity: AppEntity {
    static let allID = ""

    let id: String

    var name: String { id == Self.allID ? "Tất cả chủ đề" : id }
    /// nil khi chọn tất cả, dùng thẳng cho PhraseStore
    var filter: String? { id == Self.allID ? nil : id }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Chủ đề"
    static var defaultQuery = TopicQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

struct TopicQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TopicEntity] {
        identifiers.map(TopicEntity.init)
    }

    func suggestedEntities() async throws -> [TopicEntity] {
        await PhraseStore.refreshIfStale()
        let topics = PhraseStore.topics(in: PhraseStore.loadForWidget())
        return [TopicEntity(id: TopicEntity.allID)] + topics.map(TopicEntity.init)
    }

    func defaultResult() async -> TopicEntity? {
        TopicEntity(id: TopicEntity.allID)
    }
}

struct SelectTopicIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Chọn chủ đề"
    static var description = IntentDescription("Widget chỉ hiện từ thuộc chủ đề này.")

    @Parameter(title: "Chủ đề")
    var topic: TopicEntity?
}
