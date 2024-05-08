import Foundation
import Combine
import Model

extension URLSession: NetworkService {
  public func fetch(request: URLRequest, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> AnyCancellable {
    let task = dataTask(with: request, completionHandler: completion)
    task.resume()
    return AnyCancellable(task)
  }
}

extension URLSessionTask: Cancellable
{}
