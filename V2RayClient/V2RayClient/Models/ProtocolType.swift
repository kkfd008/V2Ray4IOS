import Foundation

/// V2Ray 支持的代理协议类型
enum ProtocolType: String, Codable, CaseIterable, Identifiable {
    case vmess
    case vless
    case trojan
    case shadowsocks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vmess:       return "VMess"
        case .vless:       return "VLESS"
        case .trojan:      return "Trojan"
        case .shadowsocks: return "Shadowsocks"
        }
    }

    var shortName: String {
        switch self {
        case .vmess:       return "VMess"
        case .vless:       return "VLESS"
        case .trojan:      return "Trojan"
        case .shadowsocks: return "SS"
        }
    }

    /// 协议链 URL scheme 前缀
    var scheme: String {
        switch self {
        case .vmess:       return "vmess"
        case .vless:       return "vless"
        case .trojan:      return "trojan"
        case .shadowsocks: return "ss"
        }
    }
}