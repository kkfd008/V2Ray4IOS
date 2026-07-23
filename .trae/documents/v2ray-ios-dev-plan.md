# V2Ray iOS Client 开发计划

## 1. 项目概述

使用 Swift + SwiftUI 开发一个功能完整的 iOS V2Ray 代理客户端，通过 gomobile 编译 Xray-core 为 iOS 框架，基于 NetworkExtension 实现系统级 VPN 代理。

## 2. 当前状态分析

- 已有 Spec 文档（`/workspace/.trae/specs/v2ray-ios-client/spec.md`）
- 已有 Tasks 分解（`/workspace/.trae/specs/v2ray-ios-client/tasks.md`）
- 已有 Checklist 验收标准（`/workspace/.trae/specs/v2ray-ios-client/checklist.md`）
- 已完成 UI 原型设计（HTML 交互稿，暗色主题 + 霓虹绿强调色）
- 项目尚未创建，为全新项目

## 3. 技术选型

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

## 4. 项目结构

```
V2RayClient/
├── V2RayClient.xcodeproj
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
│   │   ├── Home/
│   │   │   └── HomeView.swift            # 主页面（连接环 + 统计 + 快捷入口）
│   │   ├── Servers/
│   │   │   ├── ServerListView.swift      # 服务器列表
│   │   │   ├── ServerConfigView.swift    # 协议配置表单（分发到各协议子视图）
│   │   │   ├── AddServerMenu.swift       # + 弹出菜单
│   │   │   └── protocols/
│   │   │       ├── VMessConfigView.swift
│   │   │       ├── VLESSConfigView.swift
│   │   │       ├── TrojanConfigView.swift
│   │   │       └── SSConfigView.swift
│   │   ├── Subscription/
│   │   │   └── SubscriptionView.swift    # 订阅管理
│   │   ├── Routing/
│   │   │   └── RoutingView.swift         # 路由模式选择 + PAC 配置
│   │   ├── Scanner/
│   │   │   └── QRScannerView.swift       # 二维码扫描
│   │   └── Components/
│   │       ├── ConnectRing.swift         # 连接环组件
│   │       ├── StatsRow.swift            # 流量统计行
│   │       ├── ProtocolBadge.swift       # 协议标签
│   │       ├── ToggleRow.swift           # 开关行
│   │       └── ToastView.swift           # Toast 提示
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

## 5. 开发计划（分阶段）

### 阶段一：项目骨架 + 数据层（Task 1-3）

**Task 1: 创建 Xcode 项目结构**
- 创建 SwiftUI App 项目 `V2RayClient`
- 添加 NetworkExtension Target `PacketTunnel`（Bundle ID: `{app}.packet-tunnel`）
- 配置 App Group：`group.com.v2ray.client`
- 配置 `Info.plist`：
  - 主 App：`com.apple.developer.networking.vpn.api` 权限
  - Extension：`NSExtensionPointIdentifier = com.apple.networkextension.packet-tunnel`
- 创建 Shared 目录，定义 `SharedConstants`（App Group ID、UserDefaults Keys）

**Task 2: 实现数据模型层**
- `ProtocolType` 枚举：`.vmess`, `.vless`, `.trojan`, `.shadowsocks`
- `ServerConfig`：Codable struct，包含通用字段（id, name, address, port, protocol）及各协议特有字段（使用 enum with associated values 区分）
- `Subscription`：id, url, lastUpdated, serverCount
- `RoutingMode` 枚举：`.global`, `.pac`
- `WhitelistBlacklistEntry`：id, regex, type(.whitelist / .blacklist)

**Task 3: 实现持久化存储**
- `StorageService`：单例，封装 App Group UserDefaults 读写
- 方法：`saveServers()`, `loadServers()`, `saveSubscription()`, `loadSubscriptions()`, `saveRoutingMode()`, `loadRoutingMode()`, `saveWhitelistEntries()`, `loadWhitelistEntries()`, `saveBlacklistEntries()`, `loadBlacklistEntries()`
- 所有数据通过 JSONEncoder/JSONDecoder 序列化

### 阶段二：核心引擎 + VPN（Task 4-6）

**Task 4: Xray-core 桥接层**
- 准备 gomobile 编译环境（Go 1.21+, gomobile）
- 编写 Go 封装层，暴露 `StartXray(configJSON string)`, `StopXray()`, `GetTrafficStats() (up, down int64)`
- `gomobile bind -target=ios -o XrayCore.xcframework` 编译
- 在主工程中 link XrayCore.xcframework
- 创建 Swift wrapper `XrayBridge` 封装 Go 导出的函数

**Task 5: VPN 管理器（主 App 侧）**
- `VPNManager`：ObservableObject，管理 NETunnelProviderManager
- `loadProvider()`：加载已有 VPN 配置
- `saveProvider()`：创建/更新 VPN 配置
- `connect(config: ServerConfig)`：将配置写入共享存储，启动隧道
- `disconnect()`：停止隧道
- `status`：@Published 属性，监听 `NEVPNStatusDidChange`
- 状态枚举映射：`.invalid/.disconnected` → 已断开，`.connecting` → 连接中，`.connected` → 已连接

**Task 6: PacketTunnelProvider**
- `PacketTunnelProvider` 继承 `NEPacketTunnelProvider`
- `startTunnel(options:)`：从共享存储读取 ServerConfig → 生成 JSON 配置 → 启动 Xray-core（本地 SOCKS5 127.0.0.1:10808）→ 配置 `NEPacketTunnelNetworkSettings`（tunnelRemoteAddress + includedRoutes）
- `stopTunnel(with:)`：停止 Xray-core → 调用 `completionHandler`
- 定时读取流量统计，写入共享存储

### 阶段三：协议解析 + 订阅（Task 8）

**Task 8: 协议链解析与订阅导入**
- `ConfigParser`：
  - `parse(url: URL) -> ServerConfig?`：解析 `vmess://` / `vless://` / `trojan://` / `ss://` 协议链
  - 各协议链格式：
    - vmess://base64(json)
    - vless://uuid@host:port?params
    - trojan://password@host:port?params
    - ss://base64(method:password@host:port)
