import SwiftUI
import Model

/// A detail view which fetches and displays a provided dessert's full details.
struct DessertDetailView: View {
  /// The dessert for which full details should be fetched and displayed in this view.
  let dessert: DessertResult
  /// The fetched details object for `dessert`. Nil until the corresponding task is complete.
  @State private var details: DessertDetail?
  @EnvironmentObject var model: Model

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        AsyncImage(url: dessert.thumbnail) { image in
          image.resizable()
            .scaledToFill()
        } placeholder: {
          Rectangle().foregroundColor(.gray)
        }
        .frame(maxHeight: 250)
        .clipped()

        VStack(alignment: .leading) {
          Text(dessert.name)
            .font(.largeTitle.weight(.medium))
            .padding(.bottom, 20)

          Group {
            if let details = details {
              VStack(alignment: .leading, spacing: 6) {
                Text("Ingredients")
                  .font(.headline)
                  .padding(.bottom, 6)

                ForEach(details.ingredients) { item in
                  HStack {
                    Text(item.name.capitalized)
                    Spacer()
                    Text(item.amount)
                  }
                }
              }
              .padding(.bottom, 20)

              VStack(alignment: .leading, spacing: 12) {
                Text("Steps")
                  .font(.headline)

                ForEach(details.steps, id: \.self) { step in
                  Text(step)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
              }
            } else {
              ProgressView()
            }
          }
        }
        .padding()
      }
    }
    .task {
      do {
        details = try await model.getDetails(for: dessert)
      } catch {
        assertionFailure("🛑 Failed to get dessert details and no error handling has been implemented.")
      }
    }
  }
}

import MockServiceImplementations
#Preview {
  let mock = Services.mock()

  return NavigationView {
    DessertDetailView(dessert: mock.fixture())
      .environmentObject(Model(services: mock))
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
  }
}
