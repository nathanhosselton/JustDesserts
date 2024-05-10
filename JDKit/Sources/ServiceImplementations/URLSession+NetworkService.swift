import Foundation
import Combine
import Model

extension URLSession: NetworkService {
  public func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, NetworkServiceError?) -> Void) -> AnyCancellable {
    let task = dataTask(with: request, completionHandler: networkServiceErrorCompletionAdapter(completion))
    task.resume()
    return AnyCancellable(task)
  }
}

extension URLSessionTask: Cancellable
{}

//MARK: - Error Handling
extension NetworkServiceError {
  /// An initializer which handles common HTTP response failures by mapping them to the corresponding
  /// `NetworkServiceError` value.
  init(_ resp: HTTPURLResponse) {
    switch resp.statusCode {
    case 408, 502, 504:
      self = .connectivity
    case 500...599:
      self = .serviceUnavailable
    default:
      self = .other(statusCode: resp.statusCode)
    }
  }

  /// An initializer which handles the common HTTP request errors by mapping them to the corresponding
  /// `NetworkServiceError` value.
  init?(_ error: NSError) {
    switch error.code {
    case -1001 where error.domain == "NSURLErrorDomain": // Timeout was reached (URLRequest default timeout is 60s)
      self = .timeout
    case -1005 where error.domain == "NSURLErrorDomain", // Connection lost during request
         -1009 where error.domain == "NSURLErrorDomain": // Device has no service (immediate)
      self = .connectivity
    default:
      return nil
    }
  }
}

/// A completion adapter which exclusively checks whether the HTTP response or error convert to a known `NetworkServiceError`.
/// All other result states are ignored and passed onto the caller.
func networkServiceErrorCompletionAdapter(_ completion: @escaping (Data?, URLResponse?, NetworkServiceError?) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
  return { (d, r, e) in
    switch (r, e) {
    case (.some(let response as HTTPURLResponse), _) where (200..<299).contains(response.statusCode):
      // There is a success response ∴ error should be nil and is ignored
      completion(d, r, nil)
    case (.some(let response as HTTPURLResponse), _):
      // Request completed but with an unexpected response that maps to a known error
      completion(d, r, NetworkServiceError(response))
    case (.some, .none):
      // Request completed but with an unrecognized response that must be handled by callers
      completion(d, r, nil)
    case (_, .some(let error as NSError)) where NetworkServiceError(error) != nil:
      // Request failed with a known error
      completion(d, r, NetworkServiceError(error)!)
    case (_, .some(let error)):
      // Request failed with an unrecognized error
      completion(d, r, .unknownUnhandled(error))
    case (.none, .none):
      // Impossible according to URLSession guarantees
      completion(d, r, nil)
    }
  }
}
