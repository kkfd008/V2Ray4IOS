# Tasks

- [ ] Task 1: 创建 Xcode 项目结构
  - [ ] 创建 SwiftUI 主工程（V2RayClient）
  - [ ] 创建 NetworkExtension Target（PacketTunnel）
  - [ ] 配置 App Group 共享容器
  - [ ] 配置 Info.plist（VPN 权限、NetworkExtension 声明）

- [ ] Task 2: 实现数据模型层
  - [ ] 定义 ProtocolType 枚举（vmess/vless/trojan/ss）
  - [ ] 定义 ServerConfig 模型（通用字段 + 各协议特有字段），Codable
  - [ ] 定义 Subscription 模型
  - [ ] 定义 RoutingRule 模型

- [ ] Task 3: 实现持久化存储（App Group 共享）
  - [ ] 实现 ServerStore（UserDefaults + JSON 编码）
  - [ ] 实现 CRUD 操作
  - [ ] 确保主 App 和 Extension 均可读写

- [ ] Task 4: 实现 Xray-core 桥接层
  - [ ] 配置 gomobile 编译 Xray-core 为 iOS .xcframework
  - [ ] 创建 Swift 桥接层，封装启动/停止/配置生成
  - [ ] 根据 ServerConfig 动态生成 V2Ray JSON 配置

- [ ] Task 5: 实现 VPN 管理器（主 App 侧）
  - [ ] 封装 NETunnelProviderManager 的加载/保存/连接/断开
  - [ ] 监听 NEVPNStatusDidChange 并发布状态
  - [ ] 连接前将选中配置写入共享存储

- [ ] Task 6: 实现 PacketTunnelProvider
  - [ ] 实现 startTunnel：启动 Xray-core 本地 SOCKS5 代理
  - [ ] 配置 NEPacketTunnelNetworkSettings 路由流量到本地代理
  - [ ] 实现 stopTunnel：停止 Xray-core
  - [ ] 实现流量统计上报到共享存储

- [ ] Task 7: 实现主界面 UI（SwiftUI）
  - [ ] 主页面：连接按钮、状态、流量统计、计时器
  - [ ] 服务器列表页（列表 + 滑动删除）
  - [ ] 添加服务器页（手动输入协议链 + 扫描二维码入口）
  - [ ] 服务器配置编辑页（协议动态表单）
  - [ ] 订阅管理页
  - [ ] 路由规则配置页

- [ ] Task 8: 实现协议链解析与订阅导入
  - [ ] 解析 vmess:// / vless:// / trojan:// / ss:// 协议链
  - [ ] 实现二维码扫描（AVFoundation）
  - [ ] 实现订阅链接请求 + Base64 解码 + 批量导入
  - [ ] 增量更新逻辑

- [ ] Task 9: 集成路由规则与 geo 数据
  - [ ] 集成 geoip.dat / geosite.dat 资源文件
  - [ ] 生成默认路由 JSON 配置
  - [ ] 实现自定义路由规则编辑界面

# Task Dependencies
- Task 2 依赖 Task 1
- Task 3 依赖 Task 2
- Task 4 可与 Task 2-3 并行
- Task 5 依赖 Task 3
- Task 6 依赖 Task 4 + Task 3
- Task 7 依赖 Task 5 + Task 3
- Task 8 依赖 Task 2-3
- Task 9 依赖 Task 4