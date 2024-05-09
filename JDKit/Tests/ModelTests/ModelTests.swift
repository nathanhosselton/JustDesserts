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

    // When refreshDesserts() is executed
    try await model.refreshDesserts()
    cancellable.cancel()

    // Then we see expected values emitted throughout the reload
    XCTAssertEqual(
      isFetchingDessertsValues,
      [false, true, false]
    )
  }

  func test_Operation_GetDessertDetail_decode() throws {
    // Given a newly initialized GetDessertDetail object and a fixture of a valid response
    let operation = GetDessertDetail(dessertId: "")
    let fixture = #"""
    {
      "meals": [
        {
          "idMeal": "53049",
          "strMeal": "Apam balik",
          "strInstructions": "Mix milk, oil and egg together.\r\n\r\nSpread.",
          "strMealThumb": "https://www.themealdb.com/images/media/meals/adxcbq1619787919.jpg",
          "strIngredient1": "Milk",
          "strMeasure1": "200ml",
        }
      ]
    }
    """#
      .data(using: .utf8)!

    // When decoding the response data through the operation
    let decoded = try? operation.decode(data: fixture, using: JSONDecoder())

    // Then the decoded object is non-nil (decoding succeeds)
    XCTAssert(decoded != nil)
  }

  func test_Operation_GetDessertDetail_decodingEmptyMealsThrows_permanentResponseFailure() throws {
    // Given a newly initialized GetDessertDetail object and a fixture of a response containing no details
    let operation = GetDessertDetail(dessertId: "")
    let fixture = #"""
    {
      "meals": [
      ]
    }
    """#
      .data(using: .utf8)!
    var intentionalError: Error? = nil

    // When decoding the response data through the operation
    do {
      _ = try operation.decode(data: fixture, using: JSONDecoder())
    } catch {
      intentionalError = error
    }

    // Then the caught error is ModelError.permanentResponseFailure
    XCTAssert(intentionalError as? ModelError == .permanentResponseFailure)
  }
}
