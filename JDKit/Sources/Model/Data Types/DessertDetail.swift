import Foundation

/// Represents the full details of a particular dessert.
public struct DessertDetail: Decodable, Identifiable {
  public let id: String
  /// The name of this dessert.
  public let name: String
  /// A url to a thumbnail image for this dessert.
  public let thumbnail: URL
  /// The list of ingredients used in the dessert and their amounts.
  public let ingredients: [Ingredient]
  /// The list of steps taken to make the dessert.
  public let steps: [String]

  /// Represents an individual ingredient in the dessert and its corresponding amount.
  public struct Ingredient: Decodable, Identifiable {
    /// The name of the ingredient, e.g. "Milk".
    public let name: String
    /// The amount of the ingredient, e.g. "200ml".
    public let amount: String

    public var id: String {
      "\(name)\(amount)"
    }
  }

  //MARK: Custom decoding
  enum CodingKeys: String, CodingKey {
    // Renamed values
    case id = "idMeal", name = "strMeal", thumbnail = "strMealThumb"
    // Remapped values
    case instructions = "strInstructions"
    case ingredient1 = "strIngredient1", ingredient2 = "strIngredient2",
         ingredient3 = "strIngredient3", ingredient4 = "strIngredient4",
         ingredient5 = "strIngredient5", ingredient6 = "strIngredient6",
         ingredient7 = "strIngredient7", ingredient8 = "strIngredient8",
         ingredient9 = "strIngredient9", ingredient10 = "strIngredient10",
         ingredient11 = "strIngredient11", ingredient12 = "strIngredient12",
         ingredient13 = "strIngredient13", ingredient14 = "strIngredient14",
         ingredient15 = "strIngredient15", ingredient16 = "strIngredient16",
         ingredient17 = "strIngredient17", ingredient18 = "strIngredient18",
         ingredient19 = "strIngredient19", ingredient20 = "strIngredient20"
    case measurement1 = "strMeasure1", measurement2 = "strMeasure2",
         measurement3 = "strMeasure3", measurement4 = "strMeasure4",
         measurement5 = "strMeasure5", measurement6 = "strMeasure6",
         measurement7 = "strMeasure7", measurement8 = "strMeasure8",
         measurement9 = "strMeasure9", measurement10 = "strMeasure10",
         measurement11 = "strMeasure11", measurement12 = "strMeasure12",
         measurement13 = "strMeasure13", measurement14 = "strMeasure14",
         measurement15 = "strMeasure15", measurement16 = "strMeasure16",
         measurement17 = "strMeasure17", measurement18 = "strMeasure18",
         measurement19 = "strMeasure19", measurement20 = "strMeasure20"

    static var allIngredients: [CodingKeys] = [
      .ingredient1, .ingredient2, .ingredient3, .ingredient4, .ingredient5,
      .ingredient6, .ingredient7, .ingredient8, .ingredient9, .ingredient10,
      .ingredient11, .ingredient12, .ingredient13, .ingredient14, .ingredient15,
      .ingredient16, .ingredient17, .ingredient18, .ingredient19, .ingredient20
    ]

    static var allMeasurements: [CodingKeys] = [
      .measurement1, .measurement2, .measurement3, .measurement4, .measurement5,
      .measurement6, .measurement7, .measurement8, .measurement9, .measurement10,
      .measurement11, .measurement12, .measurement13, .measurement14, .measurement15,
      .measurement16, .measurement17, .measurement18, .measurement19, .measurement20
    ]
  }

  public init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    thumbnail = try values.decode(URL.self, forKey: .thumbnail)

    // Map the paragraphical instructions string to a list of strings
    let rawSteps = try values.decode(String.self, forKey: .instructions)
    let regex = try! NSRegularExpression(pattern: "[\\r|\\n]+") // Match any sequence of line breaks
    steps = regex.stringByReplacingMatches(in: rawSteps, range: NSRange(0...rawSteps.count), withTemplate: "\n")
      .split(separator: "\n")
      .map(String.init)

    // Map the related series' of ingredients and measurements to a list of Ingredients
    var ingredients: [Ingredient] = []
    for (ingredientKey, measurementKey) in zip(CodingKeys.allIngredients, CodingKeys.allMeasurements) {
      if let ingredient = try? values.decode(String.self, forKey: ingredientKey),
         let measurement = try? values.decode(String.self, forKey: measurementKey),
         !ingredient.trimmingCharacters(in: .whitespaces).isEmpty,
         !measurement.trimmingCharacters(in: .whitespaces).isEmpty {
        ingredients.append(Ingredient(name: ingredient, amount: measurement))
      }
    }
    self.ingredients = ingredients
  }
}
