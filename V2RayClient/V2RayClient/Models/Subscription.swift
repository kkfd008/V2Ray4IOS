import Foundation

/// 订阅链接模型
struct Subscription: Codable, Identifiable, Equatable {
    let id: UUID
    var url: String
    var name: String
    var lastUpdated: Date?
    var serverCount: Int

    init(
        id: UUID = UUID(),
        url: String,
        name: String = "",
        lastUpdated: Date? = nil,
        serverCount: Int = 0
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.lastUpdated = lastUpdated
        self.serverCount = serverCount
    }

    var lastUpdatedDisplay: String {
        guard let date = lastUpdated else { return "从未更新" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}