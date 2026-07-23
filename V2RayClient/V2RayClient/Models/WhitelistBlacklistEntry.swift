import Foundation

/// PAC 白名单 / 黑名单条目
struct WhitelistBlacklistEntry: Codable, Identifiable, Equatable {
    enum EntryType: String, Codable {
        case whitelist
        case blacklist
    }

    let id: UUID
    var regex: String
    var type: EntryType

    init(id: UUID = UUID(), regex: String, type: EntryType) {
        self.id = id
        self.regex = regex
        self.type = type
    }
}