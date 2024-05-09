import XCTest
@testable import Model
import MockServiceImplementations

final class ModelTests: XCTestCase {
  func test_refreshDesserts() async throws {
    // Given a newly initialized Model
    let model = Model(services: .mock())

    // When refreshDesserts() completes
    try await model.refreshDesserts()

    // Then model.desserts should contain values
    XCTAssert(!model.desserts.isEmpty)
  }
}
