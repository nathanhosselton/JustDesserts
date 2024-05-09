import Foundation

/// Represents a dessert to be displayed to the user and for which additional details may be fetched.
public struct DessertResult: Decodable, Identifiable, Comparable {
  public let id: String
  /// The name of this dessert.
  public let name: String
  /// A url to a thumbnail image for this dessert.
  public let thumbnail: URL

  public static func < (lhs: DessertResult, rhs: DessertResult) -> Bool {
    lhs.name < rhs.name
  }

  enum CodingKeys: String, CodingKey {
    case id = "idMeal", name = "strMeal", thumbnail = "strMealThumb"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)

    // Throw when `name` decodes into an empty string.
    // - Note: This is possibly an overreach in safety as it's extremely unlikely that the
    // API would ever provide results with no names but for the sake of thoroughness and
    // example I've included it.
    let name = try container.decode(String.self, forKey: .name)
    if name.trimmingCharacters(in: .whitespaces).isEmpty {
      throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.name], debugDescription: "Value for key `name` was unexpectedly empty."))
    }
    self.name = name

    self.thumbnail = try container.decode(URL.self, forKey: .thumbnail)
  }
}

//- MARK: Operation
/// An operation which fetches all desserts from the remote API.
struct GetDesserts: Operation {
  var urlRequest: URLRequest {
    URLRequest(url: URL(string: "https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert")!)
  }

  /// Represents the raw JSON object response from the API.
  private struct DessertsResponse: Decodable {
    let meals: [DessertResult]

    enum CodingKeys: CodingKey {
      case meals
    }

    init(from decoder: any Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      var container = try values.nestedUnkeyedContainer(forKey: .meals)

      // Filter out desserts which fail to decode
      // - Note: The API does not currently return any results which are missing required fields,
      // but as with any external API, it may become unreliable and our app should not completely fail.
      var meals = [DessertResult]()
      while !container.isAtEnd {
        if let decoded = try? container.decode(DessertResult.self) {
          meals.append(decoded)
        } else {
          // Consume the malformed entry so that iteration may proceed
          struct IgnoredMalformedEntry: Decodable {}
          _ = try container.decode(IgnoredMalformedEntry.self)
        }
      }

      self.meals = meals
    }
  }

  func decode(data: Data, using decoder: JSONDecoder) throws -> [DessertResult] {
    let decoded = try decoder.decode(DessertsResponse.self, from: data)

    guard !decoded.meals.isEmpty else {
      // Unlikely, but given that we silently ignore DessertResults that fail to decode,
      // it's plausible that an API change could result in us filtering the entire list,
      // which would be an error.
      throw ModelError.permanentResponseFailure
    }

    // - Note: The API currently returns results sorted (mostly) alphabetically, but as with any
    // external API, it may become (more) unreliable and our app should maintain user expectations.
    return decoded.meals.sorted(by: <)
  }
}
