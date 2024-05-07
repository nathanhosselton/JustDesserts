import Foundation

/// Represents a dessert to be displayed to the user and for which additional details may be fetched.
public struct DessertResult: Decodable, Identifiable {
  public let id: String
  /// The name of this dessert.
  public let name: String
  /// A url to a thumbnail image for this dessert.
  public let thumbnail: URL

  enum CodingKeys: String, CodingKey {
    case id = "idMeal", name = "strMeal", thumbnail = "strMealThumb"
  }
}
