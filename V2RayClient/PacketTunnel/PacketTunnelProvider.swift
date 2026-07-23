import Foundation
import NetworkExtension

/// NEPacketTunnelProvider 子类
/// 在 VPN 隧道内启动 Xray-core 本地代理并路由流量
class PacketTunnelProvider: NEPacketTunnelProvider {
    private let bridge = XrayBridge.shared
    private var trafficTimer: Timer?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // 1. 从共享存储读取选中配置
        guard let configData = SharedConstants.sharedDefaults.data(forKey: SharedConstants.selectedServerKey),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: configData) else {
            completionHandler(NSError(domain: "PacketTunnel", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No server config found"]))
            return
        }

        // 2. 生成 V2Ray JSON 配置
        let configJSON = ConfigGenerator.generate(from: config)

        // 3. 获取 asset 目录 (geoip.dat / geosite.dat)
        let assetDir = Bundle.main.resourcePath ?? ""

        // 4. 启动 Xray-core
        let error = bridge.start(configJSON: configJSON, assetDir: assetDir)
        if !error.isEmpty {
            completionHandler(NSError(domain: "PacketTunnel", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Xray start failed: \(error)"]))
            return
        }

        // 5. 配置网络设置
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        settings.mtu = 1500

        // 读取路由模式
        let routingModeStr = SharedConstants.sharedDefaults.string(forKey: SharedConstants.routingModeKey) ?? "global"
        let routingMode = RoutingMode(rawValue: routingModeStr) ?? .global

        switch routingMode {
        case .global:
            // 全局代理：所有流量走隧道
            settings.ipv4Settings = NEIPv4Settings(
                addresses: ["10.0.0.2"],
                subnetMasks: ["255.255.255.0"]
            )
            settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]

        case .pac:
            // PAC 模式：系统代理设置
            settings.ipv4Settings = NEIPv4Settings(
                addresses: ["10.0.0.2"],
                subnetMasks: ["255.255.255.0"]
            )
            settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]

            let proxySettings = NEProxySettings()
            proxySettings.exceptionList = []
            proxySettings.httpEnabled = true
            proxySettings.httpServer = NEProxyServer(
                address: bridge.localHost,
                port: bridge.httpPort
            )
            proxySettings.httpsEnabled = true
            proxySettings.httpsServer = NEProxyServer(
                address: bridge.localHost,
                port: bridge.httpPort
            )
            proxySettings.socksEnabled = true
            proxySettings.socksServer = NEProxyServer(
                address: bridge.localHost,
                port: bridge.socksPort
            )

            // 生成 PAC 脚本
            let pacJS = PACGenerator.generate(
                whitelist: StorageService.shared.whitelistEntries,
                blacklist: StorageService.shared.blacklistEntries
            )
            proxySettings.proxyAutoConfigurationJavaScript = pacJS

            settings.proxySettings = proxySettings
        }

        // 6. 应用网络设置
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                self?.bridge.stop()
                completionHandler(error)
                return
            }

            // 7. 启动流量统计定时器
            self?.startTrafficMonitoring()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        trafficTimer?.invalidate()
        trafficTimer = nil
        bridge.stop()
        completionHandler()
    }

    // MARK: - Traffic Monitoring

    private func startTrafficMonitoring() {
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let stats = self?.bridge.getTrafficStats() ?? (0, 0)
            let defaults = SharedConstants.sharedDefaults
            defaults.set(stats.upload, forKey: SharedConstants.trafficUploadKey)
            defaults.set(stats.download, forKey: SharedConstants.trafficDownloadKey)
        }
    }
}