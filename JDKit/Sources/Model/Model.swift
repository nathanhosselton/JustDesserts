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

        DispatchQueue.main.async {
          self.desserts = decoded.meals
        }
      } catch {
        assertionFailure("🛑 Failed to decode desserts response: \(error)")
      }
    }.store(in: &pendingTasks)
  }
}
