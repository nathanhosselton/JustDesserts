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
  /// Performs lightweight error detection, including for non-success HTTP status codes, mapping known errors to a
  /// `NetworkServiceError` within the completion while leaving the data and response objects unmodified.
  /// Callers can reasonably expect that the completion will always receive a response object or an error (or both).
  ///
  /// - Returns: An object which may be used to cancel an in-progress request.
  func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, NetworkServiceError?) -> Void) -> AnyCancellable
}
