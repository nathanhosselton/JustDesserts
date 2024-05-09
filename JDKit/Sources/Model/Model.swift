import Foundation
import Combine

/// The container object for model data utilized throughout the app.
public final class Model: ObservableObject {
  /// The list of desserts to be displayed to the user.
  @Published public private(set) var desserts: [DessertResult] = []

  /// The services utilized by this model for fetching and operating on data.
  let services: Services

  /// Initializes the `Model` with its required services.
  public init(services: Services) {
    self.services = services
  }

  /// Asks this model to fetch new dessert results, publishing them to `desserts` when complete.
  @discardableResult 
  @MainActor public func refreshDesserts() async throws -> [DessertResult] {
    self.desserts = try await request(GetDesserts())

    return desserts
  }

  /// Requests the full details for the provided dessert and returns the result.
  ///
  /// - Returns: A `DessertDetail` object. Throws `ModelError.permanentResponseFailure`
  /// when no details are available for the provided dessert.
  public func getDetails(for dessert: DessertResult) async throws -> DessertDetail {
    return try await request(GetDessertDetail(dessertId: dessert.id))
  }

  //- MARK: Internal
  /// The storage for tasks created by the Model which are otherwise cancelled upon release.
  private var pendingTasks = Set<AnyCancellable>()

  /// Executes a `NetworkService` fetch for the provided operation, automatically decoding and returning the public result type.
  ///
  /// This method adapts the most common use case of the `NetworkService` for requesting data and then decoding it. It provides
  /// standard error handling (including communicating decoding failures as `ModelError.permanentResponseFailure` as a
  /// convenience.
  ///
  /// If you require different behavior, execute your request through the `services` object directly. Standard result mapping may still
  /// be leveraged via the free func `networkServiceResultCompletionAdapter(completion:)`.
  private func request<T>(_ operation: T) async throws -> T.ResponseType where T: Operation {
    return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<T.ResponseType, any Error>) in
      request(operation, completion: { continuation.resume(with: $0) })
    }
  }

  /// Executes a `NetworkService` fetch for the provided operation, automatically decoding and returning the public result type.
  /// Always calls the completion on the main thread.
  ///
  /// This method adapts the most common use case of the `NetworkService` for requesting data and then decoding it. It provides
  /// standard error handling (including communicating decoding failures as `ModelError.permanentResponseFailure` as well
  /// as main thread completion as a convenience.
  ///
  /// If you require different behavior, execute your request through the `services` object directly. Standard result mapping may still
  /// be leveraged via the free func `networkServiceResultCompletionAdapter(completion:)`.
  private func request<T>(_ operation: T, completion: @escaping (Result<T.ResponseType, Error>) -> Void) where T: Operation {
    services.networkService.fetch(request: operation.urlRequest, completion: networkServiceResultCompletionAdapter { result in
      switch result {
      case .success(let data):
        do {
          let decoded = try operation.decode(data: data, using: JSONDecoder())

          DispatchQueue.main.async {
            completion(.success(decoded))
          }
        } catch is DecodingError {
          DispatchQueue.main.async {
            completion(.failure(ModelError.permanentResponseFailure))
          }
        } catch {
          // Operation/decode(data:using:) threw a non-decoding error
          DispatchQueue.main.async {
            completion(.failure(error))
          }
        }
      case .failure(let error):
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }).store(in: &pendingTasks)
  }
}

/// Adapts standard `NetworkService` completion handlers by consolidating boilerplate logic into a `Result`.
private func networkServiceResultCompletionAdapter(completion: @escaping (Result<Data, NetworkServiceError>) -> Void) -> (Data?, URLResponse?, NetworkServiceError?) -> Void {
  return { (d, r, e) in
    switch (d, r, e) {
    case (.some(let data), .some(_ as HTTPURLResponse), .none):
      // - Valid success response
      completion(.success(data))
    case (_, _, .some(let error)):
      // - Known error response
      completion(.failure(error))
    case (_, .some(let response), .none):
      // - Unrecognized unexpected response (Typically a developer error)
      assertionFailure("🛑 NetworkService task completed with an unexpected response: \(response.debugDescription)")
      completion(.failure(.unknownUnhandled(NSError())))
    case (_, .none, .none):
      // - Impossible according to API expectations
      assertionFailure("🛑 NetworkService failed to provide either a response or an error.")
      completion(.failure(.unknownUnhandled(NSError())))
    }
  }
}
