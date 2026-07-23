import SwiftUI

/// 首页
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var timerText = "00:00:00"
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 导航栏
                HStack {
                    Text("V2Ray")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "e4e8ee"))
                    Spacer()
                    Text("v2.0")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "4a5462"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)

                // 连接环
                ConnectRing(state: appState.vpnManager.connectionState) {
                    toggleConnection()
                }
                .padding(.bottom, 16)

                // 连接状态
                Text(appState.vpnManager.connectionState.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(statusColor)
                Text(timerText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "4a5462"))
                    .padding(.top, 4)
                    .opacity(appState.vpnManager.connectionState == .connected ? 1 : 0)

                // 流量统计
                StatsRow(
                    download: formatBytes(appState.vpnManager.downloadBytes),
                    upload: formatBytes(appState.vpnManager.uploadBytes),
                    speed: appState.vpnManager.currentSpeed
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // 当前服务器信息
                if let server = appState.storage.selectedServer {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(server.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "e4e8ee"))
                        HStack(spacing: 16) {
                            Text(server.protocolType.shortName)
                                .font(.system(size: 12, design: .monospaced))
                            Text("\(server.address):\(server.port)")
                                .font(.system(size: 12, design: .monospaced))
                            Text(server.transport.displayName.uppercased() + "+" + tlsText(server))
                                .font(.system(size: 12, design: .monospaced))
                        }
                        .foregroundColor(Color(hex: "4a5462"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(hex: "131820"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // 快捷入口
                HStack(spacing: 8) {
                    QuickActionButton(icon: "list.bullet", title: "服务器") {
                        appState.selectedTab = .servers
                    }
                    QuickActionButton(icon: "arrow.triangle.branch", title: "路由") {
                        appState.selectedTab = .routing
                    }
                    QuickActionButton(icon: "arrow.down.circle", title: "订阅") {
                        appState.selectedTab = .subscriptions
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .padding(.bottom, 20)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var statusColor: Color {
        switch appState.vpnManager.connectionState {
        case .connected:  return Color(hex: "00e5a0")
        case .connecting: return Color(hex: "f0a040")
        default:          return Color(hex: "4a5462")
        }
    }

    private func toggleConnection() {
        switch appState.vpnManager.connectionState {
        case .connected:
            appState.vpnManager.disconnect()
        case .disconnected:
            if let config = appState.storage.selectedServer {
                appState.vpnManager.connect(config: config)
            }
        default:
            break
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let start = appState.vpnManager.connectionStartTime,
               appState.vpnManager.connectionState == .connected {
                let elapsed = Int(Date().timeIntervalSince(start))
                let h = elapsed / 3600
                let m = (elapsed % 3600) / 60
                let s = elapsed % 60
                timerText = String(format: "%02d:%02d:%02d", h, m, s)
            } else {
                timerText = "00:00:00"
            }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }

    private func tlsText(_ config: ServerConfig) -> String {
        switch config.protocolSpecific {
        case .vmess(let c):   return c.tlsEnabled ? "TLS" : ""
        case .vless(let c):   return c.realityEnabled ? "Reality" : ""
        case .trojan(let c):  return c.tlsEnabled ? "TLS" : ""
        case .shadowsocks:    return ""
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(Color(hex: "7a8494"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(hex: "131820"))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}