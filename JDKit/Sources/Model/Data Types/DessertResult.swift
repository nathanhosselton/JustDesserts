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
