import Foundation

/// 订阅服务
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    private let storage = StorageService.shared
    private let session = URLSession.shared

    /// 获取订阅内容并解析
    func fetchSubscription(url: URL, completion: @escaping (Result<[ServerConfig], Error>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "SubscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"]))) }
                return
            }

            // 尝试 Base64 解码
            let decoded: String
            if let base64Decoded = Data(base64Encoded: data, options: .ignoreUnknownCharacters),
               let str = String(data: base64Decoded, encoding: .utf8) {
                decoded = str
            } else if let str = String(data: data, encoding: .utf8) {
                decoded = str
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "SubscriptionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot decode content"]))) }
                return
            }

            let configs = ConfigParser.parseMultiple(decoded)
            DispatchQueue.main.async { completion(.success(configs)) }
        }
        task.resume()
    }

    /// 更新订阅，增量合并
    func updateSubscription(_ subscription: Subscription) {
        guard let url = URL(string: subscription.url) else { return }

        fetchSubscription(url: url) { [weak self] result in
            switch result {
            case .success(let newConfigs):
                self?.mergeConfigs(newConfigs)
                if let idx = self?.storage.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                    self?.storage.subscriptions[idx].lastUpdated = Date()
                    self?.storage.subscriptions[idx].serverCount = newConfigs.count
                    self?.storage.saveSubscriptions()
                }
            case .failure(let error):
                print("Subscription update failed: \(error)")
            }
        }
    }

    /// 增量合并：新增的添加，已有的更新，手动删除的保留
    private func mergeConfigs(_ newConfigs: [ServerConfig]) {
        for newConfig in newConfigs {
            // 通过地址+端口+协议匹配已有配置
            if let idx = storage.servers.firstIndex(where: {
                $0.address == newConfig.address &&
                $0.port == newConfig.port &&
                $0.protocolType == newConfig.protocolType
            }) {
                var updated = newConfig
                updated.id = storage.servers[idx].id
                updated.isSelected = storage.servers[idx].isSelected
                // 保留手动修改的名称
                if !storage.servers[idx].name.isEmpty {
                    updated.name = storage.servers[idx].name
                }
                storage.servers[idx] = updated
            } else {
                storage.servers.append(newConfig)
            }
        }
        storage.saveServers()
    }
}