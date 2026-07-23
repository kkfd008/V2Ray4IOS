import Foundation

/// App Group 共享常量，主 App 和 PacketTunnel Extension 共用
enum SharedConstants {
    static let appGroupID = "group.com.v2ray.client"

    // MARK: - UserDefaults Keys
    static let selectedServerKey = "selected_server_config"
    static let serversKey = "server_configs"
    static let subscriptionsKey = "subscriptions"
    static let routingModeKey = "routing_mode"
    static let whitelistEntriesKey = "whitelist_entries"
    static let blacklistEntriesKey = "blacklist_entries"
    static let gfwlistLastUpdatedKey = "gfwlist_last_updated"
    static let trafficUploadKey = "traffic_upload"
    static let trafficDownloadKey = "traffic_download"
    static let connectionStartTimeKey = "connection_start_time"

    // MARK: - Shared UserDefaults
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}