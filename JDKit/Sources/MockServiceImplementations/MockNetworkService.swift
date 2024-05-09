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
  func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, NetworkServiceError?) -> Void) -> AnyCancellable {
    /// The provided completion function wrapped in a dispatch to maintain the async expectations of this API.
    let completion: (Data?, URLResponse?, NetworkServiceError?) -> Void = { (d, r, e) in
      DispatchQueue.main.async(execute: { completion(d, r, e) })
    }

    guard let method = request.httpMethod, let url = request.url else {
      completion(nil, nil, .unknownUnhandled(URLError(.badURL)))
      return AnyCancellable {}
    }

    switch (method, url.host, url.path, url.query) {
    // - GET all desserts
    case ("GET", "www.themealdb.com", "/api/json/v1/1/filter.php", "c=Dessert"):
      completion(.fixture(named: "filter_desserts.json"), .successResponse(url), nil)
    // - GET item details
    case ("GET", "www.themealdb.com", "/api/json/v1/1/lookup.php", _):
      // item identifier is ignored and a static item is provided
      completion(.fixture(named: "lookup.json"), .successResponse(url), nil)
    default:
      completion(nil, .notFoundResponse(url), .unknownUnhandled(URLError(.unsupportedURL)))
    }

    return AnyCancellable {}
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
