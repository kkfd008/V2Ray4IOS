import Foundation

/// PAC 脚本生成器
/// 基于 GFWList + 白名单 + 黑名单生成 PAC JavaScript
enum PACGenerator {
    /// GFWList 固定 URL
    static let gfwlistURL = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"

    /// 代理地址
    private static let proxyHost = "127.0.0.1"
    private static let proxyPort = 10808

    /// 生成 PAC 脚本
    static func generate(
        whitelist: [WhitelistBlacklistEntry],
        blacklist: [WhitelistBlacklistEntry]
    ) -> String {
        let whitelistRules = whitelist.map { entry in
            #"  if (/"# + entry.regex + #"/.test(host)) return "DIRECT";"#
        }.joined(separator: "\n")

        let blacklistRules = blacklist.map { entry in
            #"  if (/"# + entry.regex + #"/.test(host)) return "PROXY \#(proxyHost):\#(proxyPort)";"#
        }.joined(separator: "\n")

        return """
        function FindProxyForURL(url, host) {
        \#(whitelistRules)
        \#(blacklistRules)
          return "PROXY \#(proxyHost):\#(proxyPort)";
        }
        """
    }
}