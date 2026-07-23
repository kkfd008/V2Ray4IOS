import SwiftUI

/// 全局应用状态
@MainActor
final class AppState: ObservableObject {
    let storage = StorageService.shared
    let vpnManager = VPNManager.shared

    @Published var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, servers, subscriptions, routing

        var icon: String {
            switch self {
            case .home:          return "house.fill"
            case .servers:       return "list.bullet"
            case .subscriptions: return "arrow.down.circle"
            case .routing:       return "arrow.triangle.branch"
            }
        }

        var title: String {
            switch self {
            case .home:          return "首页"
            case .servers:       return "服务器"
            case .subscriptions: return "订阅"
            case .routing:       return "路由"
            }
        }
    }
}