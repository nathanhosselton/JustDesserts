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
}
