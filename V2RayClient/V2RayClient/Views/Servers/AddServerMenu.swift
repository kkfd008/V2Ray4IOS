import SwiftUI

/// + 按钮弹出菜单
struct AddServerMenu: View {
    @Binding var isPresented: Bool
    let onSelectProtocol: (ProtocolType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MenuItem(icon: "qrcode.viewfinder", title: "扫描二维码", color: Color(hex: "e4e8ee")) {
                isPresented = false
                // 触发扫描
            }
            MenuItem(icon: "doc.on.clipboard", title: "从剪切板导入", color: Color(hex: "e4e8ee")) {
                isPresented = false
                importFromClipboard()
            }
            MenuItem(icon: "folder", title: "从本地导入", color: Color(hex: "e4e8ee")) {
                isPresented = false
            }
            Divider().background(Color(white: 1).opacity(0.08)).padding(.vertical, 3)

            MenuItem(icon: nil, title: "手动输入 VMess", color: Color(hex: "4da6ff")) {
                isPresented = false
                onSelectProtocol(.vmess)
            }
            MenuItem(icon: nil, title: "手动输入 VLESS", color: Color(hex: "c882f0")) {
                isPresented = false
                onSelectProtocol(.vless)
            }
            MenuItem(icon: nil, title: "手动输入 Trojan", color: Color(hex: "f0a040")) {
                isPresented = false
                onSelectProtocol(.trojan)
            }
            MenuItem(icon: nil, title: "手动输入 SS", color: Color(hex: "ff4757")) {
                isPresented = false
                onSelectProtocol(.shadowsocks)
            }
        }
        .frame(width: 194)
        .padding(.vertical, 4)
        .background(Color(hex: "1a212b"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 16)
    }

    private func importFromClipboard() {
        guard let text = UIPasteboard.general.string,
              let config = ConfigParser.parse(string: text) else { return }
        StorageService.shared.servers.append(config)
        StorageService.shared.saveServers()
    }
}

struct MenuItem: View {
    let icon: String?
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .frame(width: 20)
                        .font(.system(size: 14))
                } else {
                    Text("▸")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 20)
                }
                Text(title)
                    .font(.system(size: 14))
                Spacer()
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
    }
}