- `QRScannerView`：基于 AVFoundation 的 `AVCaptureSession`，识别二维码后回调
- `SubscriptionService`：
  - `fetchSubscription(url: URL)`：URLSession 请求 → Base64 解码 → 逐行解析协议链 → 批量导入
  - `updateSubscription(id)`：重新拉取并增量更新（新增的添加，已有更新，手动删除的保留）

### 阶段四：UI 实现（Task 7）

所有 UI 采用暗色主题，单一强调色 `#00e5a0`（`Color(.systemGreen)` 近似），字体使用系统等宽字体 + 系统中文字体。

**HomeView**
- 顶部：App 名称 + 版本号
- 连接环组件 `ConnectRing`：136×136 圆形，三种状态动画
  - 已断开：灰色边框 + 🔌 图标
  - 连接中：虚线旋转 + ⏳ 图标
  - 已连接：绿色边框 + 脉冲光晕动画 + ⚡ 图标
- 连接状态文字 + 计时器（HH:MM:SS 格式）
- `StatsRow`：三列均分网格，显示下载/上传/速度
- 当前服务器信息卡片（名称 + 协议 + 地址 + 传输）
- 快捷入口：服务器 / 路由 / 订阅

**ServerListView**
- 导航栏：返回按钮 + 标题 + + 按钮
- 服务器列表（分割线分隔，非卡片）
- 每行：协议标签（四色）+ 名称 + 地址 + 选中标记 ✓
- 点击切换选中服务器，同步更新首页
- + 按钮弹出 `AddServerMenu`：
  - 扫描二维码
  - 从剪切板导入
  - 从本地导入
  - 分割线
  - 手动输入 VMess（蓝色）
  - 手动输入 VLESS（紫色）
  - 手动输入 Trojan（橙色）
  - 手动输入 SS（红色）

**协议配置视图（四种独立 UI）**
- `VMessConfigView`：蓝色主题，三组卡片（服务端信息/认证/传输）
- `VLESSConfigView`：紫色主题，三组卡片（目标服务器/身份凭证/传输与安全）
- `TrojanConfigView`：橙色主题，顶部横幅（🐴 图标 + 描述），密码字段为 SecureField
- `SSConfigView`：红色主题，顶部横幅（🔐 图标 + 描述），加密分组
- 保存按钮颜色随协议切换

