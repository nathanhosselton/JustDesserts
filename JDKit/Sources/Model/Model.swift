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
    /// Represents the raw JSON object response from the API.
    struct DessertsResponse: Decodable {
      let meals: [DessertResult]

      enum CodingKeys: CodingKey {
        case meals
      }

      init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var container = try values.nestedUnkeyedContainer(forKey: .meals)

        // Filter out desserts which fail to decode
        // - Note: The API does not currently return any results which are missing required fields,
        // but as with any external API, it may become unreliable and our app should not completely fail.
        var meals = [DessertResult]()
        while !container.isAtEnd {
          if let decoded = try? container.decode(DessertResult.self) {
            meals.append(decoded)
          } else {
            // Consume the malformed entry so that iteration may proceed
            struct IgnoredMalformedEntry: Decodable {}
            _ = try container.decode(IgnoredMalformedEntry.self)
          }
        }

        self.meals = meals
      }
    }

    let allDesserts = URLRequest(url: URL(string: "https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert")!)

    services.networkService.fetch(request: allDesserts, completion: networkServiceResultCompletionAdapter { result in
      switch result {
      case .success(let data):
        do {
          let decoded = try JSONDecoder().decode(DessertsResponse.self, from: data)
          // - Note: The API currently returns results sorted (mostly) alphabetically, but as with any
          // external API, it may become (more) unreliable and our app should maintain user expectations.
          let desserts = decoded.meals.sorted(by: <)

          DispatchQueue.main.async {
            self.desserts = desserts
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
    struct DetailResponse: Decodable {
      let meals: [DessertDetail]
    }

    let details = URLRequest(url: URL(string: "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(dessert.id)")!)

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DessertDetail, Error>) in
      services.networkService.fetch(request: details, completion: networkServiceResultCompletionAdapter { result in
        switch result {
        case .success(let data):
          do {
            let decoded = try JSONDecoder().decode(DetailResponse.self, from: data)

            if let detailResult = decoded.meals.first {
              DispatchQueue.main.async {
                continuation.resume(returning: detailResult)
              }
            } else {
              throw ModelError.permanentResponseFailure
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
