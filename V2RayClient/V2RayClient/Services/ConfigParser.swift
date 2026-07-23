import Foundation

/// 协议链解析器
/// 支持 vmess:// / vless:// / trojan:// / ss:// 格式
enum ConfigParser {
    /// 解析协议链 URL，返回 ServerConfig
    static func parse(url: URL) -> ServerConfig? {
        guard let scheme = url.scheme?.lowercased(),
              let protoType = ProtocolType(rawValue: scheme) else {
            return nil
        }

        switch protoType {
        case .vmess:       return parseVMess(url: url)
        case .vless:       return parseVLESS(url: url)
        case .trojan:      return parseTrojan(url: url)
        case .shadowsocks: return parseShadowsocks(url: url)
        }
    }

    /// 解析字符串，尝试匹配协议链格式
    static func parse(string: String) -> ServerConfig? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }
        return parse(url: url)
    }

    /// 批量解析多行字符串
    static func parseMultiple(_ content: String) -> [ServerConfig] {
        content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { parse(string: $0) }
    }

    // MARK: - VMess

    /// vmess://base64(json)
    private static func parseVMess(url: URL) -> ServerConfig? {
        // vmess:// base64encoded
        let encoded = url.host ?? ""
        guard let decoded = Data(base64Encoded: encoded.addingBase64Padding),
              let json = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any] else {
            return nil
        }

        let name = json["ps"] as? String ?? json["remark"] as? String ?? ""
        let address = json["add"] as? String ?? ""
        let port = json["port"] as? Int ?? 443
        let uuid = json["id"] as? String ?? ""
        let alterId = json["aid"] as? Int ?? 0
        let security = json["scy"] as? String ?? "auto"
        let tls = (json["tls"] as? String) == "tls"

        let transport: ServerConfig.TransportType = {
            switch json["net"] as? String {
            case "ws": return .ws
            case "grpc": return .grpc
            case "h2": return .h2
            default: return .tcp
            }
        }()

        let settings = ServerConfig.TransportSettings(
            wsPath: json["path"] as? String ?? "/",
            wsHeaders: (json["host"] as? String).map { ["Host": $0] } ?? [:]
        )

        return ServerConfig(
            name: name,
            address: address,
            port: port,
            protocolType: .vmess,
            protocolSpecific: .vmess(.init(uuid: uuid, alterId: alterId, security: security, tlsEnabled: tls)),
            transport: transport,
            transportSettings: settings
        )
    }

    // MARK: - VLESS

    /// vless://uuid@host:port?params
    private static func parseVLESS(url: URL) -> ServerConfig? {
        let uuid = url.user ?? ""
        guard let host = url.host else { return nil }
        let port = url.port ?? 443

        let params = url.queryItems

        let name = params["remark"] ?? params["ps"] ?? ""
        let flow = params["flow"] ?? "none"
        let encryption = params["encryption"] ?? "none"
        let reality = params["security"] == "reality"

        let transport: ServerConfig.TransportType = {
            switch params["type"] {
            case "ws": return .ws
            case "grpc": return .grpc
            case "h2": return .h2
            default: return .tcp
            }
        }()

        return ServerConfig(
            name: name,
            address: host,
            port: port,
            protocolType: .vless,
            protocolSpecific: .vless(.init(uuid: uuid, flow: flow, encryption: encryption, realityEnabled: reality)),
            transport: transport,
            transportSettings: .init(wsPath: params["path"] ?? "/")
        )
    }

    // MARK: - Trojan

    /// trojan://password@host:port?params
    private static func parseTrojan(url: URL) -> ServerConfig? {
        let password = url.user ?? ""
        guard let host = url.host else { return nil }
        let port = url.port ?? 443

        let params = url.queryItems
        let name = params["remark"] ?? params["ps"] ?? ""
        let tls = params["security"] == "tls" || params["allowInsecure"] == "1"

        let transport: ServerConfig.TransportType = {
            switch params["type"] {
            case "ws": return .ws
            case "grpc": return .grpc
            default: return .tcp
            }
        }()

        return ServerConfig(
            name: name,
            address: host,
            port: port,
            protocolType: .trojan,
            protocolSpecific: .trojan(.init(password: password, tlsEnabled: tls)),
            transport: transport,
            transportSettings: .init(wsPath: params["path"] ?? "/")
        )
    }

    // MARK: - Shadowsocks

    /// ss://base64(method:password@host:port) or ss://base64(method:password)@host:port
    private static func parseShadowsocks(url: URL) -> ServerConfig? {
        let userInfo: String
        let host: String
        let port: Int

        if let decodedHost = url.host, !decodedHost.isEmpty {
            // ss://base64(method:password)@host:port
            userInfo = url.user ?? ""
            host = decodedHost
            port = url.port ?? 8388
        } else {
            // ss://base64(method:password@host:port)
            let base64Part = url.absoluteString
                .replacingOccurrences(of: "ss://", with: "")
                .components(separatedBy: "#").first ?? ""
            guard let decoded = Data(base64Encoded: base64Part.addingBase64Padding),
                  let decodedStr = String(data: decoded, encoding: .utf8) else {
                return nil
            }
            // method:password@host:port
            let parts = decodedStr.components(separatedBy: "@")
            userInfo = parts.first ?? ""
            let hostPort = parts.last?.components(separatedBy: ":") ?? []
            host = hostPort.first ?? ""
            port = Int(hostPort.last ?? "8388") ?? 8388
        }

        let methodPassword = userInfo.components(separatedBy: ":")
        let method = methodPassword.first ?? "aes-256-gcm"
        let password = methodPassword.count > 1 ? methodPassword.dropFirst().joined(separator: ":") : ""

        let name = (url.fragment?.removingPercentEncoding) ?? ""

        return ServerConfig(
            name: name,
            address: host,
            port: port,
            protocolType: .shadowsocks,
            protocolSpecific: .shadowsocks(.init(method: method, password: password))
        )
    }
}

// MARK: - URL Query Items Helper

extension URL {
    var queryItems: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return [:] }
        var dict: [String: String] = [:]
        for item in items { dict[item.name] = item.value }
        return dict
    }
}

// MARK: - Base64 Padding Helper

extension String {
    func addingBase64Padding() -> String {
        let remainder = count % 4
        if remainder == 0 { return self }
        return self + String(repeating: "=", count: 4 - remainder)
    }
}