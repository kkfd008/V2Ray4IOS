import Foundation

/// Xray-core Swift 桥接层
/// 封装 gomobile 生成的 XrayCore.xcframework 的 Go 函数调用
///
/// 前置条件：需要将 XrayCore.xcframework 添加到 Frameworks 目录并在 Xcode 中 link
/// gomobile 编译命令：gomobile bind -target=ios -o XrayCore.xcframework ./xray-wrapper
///
/// Go 封装层暴露的函数签名：
///   func StartXray(configJSON string, assetDir string) string  // 返回错误信息
///   func StopXray()
///   func GetTrafficStats() (upload int64, download int64)
final class XrayBridge {
    static let shared = XrayBridge()

    private var isRunning = false

    /// 本地代理地址
    let localHost = "127.0.0.1"
    let socksPort = 10808
    let httpPort = 10809

    /// 启动 Xray-core
    /// - Parameters:
    ///   - configJSON: V2Ray JSON 配置字符串
    ///   - assetDir: geoip.dat / geosite.dat 所在目录
    /// - Returns: 错误信息，空字符串表示成功
    func start(configJSON: String, assetDir: String) -> String {
        guard !isRunning else { return "" }
        // let error = XrayCoreStartXray(configJSON, assetDir)
        // if error.isEmpty { isRunning = true }
        // return error
        isRunning = true
        return ""
    }

    /// 停止 Xray-core
    func stop() {
        guard isRunning else { return }
        // XrayCoreStopXray()
        isRunning = false
    }

    /// 获取流量统计
    /// - Returns: (上传字节数, 下载字节数)
    func getTrafficStats() -> (upload: Int64, download: Int64) {
        // return XrayCoreGetTrafficStats()
        return (0, 0)
    }

    /// 生成本地 SOCKS5 代理地址
    var socksProxyAddress: String {
        "\(localHost):\(socksPort)"
    }

    var httpProxyAddress: String {
        "\(localHost):\(httpPort)"
    }
}