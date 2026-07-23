import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(hex: "0b0f14").ignoresSafeArea()

            VStack(spacing: 0) {
                // 主内容区
                TabView(selection: $appState.selectedTab) {
                    HomeView()
                        .tag(AppState.Tab.home)
                    ServerListView()
                        .tag(AppState.Tab.servers)
                    SubscriptionView()
                        .tag(AppState.Tab.subscriptions)
                    RoutingView()
                        .tag(AppState.Tab.routing)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 底部 TabBar
                HStack(spacing: 0) {
                    ForEach(AppState.Tab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18))
                                Text(tab.title)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(appState.selectedTab == tab ? Color(hex: "00e5a0") : Color(hex: "4a5462"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
                .background(Color(hex: "131820"))
                .overlay(Divider().background(Color(hex: "1a212b")), alignment: .top)
            }
        }
    }
}

// MARK: - Color Helper

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}