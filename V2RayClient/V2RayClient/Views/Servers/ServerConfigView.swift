import SwiftUI

/// 服务器配置视图容器，根据协议类型分发到对应子视图
struct ServerConfigView: View {
    let protocolType: ProtocolType
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch protocolType {
            case .vmess:       VMessConfigView(onSave: { saveConfig($0) })
            case .vless:       VLESSConfigView(onSave: { saveConfig($0) })
            case .trojan:      TrojanConfigView(onSave: { saveConfig($0) })
            case .shadowsocks: SSConfigView(onSave: { saveConfig($0) })
            }
        }
    }

    private func saveConfig(_ config: ServerConfig) {
        appState.storage.servers.append(config)
        appState.storage.saveServers()
        dismiss()
    }
}