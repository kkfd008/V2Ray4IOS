import SwiftUI

/// VMess 配置视图 — 蓝色主题
struct VMessConfigView: View {
    let onSave: (ServerConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var port = "443"
    @State private var uuid = ""
    @State private var alterId = "0"
    @State private var security = "auto"
    @State private var transport: ServerConfig.TransportType = .ws
    @State private var tlsEnabled = true

    let accentColor = Color(hex: "4da6ff")

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
                        Text("VMess 配置")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "e4e8ee"))
                        Spacer().frame(width: 30)
                    }
                    .padding(.bottom, 16)

                    // 服务端信息
                    ConfigSection(title: "服务端信息", accent: accentColor) {
                        ConfigField(label: "备注", text: $name, placeholder: "例如：US West")
                        ConfigRow {
                            ConfigField(label: "地址", text: $address, placeholder: "server.com")
                            ConfigField(label: "端口", text: $port, placeholder: "443")
                        }
                    }

                    // 认证
                    ConfigSection(title: "认证", accent: accentColor) {
                        ConfigField(label: "UUID", text: $uuid, placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
                        ConfigRow {
                            ConfigField(label: "Alter ID", text: $alterId, placeholder: "0")
                            ConfigPicker(label: "Security", selection: $security, options: ["auto", "aes-128-gcm", "chacha20-poly1305", "none"])
                        }
                    }

                    // 传输
                    ConfigSection(title: "传输", accent: accentColor) {
                        ConfigPicker(label: "传输协议", selection: transportBinding, options: ["ws", "tcp", "grpc", "h2"])
                        ToggleRow(label: "TLS", isOn: $tlsEnabled)
                    }

                    // 保存
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
            protocolType: .vmess,
            protocolSpecific: .vmess(.init(uuid: uuid, alterId: Int(alterId) ?? 0, security: security, tlsEnabled: tlsEnabled)),
            transport: transport
        )
        onSave(config)
    }
}