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

  /// The storage for tasks created by the Model which are otherwise cancelled upon release.
  private var pendingTasks = Set<AnyCancellable>()

  /// Asks this model to asynchronously fetch new dessert results, publishing them to `desserts` when complete.
  public func reloadDesserts() {

    let getDesserts = GetDesserts()

    services.networkService.fetch(request: getDesserts.urlRequest, completion: networkServiceResultCompletionAdapter { result in
      switch result {
      case .success(let data):
        do {
          let decoded = try getDesserts.decode(data: data, using: JSONDecoder())

          DispatchQueue.main.async {
            self.desserts = decoded
          }
        } catch {
          assertionFailure("🛑 Failed to decode desserts response: \(error)")
        }
      case .failure(let error):
        assertionFailure("🛑 Failed to get desserts and no error handling has been implemented.")
      }
    }).store(in: &pendingTasks)
  }

  /// Requests the full details for the provided dessert and returns the result.
  ///
  /// - Returns: A `DessertDetail` object. Throws `ModelError.permanentResponseFailure`
  /// when no details are available for the provided dessert.
  public func getDetails(for dessert: DessertResult) async throws -> DessertDetail {
    let getDetails = GetDessertDetail(dessertId: dessert.id)

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DessertDetail, Error>) in
      services.networkService.fetch(request: getDetails.urlRequest, completion: networkServiceResultCompletionAdapter { result in
        switch result {
        case .success(let data):
          do {
            let decoded = try getDetails.decode(data: data, using: JSONDecoder())

            DispatchQueue.main.async {
              continuation.resume(returning: decoded)
            }
          } catch is DecodingError {
            DispatchQueue.main.async {
              continuation.resume(throwing: ModelError.permanentResponseFailure)
            }
          } catch {
            DispatchQueue.main.async {
              continuation.resume(throwing: error)
            }
          }
        case .failure(let error):
          DispatchQueue.main.async {
            continuation.resume(throwing: error)
          }
        }
      }).store(in: &pendingTasks)
    }
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
