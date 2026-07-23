import SwiftUI

/// 服务器列表
struct ServerListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddMenu = false
    @State private var navigateToConfig: ProtocolType?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0b0f14").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 导航栏
                        HStack {
                            Button {
                                appState.selectedTab = .home
                            } label: {
                                Text("← 返回")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "00e5a0"))
                            }
                            Spacer()
                            Text("服务器")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "e4e8ee"))
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    showAddMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "00e5a0"))
                                    .frame(width: 30, height: 30)
                                    .background(Color(hex: "00e5a0").opacity(0.1))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(hex: "00e5a0"), lineWidth: 1))
                            }
                        }
                        .padding(.bottom, 16)

                        // 服务器列表
                        SectionHeader(title: "全部", count: "\(appState.storage.servers.count) 台")

                        ForEach(appState.storage.servers) { server in
                            ServerRow(config: server, isSelected: server.isSelected) {
                                appState.storage.selectServer(server)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .overlay(alignment: .topTrailing) {
                if showAddMenu {
                    AddServerMenu(
                        isPresented: $showAddMenu,
                        onSelectProtocol: { proto in
                            navigateToConfig = proto
                        }
                    )
                    .padding(.top, 96)
                    .padding(.trailing, 20)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .navigationDestination(item: $navigateToConfig) { proto in
                ServerConfigView(protocolType: proto)
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let count: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "4a5462"))
                .textCase(.uppercase)
            Spacer()
            Text(count)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "4a5462"))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Server Row

struct ServerRow: View {
    let config: ServerConfig
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ProtocolBadge(type: config.protocolType)
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "e4e8ee"))
                    Text("\(config.address):\(config.port) | \(config.transport.displayName.uppercased())")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "4a5462"))
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "00e5a0"))
                }
            }
            .padding(.vertical, 14)
        }
        .overlay(
            Divider().background(Color(white: 1).opacity(0.08)),
            alignment: .bottom
        )
    }
}