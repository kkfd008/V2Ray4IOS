import Foundation
import NetworkExtension

/// VPN 管理器，封装 NETunnelProviderManager 操作
@MainActor
final class VPNManager: ObservableObject {
    static let shared = VPNManager()

    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case disconnecting

        var displayName: String {
            switch self {
            case .disconnected:  return "已断开"
            case .connecting:    return "连接中…"
            case .connected:     return "已连接"
            case .disconnecting: return "断开中…"
            }
        }
    }

    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectionStartTime: Date?
    @Published var uploadBytes: Int64 = 0
    @Published var downloadBytes: Int64 = 0
    @Published var currentSpeed: String = "0 B/s"

    private var providerManager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?

    private let storage = StorageService.shared

    // MARK: - Init

    private init() {
        loadProvider()
        observeStatus()
    }

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Provider Management

    func loadProvider() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                print("Failed to load VPN managers: \(error)")
                return
            }
            self.providerManager = managers?.first ?? self.createProvider()
            self.updateState(from: self.providerManager?.connection.status ?? .invalid)
        }
    }

    private func createProvider() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.v2ray.client.packet-tunnel"
        proto.serverAddress = "V2Ray"
        manager.protocolConfiguration = proto
        manager.localizedDescription = "V2Ray"
        manager.isEnabled = true
        return manager
    }

    // MARK: - Connect / Disconnect

    func connect(config: ServerConfig) {
        guard let manager = providerManager else { return }

        // 将选中配置写入共享存储
        if let data = try? JSONEncoder().encode(config) {
            SharedConstants.sharedDefaults.set(data, forKey: SharedConstants.selectedServerKey)
        }

        // 保存路由模式
        SharedConstants.sharedDefaults.set(storage.routingMode.rawValue, forKey: SharedConstants.routingModeKey)

        // 保存连接开始时间
        let startTime = Date()
        SharedConstants.sharedDefaults.set(startTime, forKey: SharedConstants.connectionStartTimeKey)
        connectionStartTime = startTime

        manager.saveToPreferences { [weak self] error in
            if let error = error {
                print("Failed to save VPN preferences: \(error)")
                return
            }
            manager.loadFromPreferences { _ in
                do {
                    try manager.connection.startVPNTunnel()
                    self?.connectionState = .connecting
                } catch {
                    print("Failed to start VPN tunnel: \(error)")
                }
            }
        }
    }

    func disconnect() {
        guard let manager = providerManager else { return }
        connectionState = .disconnecting
        manager.connection.stopVPNTunnel()
    }

    // MARK: - Status Observation

    private func observeStatus() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            self?.updateState(from: connection.status)
        }
    }

    private func updateState(from status: NEVPNStatus) {
        switch status {
        case .invalid, .disconnected:
            connectionState = .disconnected
            connectionStartTime = nil
            currentSpeed = "0 B/s"
        case .connecting:
            connectionState = .connecting
        case .connected:
            connectionState = .connected
            if connectionStartTime == nil {
                connectionStartTime = SharedConstants.sharedDefaults.object(forKey: SharedConstants.connectionStartTimeKey) as? Date
            }
        case .disconnecting:
            connectionState = .disconnecting
        case .reasserting:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Traffic Stats

    func updateTrafficStats() {
        let defaults = SharedConstants.sharedDefaults
        let newUpload = Int64(defaults.integer(forKey: SharedConstants.trafficUploadKey))
        let newDownload = Int64(defaults.integer(forKey: SharedConstants.trafficDownloadKey))

        let uploadDelta = newUpload - uploadBytes
        let downloadDelta = newDownload - downloadBytes

        uploadBytes = newUpload
        downloadBytes = newDownload

        // 计算速度 (每秒)
        let speed = uploadDelta + downloadDelta
        currentSpeed = formatBytes(speed) + "/s"
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }
}