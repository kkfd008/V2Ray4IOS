# V2Ray4IOS

基于 Swift + SwiftUI 开发的 iOS V2Ray 代理客户端，通过 gomobile 将 Xray-core 编译为 iOS 框架，基于 NetworkExtension 实现系统级 VPN 代理。

## 支持的协议

- **VMess** — 地址、端口、UUID、AlterID、Security、传输（TCP/WS/gRPC/H2）、TLS
- **VLESS** — 地址、端口、UUID、Flow、Encryption、传输（TCP/WS/gRPC/H2）、TLS/Reality
- **Trojan** — 地址、端口、密码、传输（TCP/WS/gRPC）、TLS
- **Shadowsocks** — 地址、端口、加密方法、密码

## 项目结构

```
V2RayClient/
├── V2RayClient/                          # 主 App Target
│   ├── App/
│   │   ├── V2RayClientApp.swift          # @main App 入口
│   │   └── AppState.swift                # 全局状态管理
│   ├── Models/
│   │   ├── ProtocolType.swift            # 协议枚举
│   │   ├── ServerConfig.swift            # 服务器配置模型
│   │   ├── Subscription.swift            # 订阅模型
│   │   ├── RoutingMode.swift             # 路由模式枚举
│   │   └── WhitelistBlacklistEntry.swift # PAC 白/黑名单条目
│   ├── Services/
│   │   ├── StorageService.swift          # App Group 持久化
│   │   ├── VPNManager.swift              # NETunnelProviderManager 封装
│   │   ├── ConfigParser.swift            # 协议链解析器
│   │   ├── SubscriptionService.swift     # 订阅拉取与解析
│   │   └── PACGenerator.swift            # PAC 脚本生成
│   ├── Views/
│   │   ├── Home/HomeView.swift           # 主页面（连接环 + 统计 + 快捷入口）
│   │   ├── Servers/                      # 服务器列表与配置
│   │   ├── Subscription/                 # 订阅管理
│   │   ├── Routing/                      # 路由模式选择 + PAC 配置
│   │   ├── Scanner/                      # 二维码扫描
│   │   └── Components/                   # 可复用组件
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── geoip.dat                     # 路由规则数据
│   │   └── geosite.dat
│   └── Info.plist
├── PacketTunnel/                         # NetworkExtension Target
│   ├── PacketTunnelProvider.swift        # NEPacketTunnelProvider 子类
│   ├── XrayBridge.swift                  # Xray-core 桥接
│   ├── ConfigGenerator.swift             # JSON 配置生成
│   └── Info.plist
├── Frameworks/
│   └── XrayCore.xcframework              # gomobile 编译产物
└── Shared/                               # App Group 共享
    └── SharedConstants.swift             # App Group ID、Key 常量
```

## 环境要求

| 组件 | 版本要求 |
|------|---------|
| macOS | 13.0+ |
| Xcode | 15.0+ |
| iOS 部署目标 | 15.0+ |
| Swift | 5.9+ |
| Go | 1.21+ |
| gomobile | 最新版 |

## 编译打包流程

### 1. 克隆仓库

```bash
git clone https://github.com/kkfd008/V2Ray4IOS.git
cd V2Ray4IOS
```

### 2. 准备 Xray-core 桥接层

#### 2.1 安装 Go 与 gomobile

```bash
# 安装 Go（如未安装）
brew install go

# 安装 gomobile
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# 初始化 gomobile
gomobile init
```

#### 2.2 编写 Go 封装层

在项目外创建 `xray-wrapper` 目录，编写 Go 封装代码，暴露以下函数供 Swift 调用：

```go
// 关键导出函数签名
func StartXray(configJSON string, assetDir string) string  // 返回错误信息，空字符串表示成功
func StopXray()
func GetTrafficStats() (upload int64, download int64)
```

封装层需要引入 Xray-core 作为 Go 模块依赖，并暴露 `StartXray`、`StopXray`、`GetTrafficStats` 三个导出函数。

#### 2.3 编译 Xray-core 为 iOS 框架

```bash
cd xray-wrapper
gomobile bind -target=ios -o XrayCore.xcframework .
```

编译完成后，将生成的 `XrayCore.xcframework` 复制到项目的 `V2RayClient/Frameworks/` 目录下。

> **注意**：gomobile 仅支持在 macOS 上编译 iOS 框架。编译过程可能需要较长时间，且需确保 Xray-core 依赖在 iOS arm64 上兼容。如遇到 Go 版本兼容问题，可尝试降级到 Xray-core 1.8.x 稳定分支。

### 3. 创建 Xcode 项目

#### 3.1 创建主工程

1. 打开 Xcode，选择 **File → New → Project**
2. 选择 **iOS → App**，点击 Next
3. 配置：
   - Product Name: `V2RayClient`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment Target: **iOS 15.0**
4. 将项目文件保存到 `V2RayClient/` 目录下

#### 3.2 添加 NetworkExtension Target

1. 在 Xcode 中选择 **File → New → Target**
2. 选择 **Network Extension**，点击 Next
3. 配置：
   - Product Name: `PacketTunnel`
   - Provider Type: **Packet Tunnel Provider**
