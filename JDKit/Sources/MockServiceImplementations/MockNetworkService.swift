import Foundation
import Combine
import Model

public extension Services {
  /// Creates an instance of `Services` with its required components configured for faking data results that
  /// are appropriate for tests and mock UI.
  static func mock() -> Services {
    Services(networkService: MockNetworkService())
  }
}

/// An object implementing `NetworkService` for the purpose of providing mock data to the Model.
final class MockNetworkService: NetworkService {
  func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> AnyCancellable {
    /// The provided completion function wrapped in a dispatch to maintain the async expectations of this API.
    let completion: (Data?, URLResponse?, Error?) -> Void = { (d, r, e) in
      DispatchQueue.main.async(execute: { completion(d, r, e) })
    }

    guard let method = request.httpMethod, let url = request.url else {
      completion(nil, nil, URLError(.badURL))
      return AnyCancellable {}
    }

    switch (method, url.host, url.path, url.query) {
    // - GET all desserts
    case ("GET", "www.themealdb.com", "/api/json/v1/1/filter.php", "c=Dessert"):
      completion(.fixture(named: "filter_desserts.json"), .successResponse(url), nil)
    default:
      completion(nil, .notFoundResponse(url), URLError(.unsupportedURL))
    }

    return AnyCancellable {}
  }
}

private extension Data {
  static func fixture(named name: String) -> Data {
    guard let urlToFixture = Bundle.module.url(forResource: name, withExtension: nil),
          let fixtureData = try? Data(contentsOf: urlToFixture)
    else {
      assertionFailure("🛑 No fixture named \(name) was found.")
      return Data()
    }

    return fixtureData
  }
}

private extension URLResponse {
  static func successResponse(_ url: URL) -> URLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
  }

  static func notFoundResponse(_ url: URL) -> URLResponse {
    HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
  }
}