import SwiftUI

/// 协议标签
struct ProtocolBadge: View {
    let type: ProtocolType

    var body: some View {
        Text(type.shortName)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.12))
            .foregroundColor(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var badgeColor: Color {
        switch type {
        case .vmess:       return Color(hex: "4da6ff")
        case .vless:       return Color(hex: "c882f0")
        case .trojan:      return Color(hex: "f0a040")
        case .shadowsocks: return Color(hex: "ff4757")
        }
    }
}