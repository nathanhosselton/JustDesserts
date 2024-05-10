import Foundation

/// An interface for an object representing a specific operation executed by one of our `Services`.
protocol Operation {
  /// The type into which this operation's response data decodes.
  associatedtype ResponseType: Decodable

  /// The fully formed URLRequest that may be used to execute this operation via the `NetworkService`.
  var urlRequest: URLRequest { get }
  
  /// Encapsulates the decoding logic for converting this operation's response data into a public Model type.
  func decode(data: Data, using decoder: JSONDecoder) throws -> ResponseType
}
