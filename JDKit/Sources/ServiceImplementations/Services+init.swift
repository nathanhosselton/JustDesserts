import Foundation
import Model

public extension Services {
  /// Creates a Services object with its required components fully constructed for live data.
  init() {
    self.init(networkService: URLSession.shared)
  }
}
