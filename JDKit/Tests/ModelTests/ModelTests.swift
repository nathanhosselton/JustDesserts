import XCTest
@testable import Model
import MockServiceImplementations

final class ModelTests: XCTestCase {
  func test_reloadDesserts() throws {
    // Given a newly initialized Model and an expectation that awaits the second desserts change
    let model = Model(services: .mock())
    let reloadComplete = expectation(description: "model.desserts should emit 2 values")
    let cancellable = model.$desserts
      .dropFirst() // The initial empty value received immediately upon sink
      .sink { _ in reloadComplete.fulfill() }

    // When reloadDesserts() completes
    model.reloadDesserts()
    wait(for: [reloadComplete], timeout: 5)
    cancellable.cancel()

    // Then model.desserts should contain values
    XCTAssert(!model.desserts.isEmpty)
  }
}
