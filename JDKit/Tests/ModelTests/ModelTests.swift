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

  func test_isFetchingDesserts() async throws {
    // Given a newly initialized Model and a task the collects the first three values emitted by isFetchingDesserts
    let model = Model(services: .mock())
    var isFetchingDessertsValues: [Bool] = []
    let cancellable = model.$isFetchingDesserts
      .prefix(3)
      .sink {
        isFetchingDessertsValues.append($0)
      }

    // When reloadDesserts() is executed
    try await model.refreshDesserts()
    cancellable.cancel()

    // Then we see expected values emitted throughout the reload
    XCTAssertEqual(
      isFetchingDessertsValues,
      [false, true, false]
    )
  }
}
