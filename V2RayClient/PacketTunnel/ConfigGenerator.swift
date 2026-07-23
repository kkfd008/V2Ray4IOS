import Foundation
import NetworkExtension

/// JSON 配置生成器，将 ServerConfig 转换为 V2Ray JSON 配置字符串
enum ConfigGenerator {
    /// 根据 ServerConfig 生成 V2Ray JSON 配置
    static func generate(from config: ServerConfig) -> String {
        let outbound = buildOutbound(config: config)
        let routing = buildRouting()
        let inbounds = buildInbounds()

        let json: [String: Any] = [
            "inbounds": inbounds,
            "outbounds": [outbound, buildDirectOutbound()],
            "routing": routing,
            "log": ["loglevel": "warning"]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    // MARK: - Inbounds

    private static func buildInbounds() -> [[String: Any]] {
        let socksInbound: [String: Any] = [
            "tag": "socks-in",
            "port": 10808,
            "protocol": "socks",
            "settings": ["auth": "noaccount", "udp": true],
            "sniffing": ["enabled": true, "destOverride": ["http", "tls"]]
        ]
        let httpInbound: [String: Any] = [
            "tag": "http-in",
            "port": 10809,
            "protocol": "http"
        ]
        return [socksInbound, httpInbound]
    }

    // MARK: - Outbound

    private static func buildOutbound(config: ServerConfig) -> [String: Any] {
        var outbound: [String: Any] = [
            "tag": "proxy",
            "protocol": config.protocolType.rawValue,
            "settings": buildProtocolSettings(config: config),
            "streamSettings": buildStreamSettings(config: config)
        ]
        // 添加 mux 设置
        outbound["mux"] = ["enabled": true]
        return outbound
    }

    private static func buildDirectOutbound() -> [String: Any] {
        ["tag": "direct", "protocol": "freedom"]
    }

    private static func buildProtocolSettings(config: ServerConfig) -> [String: Any] {
        var settings: [String: Any] = [:]

        switch config.protocolSpecific {
        case .vmess(let c):
            settings["vnext"] = [[
                "address": config.address,
                "port": config.port,
                "users": [[
                    "id": c.uuid,
                    "alterId": c.alterId,
                    "security": c.security
                ]]
            ]]
        case .vless(let c):
            settings["vnext"] = [[
                "address": config.address,
                "port": config.port,
                "users": [[
                    "id": c.uuid,
                    "flow": c.flow,
                    "encryption": c.encryption
                ]]
            ]]
        case .trojan(let c):
            settings["servers"] = [[
                "address": config.address,
                "port": config.port,
                "password": c.password
            ]]
        case .shadowsocks(let c):
            settings["servers"] = [[
                "address": config.address,
                "port": config.port,
                "method": c.method,
                "password": c.password
            ]]
        }
        return settings
    }

    private static func buildStreamSettings(config: ServerConfig) -> [String: Any] {
        var stream: [String: Any] = [
            "network": config.transport.rawValue,
            "security": "none"
        ]

        let tlsEnabled: Bool
        switch config.protocolSpecific {
        case .vmess(let c):   tlsEnabled = c.tlsEnabled
        case .vless(let c):   tlsEnabled = c.realityEnabled
        case .trojan(let c):  tlsEnabled = c.tlsEnabled
        case .shadowsocks:    tlsEnabled = false
        }

        if tlsEnabled {
            stream["security"] = "tls"
            stream["tlsSettings"] = ["serverName": config.address]
        }

        switch config.transport {
        case .ws:
            stream["wsSettings"] = [
                "path": config.transportSettings.wsPath,
                "headers": config.transportSettings.wsHeaders
            ]
        case .grpc:
            let serviceName = config.transportSettings.grpcServiceName.isEmpty
                ? "GunService" : config.transportSettings.grpcServiceName
            stream["grpcSettings"] = ["serviceName": serviceName]
        case .h2:
            stream["httpSettings"] = [
                "path": config.transportSettings.wsPath,
                "host": [config.address]
            ]
        case .tcp:
            if !config.transportSettings.wsHeaders.isEmpty {
                stream["tcpSettings"] = [
                    "header": ["type": "http", "request": ["headers": config.transportSettings.wsHeaders]]
                ]
            }
        }
        return stream
    }

    // MARK: - Routing

    private static func buildRouting() -> [String: Any] {
        [
            "domainStrategy": "IPIfNonMatch",
            "rules": [
                // 国内域名直连
                ["type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"],
                // 国内 IP 直连
                ["type": "field", "ip": ["geoip:cn", "geoip:private"], "outboundTag": "direct"],
                // 广告拦截
                ["type": "field", "domain": ["geosite:category-ads-all"], "outboundTag": "direct"]
            ]
        ]
    }
}