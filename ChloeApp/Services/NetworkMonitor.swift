import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true

    /// Fires when connectivity transitions from offline → online
    let didReconnect = PassthroughSubject<Void, Never>()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.chloepocket.networkmonitor")
    private var wasConnected = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                let nowConnected = path.status == .satisfied
                let justReconnected = !self.wasConnected && nowConnected
                self.wasConnected = nowConnected
                self.isConnected = nowConnected
                if justReconnected {
                    self.didReconnect.send()
                }
            }
        }
        monitor.start(queue: queue)
    }
}
