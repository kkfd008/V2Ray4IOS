import SwiftUI

/// Shadowsocks 配置视图 — 红色主题
struct SSConfigView: View {
    let onSave: (ServerConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var port = "8388"
    @State private var method = "aes-256-gcm"
    @State private var password = ""

    let accentColor = Color(hex: "ff4757")

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
                        Text("Shadowsocks 配置")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "e4e8ee"))
                        Spacer().frame(width: 30)
                    }
                    .padding(.bottom, 16)

                    // 顶部横幅
                    HStack(spacing: 12) {
                        Text("🔐").font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shadowsocks")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentColor)
                            Text("轻量级 SOCKS5 代理协议")
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

                    ConfigField(label: "备注", text: $name, placeholder: "例如：SG Node")
                    ConfigRow {
                        ConfigField(label: "地址", text: $address, placeholder: "server.com")
                        ConfigField(label: "端口", text: $port, placeholder: "8388")
                    }

                    ConfigSection(title: "加密", accent: accentColor) {
                        ConfigPicker(label: "加密方法", selection: $method, options: ["aes-256-gcm", "chacha20-ietf-poly1305", "aes-128-gcm"])
                        SecureConfigField(label: "密码", text: $password, placeholder: "your-password")
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

    private func save() {
        let config = ServerConfig(
            name: name,
            address: address,
            port: Int(port) ?? 8388,
            protocolType: .shadowsocks,
            protocolSpecific: .shadowsocks(.init(method: method, password: password))
        )
        onSave(config)
    }
}