import Foundation
import Model

public extension Services {
  /* - Mock Fixtures
   Ideally, any required mock data would flow naturally from the methods available on the Model (in
   turn being provided by methods of each service protocol). Unfortunately, SwiftUI PreviewProvider
   does not yet support invalidation and therefore cannot be conditionally rendered upon receipt of
   required asynchronous data. Although this can be worked around with custom view wrappers, the
   overhead becomes a repeated source of friction which defeats the purpose of Previews.

   The best solution I've found is to simply make a direct API for piecemeal construction of mocks
   where needed (for example, when a view requires an object at init, but the source of the object
   is from an async operation that was skipped in the preview's isolation). Strictly, this API does
   not belong here. But practicality wins out in this case, I feel, especially since this API
   should not be reachable in production code (see comments in Package.swift).
   */
  /// Returns a static fixture object of the corresponding type for use in preview UI.
  func fixture<T>() -> T where T: Decodable {
    switch T.self {
    default:
      fatalError("🛑 Missing support for fixture of type \(T.self)")
    }
  }
}

extension Data {
  /// Returns the data contents of the file of the given name from within this module's bundle.
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