4. 完成后，Xcode 会在项目中生成 `PacketTunnel` 目录和 `PacketTunnelProvider.swift` 文件

#### 3.3 配置 App Group

1. 在 Xcode 中选择主 App Target → **Signing & Capabilities**
2. 点击 **+ Capability**，添加 **App Groups**
3. 添加 App Group 容器：`group.com.v2ray.client`
4. 对 PacketTunnel Target 重复上述步骤，添加相同的 App Group

#### 3.4 配置 Info.plist

**主 App Target** 需要添加 VPN 权限：

```xml
<key>com.apple.developer.networking.vpn.api</key>
<array>
    <string>com.apple.developer.networking.vpn.api.allowPersonalVPN</string>
</array>
```

**PacketTunnel Extension** 的 Info.plist 需包含：

```xml
<key>NSExtensionPointIdentifier</key>
<string>com.apple.networkextension.packet-tunnel</string>
```

#### 3.5 链接 XrayCore.framework

1. 将 `V2RayClient/Frameworks/XrayCore.xcframework` 拖入 Xcode 项目导航器
2. 在 PacketTunnel Target 的 **General → Frameworks and Libraries** 中，确保 `XrayCore.xcframework` 已添加
3. 在 PacketTunnel Target 的 **Build Settings → Framework Search Paths** 中，添加 `$(PROJECT_DIR)/Frameworks`

#### 3.6 添加资源文件

将 `geoip.dat` 和 `geosite.dat` 添加到主 App Target 和 PacketTunnel Target 的 **Copy Bundle Resources** 中。

### 4. 配置 Bundle Identifier

| Target | Bundle ID |
|--------|----------|
| 主 App | `com.v2ray.client` |
| PacketTunnel Extension | `com.v2ray.client.packet-tunnel` |

在 `PacketTunnelProvider.swift` 中确认 `providerBundleIdentifier` 与 Extension 的 Bundle ID 一致。

### 5. 编译运行

1. 在 Xcode 顶部选择 **主 App Target** 和目标设备（真机或模拟器）
2. 注意：NetworkExtension 功能必须在**真机**上测试，模拟器不支持 VPN
3. 按 **Cmd + R** 编译并运行

### 6. 打包发布

#### 6.1 Archive

1. 在 Xcode 中选择 **Product → Scheme → Edit Scheme**，将 Build Configuration 设为 **Release**
2. 选择 **Product → Archive** 进行归档
3. 归档完成后，Xcode Organizer 会自动打开

#### 6.2 导出 IPA

在 Organizer 中选择归档包，点击 **Distribute App**，根据需要选择分发方式：

- **App Store Connect** — 上传至 App Store
- **Ad Hoc** — 用于内部分发测试
- **Enterprise** — 企业证书分发
- **Development** — 开发测试

#### 6.3 注意事项

- 发布到 App Store 需要 Network Extension 的 entitlements 通过 Apple 审核
- VPN 应用需要提供明确的隐私政策和使用说明
- 确保 PacketTunnel Extension 的 provisioning profile 中包含 Network Extension 能力

## 技术选型

| 层面 | 技术 | 说明 |
|------|------|------|
| 语言 | Swift 5.9+ | 主工程 + NetworkExtension |
| UI | SwiftUI | iOS 15+ |
| 核心引擎 | Xray-core (gomobile) | Go → .xcframework |
| VPN 框架 | NetworkExtension | NEPacketTunnelProvider |
| 数据共享 | App Group | UserDefaults + 文件 |
| 持久化 | Codable + JSON | 编码到 UserDefaults |
| 二维码 | AVFoundation | 摄像头扫描 |
| 网络请求 | URLSession | 订阅拉取 |

## 依赖关系

```
Xcode 项目结构
  ├── 数据模型 (Models/)
  │     └── 持久化存储 (StorageService)
  │           ├── VPN 管理器 (VPNManager)
  │           │     └── UI 实现 (Views/)
  │           ├── 协议解析 + 订阅 (ConfigParser / SubscriptionService)
  │           │     └── UI 实现 (Views/)
  │           └── PacketTunnelProvider
  │                 └── UI 实现 (Views/)
  └── Xray-core 桥接 (XrayBridge)
        └── PacketTunnelProvider
              └── 路由规则 (ConfigGenerator)
```

## 核心功能

- **服务器配置管理**：手动输入协议链 / 扫描二维码 / 订阅链接导入三种方式
- **VPN 隧道管理**：基于 NEPacketTunnelProvider，隧道内运行 Xray-core 本地代理（SOCKS5 10808 + HTTP 10809）
- **多协议支持**：VMess / VLESS / Trojan / Shadowsocks 四种协议各有独立配置 UI
- **路由规则**：内置 geoip.dat / geosite.dat，支持全局代理与 PAC 模式
- **流量统计**：实时上传/下载流量与速度显示
- **订阅管理**：支持订阅链接的保存与手动更新
- **数据持久化**：通过 App Group 共享存储，主 App 和 Extension 均可读写