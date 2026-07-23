import SwiftUI

/// 路由模式配置
struct RoutingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPAC = false
    @State private var newWhitelist = ""
    @State private var newBlacklist = ""
    @State private var toastMessage = ""
    @State private var showToast = false

    var body: some View {
        ZStack {
            Color(hex: "0b0f14").ignoresSafeArea()

            ScrollView {
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
                        Text("路由模式")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "e4e8ee"))
                        Spacer().frame(width: 30)
                    }
                    .padding(.bottom, 16)

                    SectionHeader(title: "代理模式", count: "")

                    // 路由模式选择
                    ForEach(RoutingMode.allCases, id: \.self) { mode in
                        RoutingOptionRow(
                            mode: mode,
                            isSelected: appState.storage.routingMode == mode,
                            action: {
                                appState.storage.routingMode = mode
                                appState.storage.saveRoutingMode()
                                showPAC = (mode == .pac)
                            }
                        )
                    }

                    // PAC 配置区域
                    if showPAC {
                        pacSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            // Toast
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, isPresented: $showToast)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            showPAC = appState.storage.routingMode == .pac
        }
    }

    // MARK: - PAC Section

    private var pacSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // GFWList
            SectionHeader(title: "GFWList 规则", count: "")
            HStack(spacing: 8) {
                Text("raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "4a5462"))
                    .lineLimit(1)
                Spacer()
                Button("更新") {
                    updateGFWList()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "00e5a0"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "00e5a0").opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "00e5a0"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(12)
            .background(Color(hex: "131820"))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("上次更新：\(gfwlistLastUpdated)")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "4a5462"))
                .padding(.top, 4)
                .padding(.bottom, 14)

            // 扩展白名单
            SectionHeader(title: "扩展白名单", count: "")
            Text("匹配正则表达式的域名将强制直连")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "4a5462"))
                .padding(.bottom, 8)
            HStack(spacing: 8) {
                TextField("正则表达式，如 .*\\.example\\.com$", text: $newWhitelist)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(hex: "e4e8ee"))
                    .padding(11)
                    .background(Color(hex: "131820"))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button("添加") { addWhitelist() }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "00e5a0"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: "00e5a0").opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "00e5a0"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 10)

            ForEach(appState.storage.whitelistEntries) { entry in
                RuleEntryRow(entry: entry, onDelete: {
                    appState.storage.whitelistEntries.removeAll { $0.id == entry.id }
                    appState.storage.saveWhitelistEntries()
                })
            }

            // 扩展黑名单
            SectionHeader(title: "扩展黑名单", count: "")
                .padding(.top, 14)
            Text("匹配正则表达式的域名将强制走代理")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "4a5462"))
                .padding(.bottom, 8)
            HStack(spacing: 8) {
                TextField("正则表达式，如 .*\\.google\\.com$", text: $newBlacklist)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(hex: "e4e8ee"))
                    .padding(11)
                    .background(Color(hex: "131820"))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button("添加") { addBlacklist() }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "00e5a0"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: "00e5a0").opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "00e5a0"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 10)

            ForEach(appState.storage.blacklistEntries) { entry in
                RuleEntryRow(entry: entry, onDelete: {
                    appState.storage.blacklistEntries.removeAll { $0.id == entry.id }
                    appState.storage.saveBlacklistEntries()
                })
            }
        }
    }

    private var gfwlistLastUpdated: String {
        if let date = appState.storage.gfwlistLastUpdated {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
        return "从未"
    }

    private func updateGFWList() {
        appState.storage.gfwlistLastUpdated = Date()
        showToastMessage("GFWList 已更新")
    }

    private func addWhitelist() {
        guard !newWhitelist.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        appState.storage.whitelistEntries.append(
            WhitelistBlacklistEntry(regex: newWhitelist, type: .whitelist)
        )
        appState.storage.saveWhitelistEntries()
        newWhitelist = ""
        showToastMessage("白名单已添加")
    }

    private func addBlacklist() {
        guard !newBlacklist.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        appState.storage.blacklistEntries.append(
            WhitelistBlacklistEntry(regex: newBlacklist, type: .blacklist)
        )
        appState.storage.saveBlacklistEntries()
        newBlacklist = ""
        showToastMessage("黑名单已添加")
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        showToast = true
    }
}

// MARK: - Routing Option Row

struct RoutingOptionRow: View {
    let mode: RoutingMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(isSelected ? Color(hex: "00e5a0") : Color(white: 1).opacity(0.08), lineWidth: 2)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .fill(Color(hex: "00e5a0"))
                            .frame(width: 9, height: 9)
                            .opacity(isSelected ? 1 : 0)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "e4e8ee"))
                    Text(mode.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "4a5462"))
                }
                Spacer()
            }
            .padding(16)
            .background(
                isSelected
                    ? Color(hex: "00e5a0").opacity(0.06)
                    : Color(hex: "131820")
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "00e5a0") : Color(white: 1).opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Rule Entry Row

struct RuleEntryRow: View {
    let entry: WhitelistBlacklistEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(entry.regex)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "7a8494"))
                .lineLimit(1)
            Spacer()
            Button(action: onDelete) {
                Text("✕")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "4a5462"))
            }
        }
        .padding(10)
        .background(Color(hex: "131820"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 6)
    }
}