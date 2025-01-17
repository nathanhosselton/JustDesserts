import SwiftUI
import Model

/// A detail view which fetches and displays a provided dessert's full details.
struct DessertDetailView: View {
  /// The dessert for which full details should be fetched and displayed in this view.
  let dessert: DessertResult
  /// The fetched details object for `dessert`. Nil until the corresponding task is complete.
  @State private var details: DessertDetail?
  /// The error received during the most recent call to `retrieveDetails()`, if any.
  @State private var lastError: Error?
  @EnvironmentObject var model: Model

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // - Header image
        AsyncImage(url: dessert.thumbnail) { image in
          image.resizable()
            .scaledToFill()
        } placeholder: {
          Rectangle().foregroundColor(.gray)
        }
        .frame(maxHeight: 250)
        .clipped()

        VStack(alignment: .leading) {
          // - Dessert name
          Text(dessert.name)
            .font(.largeTitle.weight(.medium))
            .padding(.bottom, 20)

          // - Fetched details
          Group {
            if let details = details {
              // - Ingredients and Steps
              IngredientsSection(displaying: details.ingredients)
                .padding(.bottom, 20)

              StepsSection(displaying: details.steps)
            } else if let error = lastError {
              // - Embedded error display
              ErrorContent(for: error)
            } else {
              // Details are still in-flight.
              ProgressView()
            }
          }
        }
        .padding()
      }
    }
    .onAppear(perform: retrieveDetails)
  }

  /// Builds the section displaying the dessert's recipe ingredients and corresponding measurements from
  /// the fetched `DessertDetail`.
  private func IngredientsSection(displaying ingredients: [DessertDetail.Ingredient]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Ingredients")
        .font(.headline)
        .padding(.bottom, 6)

      ForEach(ingredients) { item in
        HStack {
          Text(item.name.capitalized)
          Spacer()
          Text(item.amount)
        }
      }
    }
  }

  /// Builds the section displaying the dessert's recipe streps from the fetched `DessertDetail`.
  private func StepsSection(displaying steps: [String]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Steps")
        .font(.headline)

      ForEach(steps, id: \.self) { step in
        Text(step)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  /// Builds conditional content for display when an error occurs while fetching the dessert details.
  @ViewBuilder
  private func ErrorContent(for error: Error) -> some View {
    switch error {
    case ModelError.permanentResponseFailure:
      // We received the details but they were not well formed.
      //
      // - Note: This state is essentially our handling of the case where a DessertResult
      // from the /filter API call is well-formed, but the corresponding DessertDetail
      // from the /lookup API call is malformed. Based on the current decoding implementation
      // within DessertDetail, this can only happen if every ingredient or measurement
      // is null, or if the instructions are null. Neither of these is currently the case
      // in the API for any entries returned under the Dessert category.
      //
      // The alternative to this was to perform all /lookup requests immediately upon app
      // launch and cache them in advance. This would have the advantage of both knowing
      // in advance if a DessertDetail will fail to decode, allowing us to throw away the
      // corresponding DessertResult before showing it to the user, as well as skipping
      // a loading state when the user taps on a DessertResult entry in DessertsListView.
      //
      // In reality, that lookup should rarely take longer than the transition time to
      // the DessertDetailView. And performing that many API requests simultaneously or
      // even in sequence has the potential to overload the service or result in a rate
      // limit. Using a view transition to mask the transit time of an additional data
      // request is also a more broadly used strategy than pre-fetching, and so I chose
      // to go this route rather than the alternative.
      Text("Details for this dessert are\nnot currently available.")
    default:
      // Notify the user and allow them to retry.
      VStack(alignment: .center) {
        Text("Failed while retrieving this dessert.")
        Button("Retry", action: retrieveDetails)
          .buttonStyle(.bordered)
      }
    }
  }

  /// Asks the `model` to get the details for our `dessert` then updates our `details` with the results.
  ///
  /// If an error occurs, updates `lastError`. Calling this method again clears `lastError`.
  private func retrieveDetails() {
    lastError = nil

    Task {
      do {
        details = try await model.getDetails(for: dessert)
      } catch {
        self.lastError = error
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
