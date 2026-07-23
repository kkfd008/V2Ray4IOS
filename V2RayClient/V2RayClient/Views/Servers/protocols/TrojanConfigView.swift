import SwiftUI

/// Trojan 配置视图 — 橙色主题
struct TrojanConfigView: View {
    let onSave: (ServerConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var port = "443"
    @State private var password = ""
    @State private var transport: ServerConfig.TransportType = .tcp
    @State private var tlsEnabled = true

    let accentColor = Color(hex: "f0a040")

    var body: some View {
        ZStack {
            Color(hex: "0b0f14").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button("← 返回") { dismiss() }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "00e5a0"))
                        Spacer()
                        Text("Trojan 配置")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "e4e8ee"))
                        Spacer().frame(width: 30)
                    }
                    .padding(.bottom, 16)

                    // 顶部横幅
                    HStack(spacing: 12) {
                        Text("🐴").font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trojan")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentColor)
                            Text("TLS 隧道伪装 HTTPS 流量")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "4a5462"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(accentColor.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.12), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 14)

                    ConfigField(label: "备注", text: $name, placeholder: "例如：HK Azure")
                    ConfigRow {
                        ConfigField(label: "地址", text: $address, placeholder: "server.com")
                        ConfigField(label: "端口", text: $port, placeholder: "443")
                    }
                    SecureConfigField(label: "密码", text: $password, placeholder: "your-password")

                    ConfigSection(title: "传输配置", accent: accentColor) {
                        ConfigPicker(label: "传输协议", selection: transportBinding, options: ["tcp", "ws", "grpc"])
                        ToggleRow(label: "TLS", isOn: $tlsEnabled)
                    }

                    Button(action: save) {
                        Text("保存配置")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var transportBinding: Binding<String> {
        Binding(get: { transport.rawValue }, set: { transport = ServerConfig.TransportType(rawValue: $0) ?? .tcp })
    }

    private func save() {
        let config = ServerConfig(
            name: name,
            address: address,
            port: Int(port) ?? 443,
            protocolType: .trojan,
            protocolSpecific: .trojan(.init(password: password, tlsEnabled: tlsEnabled)),
            transport: transport
        )
        onSave(config)
    }
}