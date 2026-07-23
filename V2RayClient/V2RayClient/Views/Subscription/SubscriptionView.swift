import SwiftUI

/// 订阅管理
struct SubscriptionView: View {
    @EnvironmentObject var appState: AppState
    @State private var newURL = ""
    @State private var toastMessage = ""
    @State private var showToast = false

    var body: some View {
        ZStack {
            Color(hex: "0b0f14").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        appState.selectedTab = .home
                    } label: {
                        Text("← 返回")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "00e5a0"))
                    }
                    Spacer()
                    Text("订阅")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "e4e8ee"))
                    Spacer().frame(width: 30)
                }
                .padding(.bottom, 16)

                // 输入框
                HStack(spacing: 8) {
                    TextField("输入订阅链接...", text: $newURL)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(hex: "e4e8ee"))
                        .padding(11)
                        .background(Color(hex: "131820"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button(action: addSubscription) {
                        Text("添加")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "00e5a0"))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(Color(hex: "00e5a0").opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "00e5a0"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.bottom, 16)

                // 订阅列表
                ForEach(appState.storage.subscriptions) { sub in
                    SubscriptionCard(subscription: sub) {
                        SubscriptionService.shared.updateSubscription(sub)
                        showToastMessage("订阅已更新")
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Toast
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, isPresented: $showToast)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private func addSubscription() {
        guard !newURL.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let sub = Subscription(url: newURL)
        appState.storage.subscriptions.append(sub)
        appState.storage.saveSubscriptions()
        newURL = ""
        SubscriptionService.shared.updateSubscription(sub)
        showToastMessage("订阅已添加")
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        showToast = true
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subscription.url)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "7a8494"))
                .lineLimit(2)
            HStack {
                Text("\(subscription.lastUpdatedDisplay) · \(subscription.serverCount) 台")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "4a5462"))
                Spacer()
                Button("更新", action: onUpdate)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "00e5a0"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "00e5a0").opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "00e5a0"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(14)
        .background(Color(hex: "131820"))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 10)
    }
}