**SubscriptionView**
- 订阅链接输入框 + 添加按钮
- 订阅卡片列表（URL + 更新间隔 + 服务器数 + 更新按钮）

**RoutingView**
- 路由模式选择：全局代理 / PAC 模式（单选）
- PAC 模式展开区域：
  - GFWList 规则区：固定 URL + 更新按钮 + 上次更新时间
  - 扩展白名单：正则输入框 + 添加按钮 + 列表（可删除）
  - 扩展黑名单：正则输入框 + 添加按钮 + 列表（可删除）

**QRScannerView**
- 全屏暗色遮罩
- 扫描框（220×220）+ 扫描线动画
- 提示文字 + 取消按钮

**底部 TabBar**
- 首页 / 服务器 / 订阅 / 路由
- 选中态：绿色高亮

### 阶段五：路由规则 + 收尾（Task 9）

**Task 9: 路由规则与 PAC 生成**
- 将 `geoip.dat` 和 `geosite.dat` 打包到 App Bundle 和 Extension Bundle
- 全局代理模式：`includedRoutes = [0.0.0.0/0]`，所有流量走隧道
- PAC 模式：`PACGenerator` 基于 GFWList + 白名单 + 黑名单生成 PAC 脚本
  - GFWList 域名 → `PROXY 127.0.0.1:10808`
  - 白名单正则匹配 → `DIRECT`
  - 黑名单正则匹配 → `PROXY 127.0.0.1:10808`
  - 默认 → `PROXY 127.0.0.1:10808`
- 生成 `proxyAutoConfigurationJavaScript` 注入 `NEProxySettings`

## 6. 依赖关系

```
Task 1 (项目结构)
  ├── Task 2 (数据模型)
  │     └── Task 3 (持久化存储)
  │           ├── Task 5 (VPN 管理器)
  │           │     └── Task 7 (UI 实现)
  │           ├── Task 8 (协议解析 + 订阅)
  │           │     └── Task 7 (UI 实现)
  │           └── Task 6 (PacketTunnelProvider)
  │                 └── Task 7 (UI 实现)
  └── Task 4 (Xray-core 桥接)
        └── Task 6 (PacketTunnelProvider)
              └── Task 9 (路由规则)
```

## 7. 关键决策与假设

1. **gomobile 编译**：假设 Xray-core 可在 iOS arm64 上编译通过，若遇到 Go 版本兼容问题，可降级到 Xray-core 1.8.x 稳定分支
2. **最低 iOS 版本**：iOS 15.0（SwiftUI 3.0 + NetworkExtension 完善支持）
3. **PAC 脚本**：由客户端根据 GFWList + 黑白名单动态生成，不暴露原始 PAC 编辑
4. **GFWList 更新**：首次使用或用户手动触发，缓存到本地，不自动后台更新
5. **协议特有字段**：每个协议的 ServerConfig 使用 enum with associated values 实现，避免可选字段泛滥
6. **流量统计**：由 Xray-core 内部统计，PacketTunnelProvider 定时（1s）读取一次，写入共享 UserDefaults，主 App 读取显示
7. **剪切板导入**：读取 `UIPasteboard.general.string`，检测是否包含协议链格式

## 8. 验收检查点

- [ ] Xcode 项目包含主 App Target 和 PacketTunnel NetworkExtension Target
- [ ] App Group 配置正确，共享容器可读写
- [ ] ServerConfig 模型支持 VMess / VLESS / Trojan / Shadowsocks 四种协议
- [ ] 服务器配置可增删改查，持久化到 App Group 共享存储
- [ ] 支持手动输入协议链添加服务器
- [ ] 支持扫描二维码添加服务器
- [ ] 订阅链接可解析并批量导入
- [ ] VPNManager 可控制 VPN 连接/断开，状态实时反映到 UI
- [ ] Xray-core 可通过 gomobile 编译并在 iOS 上运行
- [ ] PacketTunnelProvider 启动后流量通过 Xray-core 代理转发
- [ ] 主界面显示连接状态、流量统计、连接时长
- [ ] 全局代理模式下所有流量走 VPN 隧道
- [ ] PAC 模式：GFWList 更新、白名单/黑名单正则匹配生效
- [ ] 四种协议各有独立配置 UI，保存按钮颜色随协议变化
- [ ] 底部 TabBar 四页面切换正常