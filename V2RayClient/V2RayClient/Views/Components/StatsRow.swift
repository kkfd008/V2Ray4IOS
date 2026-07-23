import SwiftUI

/// 流量统计行
struct StatsRow: View {
    let download: String
    let upload: String
    let speed: String

    var body: some View {
        HStack(spacing: 2) {
            StatItem(value: download, label: "下载")
            StatItem(value: upload, label: "上传")
            StatItem(value: speed, label: "速度")
        }
        .background(Color(white: 1).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "e4e8ee"))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "4a5462"))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "131820"))
    }
}