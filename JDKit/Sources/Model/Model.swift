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
    struct DessertsResponse: Decodable {
      let meals: [DessertResult]
    }

    let allDesserts = URLRequest(url: URL(string: "https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert")!)

    services.networkService.fetch(request: allDesserts) { (data, response, error) in
      guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
        fatalError("🛑 Failed to get desserts and no error handling has been implemented.")
      }

      do {
        let decoded = try JSONDecoder().decode(DessertsResponse.self, from: data)
        // - Note: The API currently returns results already sorted alphabetically, so this operation
        // is wasted. However, since alphabetical sorting is a stated requirement of the app, and since
        // this API is not owned nor controlled internally and therefore could change behavior, manual
        // sorting to guarantee expectations is warranted.
        let desserts = decoded.meals.sorted(by: <)

        DispatchQueue.main.async {
          self.desserts = desserts
        }
      } catch {
        assertionFailure("🛑 Failed to decode desserts response: \(error)")
      }
    }.store(in: &pendingTasks)
  }

  /// Requests the full details for the provided dessert and returns the result.
  public func getDetails(for dessert: DessertResult) async throws -> DessertDetail {
    struct DetailResponse: Decodable {
      let meals: [DessertDetail]
    }

    let details = URLRequest(url: URL(string: "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(dessert.id)")!)

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DessertDetail, Error>) in
      services.networkService.fetch(request: details) { (data, response, error) in
        guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
          assertionFailure("🛑 Failed to get dessert details and no error handling has been implemented.")
          return DispatchQueue.main.async { continuation.resume(throwing: NSError()) }
        }

        do {
          let decoded = try JSONDecoder().decode(DetailResponse.self, from: data)

          DispatchQueue.main.async {
            if let detailResult = decoded.meals.first {
              continuation.resume(returning: detailResult)
            } else {
              assertionFailure("🛑 Dessert detail result was empty no error handling has been implemented.")
              continuation.resume(throwing: NSError())
            }
          }
        } catch {
          assertionFailure("🛑 Failed to decode desserts response: \(error)")
          return DispatchQueue.main.async { continuation.resume(throwing: error) }
        }
      }.store(in: &pendingTasks)
    }
  }
}
