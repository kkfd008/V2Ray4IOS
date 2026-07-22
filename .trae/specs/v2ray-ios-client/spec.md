# V2Ray iOS Client Spec

## Why
用户需要一个 iOS 平台的 V2Ray 代理客户端，支持主流 V2Ray 协议（VMess/VLESS/Trojan/Shadowsocks），通过 NetworkExtension VPN 框架实现系统级代理。

## What Changes
- 新建 SwiftUI iOS 项目，通过 gomobile 集成 Xray-core
- 实现 VPN 隧道管理（NEPacketTunnelProvider）
- 实现服务器配置管理（手动输入协议链 / 扫描二维码 / 订阅导入）
- 支持 VMess、VLESS、Trojan、Shadowsocks 协议
- 内置 geoip/geosite 路由规则

## Impact
- Affected specs: 全新项目
- Affected code: 全新 Swift 项目，模块：
  - App 主工程（SwiftUI）
  - NetworkExtension 扩展（PacketTunnelProvider）
  - Xray-core 桥接层（gomobile 生成的 .xcframework）

## ADDED Requirements

### Requirement: 服务器配置管理
系统 SHALL 提供服务器配置的增删改查，支持手动输入协议链、扫描二维码、订阅链接导入三种方式。

#### Scenario: 手动输入协议链添加服务器
- **WHEN** 用户选择手动添加，输入协议链地址（如 vmess://...、vless://...）
- **THEN** 系统解析协议链，自动填充配置字段，用户确认后保存

#### Scenario: 扫描二维码添加服务器
- **WHEN** 用户点击扫描二维码，摄像头识别到有效协议链二维码
- **THEN** 系统解析协议链内容，自动填充配置，用户确认后保存

#### Scenario: 从订阅链接导入
- **WHEN** 用户输入订阅链接并点击更新
- **THEN** 系统请求订阅内容（Base64），解析后批量导入服务器列表

#### Scenario: 编辑/删除服务器
- **WHEN** 用户编辑或删除服务器配置
- **THEN** 系统更新或移除对应配置，若正连接该服务器则先断开

### Requirement: VPN 隧道管理
系统 SHALL 基于 NEPacketTunnelProvider 创建 VPN 隧道，隧道内运行 Xray-core 作为本地代理。

#### Scenario: 连接
- **WHEN** 用户选择服务器并点击连接
- **THEN** 系统将配置写入共享存储，启动 VPN 隧道，隧道内启动 Xray-core
- **AND** 状态更新为"已连接"，显示服务器名、IP、持续时长

#### Scenario: 断开
- **WHEN** 用户点击断开
- **THEN** 系统停止 VPN 隧道，Xray-core 退出，状态更新为"已断开"

#### Scenario: 状态同步
- **WHEN** VPN 状态变化
- **THEN** 主界面实时显示：已断开 / 连接中 / 已连接

### Requirement: 多协议支持
系统 SHALL 支持以下协议配置：

- **VMess**: 地址、端口、UUID、AlterID、Security、传输（tcp/ws/grpc/h2）、TLS
- **VLESS**: 地址、端口、UUID、Flow、Encryption、传输（tcp/ws/grpc/h2）、TLS/Reality
- **Trojan**: 地址、端口、密码、传输（tcp/ws/grpc）、TLS
- **Shadowsocks**: 地址、端口、加密方法、密码

### Requirement: 路由规则
系统 SHALL 内置 geoip.dat 和 geosite.dat，默认规则：国内直连、境外代理。

#### Scenario: 默认路由
- **WHEN** VPN 连接后
- **THEN** 国内 IP/域名直连，境外 IP/域名走代理

#### Scenario: 自定义路由
- **WHEN** 用户添加自定义规则
- **THEN** 支持域名/IP 匹配 + 代理/直连/拒绝策略

### Requirement: 流量统计
系统 SHALL 在连接期间显示实时上传/下载流量和速度。

### Requirement: 订阅管理
系统 SHALL 支持订阅链接的保存、手动更新。

### Requirement: 数据持久化
系统 SHALL 通过 App Group 共享存储持久化所有配置，主 App 和 Extension 均可读写。