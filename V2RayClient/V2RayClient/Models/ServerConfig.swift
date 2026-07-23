import Foundation

/// 服务器配置模型，使用 enum with associated values 区分各协议特有字段
struct ServerConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var port: Int
    var protocolType: ProtocolType
    var protocolSpecific: ProtocolSpecific

    var transport: TransportType
    var transportSettings: TransportSettings

    var isSelected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        port: Int,
        protocolType: ProtocolType,
        protocolSpecific: ProtocolSpecific,
        transport: TransportType = .tcp,
        transportSettings: TransportSettings = .init(),
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
        self.protocolType = protocolType
        self.protocolSpecific = protocolSpecific
        self.transport = transport
        self.transportSettings = transportSettings
        self.isSelected = isSelected
    }

    /// 协议特有字段
    enum ProtocolSpecific: Codable, Equatable {
        case vmess(VMessConfig)
        case vless(VLESSConfig)
        case trojan(TrojanConfig)
        case shadowsocks(ShadowsocksConfig)

        // MARK: - Codable
        enum CodingKeys: String, CodingKey {
            case type, config
        }
        private enum ConfigType: String, Codable { case vmess, vless, trojan, shadowsocks }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ConfigType.self, forKey: .type)
            switch type {
            case .vmess:       self = .vmess(try container.decode(VMessConfig.self, forKey: .config))
            case .vless:       self = .vless(try container.decode(VLESSConfig.self, forKey: .config))
            case .trojan:      self = .trojan(try container.decode(TrojanConfig.self, forKey: .config))
            case .shadowsocks: self = .shadowsocks(try container.decode(ShadowsocksConfig.self, forKey: .config))
            }
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .vmess(let c):       try container.encode(ConfigType.vmess, forKey: .type); try container.encode(c, forKey: .config)
            case .vless(let c):       try container.encode(ConfigType.vless, forKey: .type); try container.encode(c, forKey: .config)
            case .trojan(let c):      try container.encode(ConfigType.trojan, forKey: .type); try container.encode(c, forKey: .config)
            case .shadowsocks(let c): try container.encode(ConfigType.shadowsocks, forKey: .type); try container.encode(c, forKey: .config)
            }
        }
    }

    // MARK: - Protocol Configs

    struct VMessConfig: Codable, Equatable {
        var uuid: String
        var alterId: Int
        var security: String
        var tlsEnabled: Bool

        init(uuid: String = "", alterId: Int = 0, security: String = "auto", tlsEnabled: Bool = true) {
            self.uuid = uuid
            self.alterId = alterId
            self.security = security
            self.tlsEnabled = tlsEnabled
        }
    }

    struct VLESSConfig: Codable, Equatable {
        var uuid: String
        var flow: String
        var encryption: String
        var realityEnabled: Bool

        init(uuid: String = "", flow: String = "none", encryption: String = "none", realityEnabled: Bool = true) {
            self.uuid = uuid
            self.flow = flow
            self.encryption = encryption
            self.realityEnabled = realityEnabled
        }
    }

    struct TrojanConfig: Codable, Equatable {
        var password: String
        var tlsEnabled: Bool

        init(password: String = "", tlsEnabled: Bool = true) {
            self.password = password
            self.tlsEnabled = tlsEnabled
        }
    }

    struct ShadowsocksConfig: Codable, Equatable {
        var method: String
        var password: String

        init(method: String = "aes-256-gcm", password: String = "") {
            self.method = method
            self.password = password
        }
    }

    // MARK: - Transport

    enum TransportType: String, Codable, CaseIterable {
        case tcp, ws, grpc, h2
        var displayName: String { rawValue }
    }

    struct TransportSettings: Codable, Equatable {
        var wsPath: String
        var wsHeaders: [String: String]
        var grpcServiceName: String

        init(wsPath: String = "/", wsHeaders: [String: String] = [:], grpcServiceName: String = "") {
            self.wsPath = wsPath
            self.wsHeaders = wsHeaders
            self.grpcServiceName = grpcServiceName
        }
    }
}