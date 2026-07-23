import Foundation

/// 数据持久化服务，封装 App Group UserDefaults 的读写
final class StorageService: ObservableObject {
    static let shared = StorageService()

    private let defaults = SharedConstants.sharedDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Servers

    @Published var servers: [ServerConfig] = []

    func loadServers() {
        guard let data = defaults.data(forKey: SharedConstants.serversKey) else {
            servers = []
            return
        }
        do {
            servers = try decoder.decode([ServerConfig].self, from: data)
        } catch {
            print("Failed to load servers: \(error)")
            servers = []
        }
    }

    func saveServers() {
        do {
            let data = try encoder.encode(servers)
            defaults.set(data, forKey: SharedConstants.serversKey)
        } catch {
            print("Failed to save servers: \(error)")
        }
    }

    var selectedServer: ServerConfig? {
        servers.first(where: { $0.isSelected })
    }

    func selectServer(_ config: ServerConfig) {
        for i in servers.indices {
            servers[i].isSelected = (servers[i].id == config.id)
        }
        saveServers()
        // 同步写入共享存储供 Extension 读取
        if let data = try? encoder.encode(config) {
            defaults.set(data, forKey: SharedConstants.selectedServerKey)
        }
    }

    // MARK: - Subscriptions

    @Published var subscriptions: [Subscription] = []

    func loadSubscriptions() {
        guard let data = defaults.data(forKey: SharedConstants.subscriptionsKey) else {
            subscriptions = []
            return
        }
        do {
            subscriptions = try decoder.decode([Subscription].self, from: data)
        } catch {
            print("Failed to load subscriptions: \(error)")
            subscriptions = []
        }
    }

    func saveSubscriptions() {
        do {
            let data = try encoder.encode(subscriptions)
            defaults.set(data, forKey: SharedConstants.subscriptionsKey)
        } catch {
            print("Failed to save subscriptions: \(error)")
        }
    }

    // MARK: - Routing Mode

    @Published var routingMode: RoutingMode = .global

    func loadRoutingMode() {
        guard let raw = defaults.string(forKey: SharedConstants.routingModeKey),
              let mode = RoutingMode(rawValue: raw) else {
            routingMode = .global
            return
        }
        routingMode = mode
    }

    func saveRoutingMode() {
        defaults.set(routingMode.rawValue, forKey: SharedConstants.routingModeKey)
    }

    // MARK: - Whitelist / Blacklist

    @Published var whitelistEntries: [WhitelistBlacklistEntry] = []
    @Published var blacklistEntries: [WhitelistBlacklistEntry] = []

    func loadWhitelistEntries() {
        guard let data = defaults.data(forKey: SharedConstants.whitelistEntriesKey) else {
            whitelistEntries = []
            return
        }
        do {
            whitelistEntries = try decoder.decode([WhitelistBlacklistEntry].self, from: data)
        } catch {
            whitelistEntries = []
        }
    }

    func saveWhitelistEntries() {
        if let data = try? encoder.encode(whitelistEntries) {
            defaults.set(data, forKey: SharedConstants.whitelistEntriesKey)
        }
    }

    func loadBlacklistEntries() {
        guard let data = defaults.data(forKey: SharedConstants.blacklistEntriesKey) else {
            blacklistEntries = []
            return
        }
        do {
            blacklistEntries = try decoder.decode([WhitelistBlacklistEntry].self, from: data)
        } catch {
            blacklistEntries = []
        }
    }

    func saveBlacklistEntries() {
        if let data = try? encoder.encode(blacklistEntries) {
            defaults.set(data, forKey: SharedConstants.blacklistEntriesKey)
        }
    }

    // MARK: - GFWList

    var gfwlistLastUpdated: Date? {
        get { defaults.object(forKey: SharedConstants.gfwlistLastUpdatedKey) as? Date }
        set { defaults.set(newValue, forKey: SharedConstants.gfwlistLastUpdatedKey) }
    }

    // MARK: - Traffic

    var trafficUpload: Int64 {
        get { Int64(defaults.integer(forKey: SharedConstants.trafficUploadKey)) }
        set { defaults.set(newValue, forKey: SharedConstants.trafficUploadKey) }
    }

    var trafficDownload: Int64 {
        get { Int64(defaults.integer(forKey: SharedConstants.trafficDownloadKey)) }
        set { defaults.set(newValue, forKey: SharedConstants.trafficDownloadKey) }
    }

    // MARK: - Init

    func loadAll() {
        loadServers()
        loadSubscriptions()
        loadRoutingMode()
        loadWhitelistEntries()
        loadBlacklistEntries()
    }
}