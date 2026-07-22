# Checklist

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
- [ ] 默认路由规则（国内直连/国外代理）生效
- [ ] 自定义路由规则可添加、编辑、删除