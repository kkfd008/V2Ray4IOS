import Foundation

/// 路由模式
enum RoutingMode: String, Codable, CaseIterable {
    case global
    case pac

    var displayName: String {
        switch self {
        case .global: return "全局代理"
        case .pac:    return "PAC 模式"
        }
    }

    var description: String {
        switch self {
        case .global: return "所有流量通过代理转发"
        case .pac:    return "基于 GFWList 黑白名单自动分流"
        }
    }
}