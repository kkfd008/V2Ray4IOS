import SwiftUI
import AVFoundation

/// 二维码扫描视图
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onScanResult: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 扫描框
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color(hex: "00e5a0"), lineWidth: 2)
                        .frame(width: 220, height: 220)

                    // 扫描线动画
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "00e5a0").opacity(0.15))
                        .frame(width: 220, height: 2)
                        .offset(y: -110)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }

                Text("将二维码置于框内")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "7a8494"))
                    .padding(.top, 24)

                Button("取消") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "7a8494"))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color(hex: "131820"))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.top, 20)

                Spacer()
            }
        }
    }
}