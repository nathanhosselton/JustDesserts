import SwiftUI
import Model

/// The root view of the app displaying the list of desserts.
struct DessertsListView: View {
  /// The error received during the most recent call to `refresh()`, if any.
  @State private var lastError: DessertsListView.Error? = nil
  /// Whether or not `lastError` should be presented when non-nil.
  @State private var shouldPresentError = false
  @EnvironmentObject var model: Model

  var body: some View {
    NavigationView {
      if !model.desserts.isEmpty {
        // - Desserts list
        List(model.desserts) { item in
          NavigationLink(destination: DessertDetailView(dessert: item)) {
            DessertResultCell(item: item)
          }
        }
        .navigationTitle("Desserts")
        .refreshable {
          //TODO: If already refreshing, await current refresh
          await refresh()
        }
      } else if model.isFetchingDesserts {
        // Refreshing
        ProgressView()
      } else {
        // Refresh failed and retry was cancelled
        Button("Refresh") {
          Task { await refresh() }
        }
        .buttonStyle(.bordered)
      }
    }
    .task {
      await refresh()
    }
    .alert(isPresented: $shouldPresentError, error: lastError, actions: { _ in
      Button("OK") {}
      Button("Retry") {
        Task { await refresh() }
      }
    }, message: { error in
      Text(error.localizedDescription)
    })
  }

  /// Builds the cell for an individual `DessertResult`.
  private func DessertResultCell(item: DessertResult) -> some View {
    HStack {
      AsyncImage(url: item.thumbnail) { image in
        image.resizable()
          .aspectRatio(1, contentMode: .fit)
      } placeholder: {
        Rectangle().overlay(Color.gray)
      }
      .frame(width: 100, height: 100)

      Text(item.name)
    }
  }

  /// Asks the `model` to refresh the contents of its `desserts`.
  ///
  /// If an error occurs, updates `lastError`. Calling this method again clears `lastError`.
  private func refresh() async {
    lastError = nil

    do {
      try await model.refreshDesserts()
      // View will invalidate on model change
    } catch {
      self.lastError = DessertsListView.Error(title: "Couldn't fetch desserts", underlying: error)
      self.shouldPresentError = true
    }
  }

  /// An error type to represent failures in this view.
  private struct Error: LocalizedError {
    /// The title to be displayed for the error.
    let title: String
    /// The actual error that occurred.
    let underlying: Swift.Error

    var errorDescription: String? {
      title
    }

    var localizedDescription: String {
      underlying.localizedDescription
    }
  }
}

import MockServiceImplementations
#Preview {
  DessertsListView()
    .environmentObject(Model(services: .mock()))
}
