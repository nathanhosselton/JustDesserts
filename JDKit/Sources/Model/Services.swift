import Foundation
import Combine

/// Container for all services utilized by the Model.
public struct Services {
  /// The service object responsible for handling network operations.
  public let networkService: NetworkService
  /// Creates a Services object with its required components.
  public init(networkService: NetworkService) {
    self.networkService = networkService
  }
}

/// An interface for a type which enables network operations on the Model's behalf.
public protocol NetworkService {
  /// Executes an asynchronous HTTP request with a function to be called upon completion.
  ///
  /// - Returns: An object which may be used to cancel an in-progress request.
  func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> AnyCancellable
}
